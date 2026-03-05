package com.homefix.technician

import io.flutter.embedding.android.FlutterActivity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Create notification channels for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Job Alerts Channel (Technician App)
            val jobAlertsChannel = NotificationChannel(
                "job_alerts_channel",
                "Job Alerts",
                NotificationManager.IMPORTANCE_MAX
            )
            jobAlertsChannel.description = "New job requests and status updates."
            jobAlertsChannel.enableVibration(true)
            jobAlertsChannel.setSound(
                android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION),
                android.media.AudioAttributes.Builder()
                    .setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION)
                    .build()
            )
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(jobAlertsChannel)
        }
    }
}

