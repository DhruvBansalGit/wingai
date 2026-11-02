package com.wingai.keyboard.capture

import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import com.wingai.keyboard.data.InputConnectionBridge

class ScreenCaptureService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startCaptureNotification()
        when (intent?.action) {
            ACTION_STOP_PROJECTION -> {
                ScreenCaptureManager.stopSession()
                stopSelf()
                return START_NOT_STICKY
            }

            else -> {
                val resultCode = intent?.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
                    ?: Activity.RESULT_CANCELED
                val resultData = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent?.getParcelableExtra(EXTRA_RESULT_DATA, Intent::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent?.getParcelableExtra(EXTRA_RESULT_DATA)
                }

                if (resultCode != Activity.RESULT_OK || resultData == null) {
                    stopSelf()
                    return START_NOT_STICKY
                }

                // One-shot frame capture: immediately stops MediaProjection and stops this service
                // as soon as the single screenshot frame is captured, then opens the Select & Search crop UI.
                ScreenCaptureManager.captureSingleFrameAndStop(
                    context = applicationContext,
                    resultCode = resultCode,
                    permissionData = resultData,
                    onCaptured = {
                        stopSelf()
                        val cropIntent = Intent(applicationContext, ScreenCaptureActivity::class.java).apply {
                            action = ScreenCaptureActivity.ACTION_SHOW_CROP
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        }
                        applicationContext.startActivity(cropIntent)
                    },
                    onError = { message ->
                        stopSelf()
                        InputConnectionBridge.updateState {
                            it.copy(isPanelOpen = true, isLoading = false, errorMessage = message)
                        }
                    }
                )
                return START_NOT_STICKY
            }
        }
    }

    private fun startCaptureNotification() {
        val channelId = "wingai_capture_channel"
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            channelId,
            "WingAI Snapshot",
            NotificationManager.IMPORTANCE_LOW
        )
        manager.createNotificationChannel(channel)
        val notification = Notification.Builder(this, channelId)
            .setContentTitle("WingAI Snapshot")
            .setContentText("Taking one snapshot for region selection...")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    override fun onDestroy() {
        ScreenCaptureManager.stopProjectionOnly()
        super.onDestroy()
    }

    companion object {
        private const val NOTIFICATION_ID = 4102
        const val ACTION_INIT_PROJECTION = "com.wingai.keyboard.action.INIT_PROJECTION"
        const val ACTION_CAPTURE_FRAME = "com.wingai.keyboard.action.CAPTURE_FRAME"
        const val ACTION_STOP_PROJECTION = "com.wingai.keyboard.action.STOP_PROJECTION"
        const val EXTRA_RESULT_CODE = "extra_result_code"
        const val EXTRA_RESULT_DATA = "extra_result_data"
        const val EXTRA_CAPTURE_IMMEDIATELY = "extra_capture_immediately"
    }
}
