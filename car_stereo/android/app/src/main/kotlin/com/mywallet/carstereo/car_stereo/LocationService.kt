package com.mywallet.carstereo.car_stereo

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import kotlin.concurrent.thread

class LocationService : Service(), LocationListener {

    private lateinit var dbHelper: CarStereoDbHelper
    private var locationManager: LocationManager? = null
    private val handler = Handler(Looper.getMainLooper())

    // Trip State
    private var activeTripId: String? = null
    private var isTrackingActiveTrip = false
    private var startTimeMs: Long = 0L
    private var distanceTravelled = 0.0
    private var startOdometer = 0.0
    private val gpsPoints = ArrayList<Pair<Double, Double>>()
    private var lastLocation: Location? = null
    private var lastMovementTimeMs: Long = 0L
    private var startAddress = ""
    private var lastAddressLookupTimeMs: Long = 0L

    private val CHANNEL_ID = "CarStereoTrackingChannel"
    private val NOTIFICATION_ID = 54321

    // Check every 30 seconds for trip stop inactivity (30 minutes)
    private val inactivityRunnable = object : Runnable {
        override fun run() {
            checkTripInactivity()
            handler.postDelayed(this, 30000) // check every 30 seconds
        }
    }

    override fun onCreate() {
        super.onCreate()
        
        // Capture database file modification time BEFORE opening or writing to it
        val dbFile = getDatabasePath(CarStereoDbHelper.DATABASE_NAME)
        val lastDbModifiedMs = if (dbFile.exists()) dbFile.lastModified() else System.currentTimeMillis()

        dbHelper = CarStereoDbHelper(this)
        gpsPoints.clear()
        
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification("Monitoring vehicle speed..."))

        // Resume or finalize active trip
        checkResumeActiveTrip(lastDbModifiedMs)

