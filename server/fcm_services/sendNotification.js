// sendNotification.js


const admin = require("firebase-admin");

if (!admin.apps.length) {
  const serviceAccount = require("../fcm_services/firebase-service-account.json");

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

async function sendNotificationToDevice(fcmToken, title, body, data = {}) {
  const message = {
    token: fcmToken,
    notification: {
      title,
      body,
    },
    data,
    android: {
      priority: "high",
      notification: {
        channelId: "iot_alerts_channel",
        sound: "default",
        defaultVibrateTimings: true,
        defaultLightSettings: true,
      },
    },
  };

  console.log("🔧 Message Object:", message);

  try {
    const response = await admin.messaging().send(message);
    console.log("✅ Gửi thông báo thành công:", response);
  } catch (error) {
    console.error("❌ Lỗi khi gửi thông báo:", error.message);
  }
}

module.exports = { sendNotificationToDevice };  // Chỉ xuất một lần
