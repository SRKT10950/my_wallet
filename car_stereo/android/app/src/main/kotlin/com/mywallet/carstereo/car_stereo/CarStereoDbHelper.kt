package com.mywallet.carstereo.car_stereo

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import java.util.UUID

class CarStereoDbHelper(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {
    companion object {
        const val DATABASE_NAME = "car_stereo.db"
        const val DATABASE_VERSION = 1

        const val TABLE_TRIPS = "car_trips"
        const val COLUMN_ID = "id"
        const val COLUMN_USER_ID = "user_id"
        const val COLUMN_DATE = "date"
        const val COLUMN_DISTANCE = "distanceTravelled"
        const val COLUMN_START_ODO = "startOdometer"
        const val COLUMN_END_ODO = "endOdometer"
        const val COLUMN_GPS_PATH = "gpsPath"
        const val COLUMN_DURATION = "durationSeconds"
        const val COLUMN_STATUS = "status"
        const val COLUMN_START_LOC = "startLocation"
        const val COLUMN_END_LOC = "endLocation"
        const val COLUMN_START_TIME = "startTime"
        const val COLUMN_END_TIME = "endTime"
        const val COLUMN_FUEL_USED = "fuelUsed"
        const val COLUMN_MILEAGE = "mileage"
    }

    override fun onCreate(db: SQLiteDatabase) {
        val createTripsTable = ("CREATE TABLE " + TABLE_TRIPS + "("
                + COLUMN_ID + " TEXT PRIMARY KEY,"
                + COLUMN_USER_ID + " TEXT,"
                + COLUMN_DATE + " TEXT,"
                + COLUMN_DISTANCE + " REAL,"
                + COLUMN_START_ODO + " REAL,"
                + COLUMN_END_ODO + " REAL,"
                + COLUMN_GPS_PATH + " TEXT,"
                + COLUMN_DURATION + " INTEGER,"
                + COLUMN_STATUS + " TEXT,"
                + COLUMN_START_LOC + " TEXT,"
                + COLUMN_END_LOC + " TEXT,"
                + COLUMN_START_TIME + " TEXT,"
                + COLUMN_END_TIME + " TEXT,"
                + COLUMN_FUEL_USED + " REAL,"
                + COLUMN_MILEAGE + " REAL" + ")")
        db.execSQL(createTripsTable)

        // Create a settings/config table
        db.execSQL("CREATE TABLE IF NOT EXISTS config ("
                + "key TEXT PRIMARY KEY,"
                + "value TEXT" + ")")
        
        // Insert default configs
        db.execSQL("INSERT OR IGNORE INTO config (key, value) VALUES ('currentOdometer', '0.0')")
        db.execSQL("INSERT OR IGNORE INTO config (key, value) VALUES ('mileage', '15.0')")
        db.execSQL("INSERT OR IGNORE INTO config (key, value) VALUES ('user_id', '')")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_TRIPS")
        db.execSQL("DROP TABLE IF EXISTS config")
        onCreate(db)
    }

    fun getOdometer(): Double {
        val db = this.readableDatabase
        val cursor = db.rawQuery("SELECT value FROM config WHERE key = 'currentOdometer'", null)
        var odo = 0.0
        if (cursor.moveToFirst()) {
            odo = cursor.getString(0).toDoubleOrNull() ?: 0.0
        }
        cursor.close()
        return odo
    }

    fun setOdometer(odo: Double) {
        val db = this.writableDatabase
        val values = ContentValues().apply {
            put("value", odo.toString())
        }
        db.update("config", values, "key = 'currentOdometer'", null)
    }

    fun getMileage(): Double {
        val db = this.readableDatabase
        val cursor = db.rawQuery("SELECT value FROM config WHERE key = 'mileage'", null)
        var mileage = 15.0
        if (cursor.moveToFirst()) {
            mileage = cursor.getString(0).toDoubleOrNull() ?: 15.0
        }
        cursor.close()
        return mileage
    }

    fun getUserId(): String {
        val db = this.readableDatabase
        val cursor = db.rawQuery("SELECT value FROM config WHERE key = 'user_id'", null)
        var userId = ""
        if (cursor.moveToFirst()) {
            userId = cursor.getString(0)
        }
        cursor.close()
        return userId
    }
}
