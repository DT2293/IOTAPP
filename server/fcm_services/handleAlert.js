// // handleAlert.js
const User = require("../models/user");
const { sendNotificationToDevice } = require("./sendNotification");  // Đảm bảo chỉ import một lần

async function handleAlert(deviceId, sensorData) {
  const users = await User.find({ devices: deviceId });

  for (const user of users) {
    const fcmTokens = user.fcmToken;  // Lấy mảng fcmTokens từ cơ sở dữ liệu

    console.log(`🔍 Đang xử lý user ${user.userId} với FCM tokens:`, fcmTokens);

    if (fcmTokens && Array.isArray(fcmTokens) && fcmTokens.length > 0) {
      const title = "🚨 Cảnh báo cháy!";
      const body = `Nhiệt độ: ${sensorData.temperature}°C, Khói: ${sensorData.smokeLevel}`;

      // Lặp qua tất cả các FCM token của user và gửi thông báo
      for (const fcmToken of fcmTokens) {
       // console.log(`📬 Gửi thông báo đến FCM Token: ${fcmToken}`);
        
        await sendNotificationToDevice(fcmToken, title, body, { deviceId, type: "fire_alert" });
      }
    } else {
      console.error(`❌ FCM token không hợp lệ cho user ${user.userId}`);
    }
  }
}

module.exports = { handleAlert };



