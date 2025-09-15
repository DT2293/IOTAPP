// // handleAlert.js
const User = require("../models/user");
const { sendNotificationToDevice } = require("./sendNotification");  

async function handleAlert(deviceId, sensorData) {
  const users = await User.find({ devices: deviceId });

  for (const user of users) {
    const fcmTokens = user.fcmToken; 

    if (fcmTokens && Array.isArray(fcmTokens) && fcmTokens.length > 0) {
      const title = "Cảnh báo cháy!";
      const body = `Nhiệt độ: ${sensorData.temperature}°C, Khói: ${sensorData.smokeLevel}`;
      for (const fcmToken of fcmTokens) {
        
        await sendNotificationToDevice(fcmToken, title, body, { deviceId, type: "fire_alert" });
      }
    } else {
      console.error(`FCM token không hợp lệ cho user ${user.userId}`);
    }
  }
}

module.exports = { handleAlert };