        // Setup Location updates
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        try {
            // Request updates every 5 seconds, min distance 2 meters
            locationManager?.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                5000L,
                2.0f,
                this
            )
            Log.d("LocationService", "Location updates requested successfully.")
        } catch (e: SecurityException) {
            Log.e("LocationService", "Security exception requesting location updates: ${e.message}")
        } catch (e: Exception) {
            Log.e("LocationService", "Error requesting location: ${e.message}")
        }

        // Start inactivity check loop
        lastMovementTimeMs = System.currentTimeMillis()
        handler.post(inactivityRunnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("LocationService", "onStartCommand triggered.")
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(inactivityRunnable)
        locationManager?.removeUpdates(this)
        dbHelper.close()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // LocationListener interface implementations
    override fun onLocationChanged(location: Location) {
        val speedKmh = (location.speed * 3.6) // speed in km/h
        Log.d("LocationService", "Location update: Lat ${location.latitude}, Lng ${location.longitude}, Speed ${speedKmh} km/h")

        val now = System.currentTimeMillis()
        
        // Filter out bad/low-accuracy updates
        if (location.accuracy > 50) return

        if (!isTrackingActiveTrip) {
            // TRIP START DETECT: Speed exceeds 5 km/h
            if (speedKmh > 5.0) {
                startNewTrip(location)
            }
        } else {
            val lastLoc = lastLocation
            if (lastLoc != null) {
                val dist = location.distanceTo(lastLoc) / 1000.0 // in km
                
                // Filter GPS noise when stopped
                if (dist > 0.003) { 
                    distanceTravelled += dist
                    gpsPoints.add(Pair(location.latitude, location.longitude))
                    lastLocation = location
                    lastMovementTimeMs = now
                    
                    // Update global odometer in configuration
                    val currentOdo = startOdometer + distanceTravelled
                    dbHelper.setOdometer(currentOdo)

                    // Periodically update active trip in database
                    updateActiveTripInDb(currentOdo)
                }
            } else {
                lastLocation = location
                gpsPoints.add(Pair(location.latitude, location.longitude))
            }

            // Update Notification with live trip data
            val info = String.format(Locale.getDefault(), "Trip: %.2f km | %.1f km/h", distanceTravelled, speedKmh)
            updateNotification(info)
        }
    }

    private fun startNewTrip(location: Location) {
        val now = System.currentTimeMillis()
        activeTripId = UUID.randomUUID().toString()
        startTimeMs = now
        startOdometer = dbHelper.getOdometer()
        distanceTravelled = 0.0
        gpsPoints.clear()
        gpsPoints.add(Pair(location.latitude, location.longitude))
        lastLocation = location
        lastMovementTimeMs = now
        isTrackingActiveTrip = true
        startAddress = "Address fetching..."
        
        // Create trip in database with 'Active' status
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.getDefault())
        val dateStr = sdf.format(Date(now))

        val db = dbHelper.writableDatabase
        val values = ContentValues().apply {
            put(CarStereoDbHelper.COLUMN_ID, activeTripId)
            put(CarStereoDbHelper.COLUMN_USER_ID, dbHelper.getUserId())
            put(CarStereoDbHelper.COLUMN_DATE, dateStr)
            put(CarStereoDbHelper.COLUMN_DISTANCE, 0.0)
            put(CarStereoDbHelper.COLUMN_START_ODO, startOdometer)
            put(CarStereoDbHelper.COLUMN_END_ODO, startOdometer)
            put(CarStereoDbHelper.COLUMN_GPS_PATH, formatGpsPath(gpsPoints))
            put(CarStereoDbHelper.COLUMN_DURATION, 0)
            put(CarStereoDbHelper.COLUMN_STATUS, "Active")
            put(CarStereoDbHelper.COLUMN_START_LOC, "Lat: ${location.latitude}, Lng: ${location.longitude}")
            put(CarStereoDbHelper.COLUMN_END_LOC, "")
            put(CarStereoDbHelper.COLUMN_START_TIME, dateStr)
            put(CarStereoDbHelper.COLUMN_END_TIME, "")
            put(CarStereoDbHelper.COLUMN_FUEL_USED, 0.0)
            put(CarStereoDbHelper.COLUMN_MILEAGE, dbHelper.getMileage())
        }
        db.insert(CarStereoDbHelper.TABLE_TRIPS, null, values)
        Log.d("LocationService", "Started new trip in DB: $activeTripId")

        // Perform async reverse geocoding for start location
        fetchStartAddress(location.latitude, location.longitude)
    }

    private fun updateActiveTripInDb(currentOdo: Double) {
        val tripId = activeTripId ?: return
        val durationSecs = ((System.currentTimeMillis() - startTimeMs) / 1000).toInt()
        val db = dbHelper.writableDatabase
        val values = ContentValues().apply {
            put(CarStereoDbHelper.COLUMN_DISTANCE, distanceTravelled)
            put(CarStereoDbHelper.COLUMN_END_ODO, currentOdo)
            put(CarStereoDbHelper.COLUMN_GPS_PATH, formatGpsPath(gpsPoints))
            put(CarStereoDbHelper.COLUMN_DURATION, durationSecs)
        }
        db.update(CarStereoDbHelper.TABLE_TRIPS, values, "${CarStereoDbHelper.COLUMN_ID} = ?", arrayOf(tripId))
    }

    private fun checkTripInactivity() {
        if (!isTrackingActiveTrip) return
        val now = System.currentTimeMillis()
        val inactiveDurationMs = now - lastMovementTimeMs
        
        // 30 minutes in ms = 30 * 60 * 1000 = 1,800,000 ms
        if (inactiveDurationMs >= 30 * 60 * 1000) {
            Log.d("LocationService", "Inactivity limit reached (30 mins). Stopping trip.")
            finalizeTrip()
        }
    }

    private fun finalizeTrip() {
        val tripId = activeTripId ?: return
        val now = System.currentTimeMillis()
        val durationSecs = ((now - startTimeMs) / 1000).toInt()
        val finalOdo = startOdometer + distanceTravelled
        
        // Update DB configuration with final odometer
        dbHelper.setOdometer(finalOdo)

        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.getDefault())
        val endDateStr = sdf.format(Date(now))
        val mileage = dbHelper.getMileage()
        val fuelUsed = if (mileage > 0.0) distanceTravelled / mileage else 0.0

        val lastPt = gpsPoints.lastOrNull()
        val endLat = lastPt?.first ?: 0.0
        val endLng = lastPt?.second ?: 0.0

        // Perform async reverse geocoding for end location
        fetchEndAddressAndComplete(tripId, endLat, endLng, finalOdo, durationSecs, endDateStr, fuelUsed, mileage)

        // Reset service states
        isTrackingActiveTrip = false
        activeTripId = null
        gpsPoints.clear()
        lastLocation = null
        updateNotification("Monitoring vehicle speed...")
    }

    private fun fetchStartAddress(lat: Double, lng: Double) {
        thread {
            try {
                val geocoder = Geocoder(this, Locale.getDefault())
                val addresses = geocoder.getFromLocation(lat, lng, 1)
                if (!addresses.isNullOrEmpty()) {
                    val address = addresses[0]
                    val addressParts = ArrayList<String>()
                    for (i in 0..address.maxAddressLineIndex) {
                        addressParts.add(address.getAddressLine(i))
                    }
                    val fullAddress = addressParts.joinToString(", ")
                    startAddress = fullAddress

                    // Update start address in DB
                    val db = dbHelper.writableDatabase
                    val values = ContentValues().apply {
                        put(CarStereoDbHelper.COLUMN_START_LOC, fullAddress)
                    }
                    db.update(CarStereoDbHelper.TABLE_TRIPS, values, "${CarStereoDbHelper.COLUMN_ID} = ?", arrayOf(activeTripId))
                    Log.d("LocationService", "Updated start address: $fullAddress")
                }
            } catch (e: Exception) {
                Log.e("LocationService", "Geocoder error: ${e.message}")
            }
        }
    }

    private fun fetchEndAddressAndComplete(
        tripId: String,
        lat: Double,
        lng: Double,
        finalOdo: Double,
        durationSecs: Int,
        endDateStr: String,
        fuelUsed: Double,
        mileage: Double
    ) {
        thread {
            var endAddressStr = "Lat: $lat, Lng: $lng"
            try {
                val geocoder = Geocoder(this, Locale.getDefault())
                val addresses = geocoder.getFromLocation(lat, lng, 1)
                if (!addresses.isNullOrEmpty()) {
                    val address = addresses[0]
                    val addressParts = ArrayList<String>()
                    for (i in 0..address.maxAddressLineIndex) {
                        addressParts.add(address.getAddressLine(i))
                    }
                    endAddressStr = addressParts.joinToString(", ")
                }
            } catch (e: Exception) {
                Log.e("LocationService", "Geocoder error: ${e.message}")
            }

            // Write final completed record to DB
            val db = dbHelper.writableDatabase
            val values = ContentValues().apply {
                put(CarStereoDbHelper.COLUMN_DISTANCE, distanceTravelled)
                put(CarStereoDbHelper.COLUMN_END_ODO, finalOdo)
                put(CarStereoDbHelper.COLUMN_GPS_PATH, formatGpsPath(gpsPoints))
                put(CarStereoDbHelper.COLUMN_DURATION, durationSecs)
                put(CarStereoDbHelper.COLUMN_STATUS, "Completed")
                put(CarStereoDbHelper.COLUMN_END_LOC, endAddressStr)
                put(CarStereoDbHelper.COLUMN_END_TIME, endDateStr)
                put(CarStereoDbHelper.COLUMN_FUEL_USED, fuelUsed)
                put(CarStereoDbHelper.COLUMN_MILEAGE, mileage)
            }
            db.update(CarStereoDbHelper.TABLE_TRIPS, values, "${CarStereoDbHelper.COLUMN_ID} = ?", arrayOf(tripId))
            Log.d("LocationService", "Finalized and saved completed trip $tripId to DB. Distance: $distanceTravelled, EndAddress: $endAddressStr")
        }
    }

    private fun checkResumeActiveTrip(lastDbModifiedMs: Long) {
        val db = dbHelper.writableDatabase
        val cursor = db.rawQuery(
            "SELECT id, startOdometer, distanceTravelled, gpsPath, startTime, startLocation FROM car_trips WHERE status = 'Active' LIMIT 1",
            null
        )
        if (cursor.moveToFirst()) {
            val tripId = cursor.getString(0)
            val startOdo = cursor.getDouble(1)
            val distTravelled = cursor.getDouble(2)
            val pathJson = cursor.getString(3)
            val startTimeStr = cursor.getString(4)
            val startLoc = cursor.getString(5) ?: ""

            val now = System.currentTimeMillis()
            val idleDurationMs = now - lastDbModifiedMs

            Log.d("LocationService", "Found Active trip in DB. Last modified time: $lastDbModifiedMs, idle: ${idleDurationMs / 1000}s")

            if (idleDurationMs > 30 * 60 * 1000) {
                // More than 30 minutes of inactivity: Finalize the trip!
                Log.d("LocationService", "Active trip was idle for >30 mins. Finalizing it now.")
                
                // Parse points to find last coordinate for end location
                var endLat = 0.0
                var endLng = 0.0
                val pts = ArrayList<Pair<Double, Double>>()
                if (!pathJson.isNullOrEmpty() && pathJson != "[]") {
                    try {
                        val clean = pathJson.replace("[", "").replace("]", "").trim()
                        if (clean.isNotEmpty()) {
                            val parts = clean.split(",")
                            for (i in 0 until parts.size - 1 step 2) {
                                val lat = parts[i].trim().toDoubleOrNull()
                                val lng = parts[i+1].trim().toDoubleOrNull()
                                if (lat != null && lng != null) {
                                    pts.add(Pair(lat, lng))
                                }
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("LocationService", "Error parsing path JSON: ${e.message}")
                    }
                }
                val lastPt = pts.lastOrNull()
                if (lastPt != null) {
                    endLat = lastPt.first
                    endLng = lastPt.second
                }

                val finalOdo = startOdo + distTravelled
                val durationSecs = ((lastDbModifiedMs - getStartTimeMs(startTimeStr)) / 1000).toInt().coerceAtLeast(0)
                val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.getDefault())
                val endDateStr = sdf.format(Date(lastDbModifiedMs))
                val mileage = dbHelper.getMileage()
                val fuelUsed = if (mileage > 0.0) distTravelled / mileage else 0.0

                fetchEndAddressAndCompleteResumed(
                    tripId,
                    endLat,
                    endLng,
                    finalOdo,
                    durationSecs,
                    endDateStr,
                    fuelUsed,
                    mileage,
                    pathJson,
                    distTravelled
                )
            } else {
                // Less than 30 minutes: Resume it!
                activeTripId = tripId
                startOdometer = startOdo
                distanceTravelled = distTravelled
                
                gpsPoints.clear()
                if (!pathJson.isNullOrEmpty() && pathJson != "[]") {
                    try {
                        val clean = pathJson.replace("[", "").replace("]", "").trim()
                        if (clean.isNotEmpty()) {
                            val parts = clean.split(",")
                            for (i in 0 until parts.size - 1 step 2) {
                                val lat = parts[i].trim().toDoubleOrNull()
                                val lng = parts[i+1].trim().toDoubleOrNull()
                                if (lat != null && lng != null) {
                                    gpsPoints.add(Pair(lat, lng))
                                }
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("LocationService", "Error parsing resumed path JSON: ${e.message}")
                    }
                }
                isTrackingActiveTrip = true
                lastMovementTimeMs = System.currentTimeMillis()
                lastLocation = gpsPoints.lastOrNull()?.let {
                    Location("GPS").apply {
                        latitude = it.first
                        longitude = it.second
                    }
                }
                startAddress = startLoc
                Log.d("LocationService", "Resumed active trip: $activeTripId. Points count: ${gpsPoints.size}, distance: $distanceTravelled km")
            }
        }
        cursor.close()
    }

    private fun getStartTimeMs(dateStr: String): Long {
        return try {
            val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.getDefault())
            sdf.parse(dateStr)?.time ?: System.currentTimeMillis()
        } catch (e: Exception) {
            System.currentTimeMillis()
        }
    }

    private fun fetchEndAddressAndCompleteResumed(
        tripId: String,
        lat: Double,
        lng: Double,
        finalOdo: Double,
        durationSecs: Int,
        endDateStr: String,
        fuelUsed: Double,
        mileage: Double,
        pathJson: String,
        distTravelled: Double
    ) {
        thread {
            var endAddressStr = "Lat: $lat, Lng: $lng"
            try {
                val geocoder = Geocoder(this, Locale.getDefault())
                val addresses = geocoder.getFromLocation(lat, lng, 1)
                if (!addresses.isNullOrEmpty()) {
                    val address = addresses[0]
                    val addressParts = ArrayList<String>()
                    for (i in 0..address.maxAddressLineIndex) {
                        addressParts.add(address.getAddressLine(i))
                    }
                    endAddressStr = addressParts.joinToString(", ")
                }
            } catch (e: Exception) {
                Log.e("LocationService", "Geocoder error: ${e.message}")
            }

            // Write final completed record to DB
            val db = dbHelper.writableDatabase
            val values = ContentValues().apply {
                put(CarStereoDbHelper.COLUMN_DISTANCE, distTravelled)
                put(CarStereoDbHelper.COLUMN_END_ODO, finalOdo)
                put(CarStereoDbHelper.COLUMN_GPS_PATH, pathJson)
                put(CarStereoDbHelper.COLUMN_DURATION, durationSecs)
                put(CarStereoDbHelper.COLUMN_STATUS, "Completed")
                put(CarStereoDbHelper.COLUMN_END_LOC, endAddressStr)
                put(CarStereoDbHelper.COLUMN_END_TIME, endDateStr)
                put(CarStereoDbHelper.COLUMN_FUEL_USED, fuelUsed)
                put(CarStereoDbHelper.COLUMN_MILEAGE, mileage)
            }
            db.update(CarStereoDbHelper.TABLE_TRIPS, values, "${CarStereoDbHelper.COLUMN_ID} = ?", arrayOf(tripId))
            Log.d("LocationService", "Finalized and saved completed previous trip $tripId to DB. Distance: $distTravelled, EndAddress: $endAddressStr")
        }
    }

    private fun formatGpsPath(points: List<Pair<Double, Double>>): String {
        val sb = StringBuilder()
        sb.append("[")
        for (i in points.indices) {
            val p = points[i]
            sb.append("[").append(p.first).append(",").append(p.second).append("]")
            if (i < points.size - 1) {
                sb.append(",")
            }
        }
        sb.append("]")
        return sb.toString()
    }

    // Helper functions for Notifications
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Car Stereo Location Tracking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps tracking car location, speed, and trips in background."
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(contentText: String): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Car Stereo GPS Running")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun updateNotification(text: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(text))
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}
}
