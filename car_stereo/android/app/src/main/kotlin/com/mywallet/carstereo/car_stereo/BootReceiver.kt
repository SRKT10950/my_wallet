package com.mywallet.carstereo.car_stereo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("BootReceiver", "Received broadcast: ${intent.action}")
        val serviceIntent = Intent(context, LocationService::class.java)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.d("BootReceiver", "Started LocationService successfully.")
        } catch (e: Exception) {
            Log.e("BootReceiver", "Error starting LocationService: ${e.message}", e)
        }
    }
}
