package app.recall.recall

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createRecallDropsChannel()
    }

    // High-importance channel for Recall Drops so backgrounded/terminated pushes
    // display as heads-up. FCM messages target this channel via channel_id and the
    // default_notification_channel_id manifest meta-data. Created on first launch
    // (onboarding), which always precedes any Drop opt-in.
    private fun createRecallDropsChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Recall Drops",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Alerts when a fresh set of cards is ready to review."
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "recall_drops"
    }
}
