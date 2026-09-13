const admin = require("firebase-admin");

if (!admin.apps.length) {
  try {
    const serviceAccount = require("./messapp-9d1bc-firebase-adminsdk-fbsvc-0d5f2bf8f4.json");
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } catch (error) {
    console.error("Lỗi khởi tạo Firebase Admin:", error.message);
  }
}

async function sendNotificationToDevice(fcmToken, title, body, data = {}) {
  const message = {
    token: fcmToken,
    notification: { title, body },
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

  try {
    await admin.messaging().send(message);
  } catch (error) {
    console.error(`Lỗi gửi FCM Token (${fcmToken}):`, error.message);
  }
}

module.exports = { sendNotificationToDevice };
