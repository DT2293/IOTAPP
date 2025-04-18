package com.example.iotapp

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        // Kiểm tra xem thông báo có chứa thông tin notification hay không
        remoteMessage.notification?.let {
            val title = it.title
            val body = it.body
            sendNotification(title, body)
        }
    }

    private fun sendNotification(title: String?, body: String?) {
        val channelId = "iot_alerts_channel"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Sử dụng title và body đã truyền vào thay vì message
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)  // Đặt title từ tham số
            .setContentText(body)    // Đặt body từ tham số
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Sử dụng biểu tượng mặc định của Android
            .build()

        notificationManager.notify(0, notification)
    }
}
