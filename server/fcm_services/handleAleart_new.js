const User = require("../models/user");
const { sendNotificationToDevice } = require("./sendNotification");

const translations = {
  vi: {
    title: "Cảnh báo cháy!",
    body: (deviceId, smokeLevel) =>
      `Thiết bị ${deviceId} phát hiện cháy!\nMức khói: ${smokeLevel}`,
  },
  en: {
    title: "Fire Alert!",
    body: (deviceId, smokeLevel) =>
      `Device ${deviceId} detected fire!\nSmoke level: ${smokeLevel}`,
  },
};

async function handleAlert(deviceId, sensorData) {
  const users = await User.find({ devices: deviceId });

  const notificationPromises = [];

  for (const user of users) {
    const fcmTokens = user.fcmToken;
    if (!fcmTokens || fcmTokens.length === 0) {
      console.warn(`FCM token không hợp lệ cho user ${user.userId}`);
      continue;
    }

    const language = user.language || "vi";
    const localized = translations[language] || translations["vi"];
    const title = localized.title;
    const body = localized.body(deviceId, sensorData.smokeLevel);

    for (const fcmToken of fcmTokens) {
      notificationPromises.push(
        sendNotificationToDevice(fcmToken, title, body, {
          deviceId,
          type: "fire_alert",
        }),
      );
    }
  }

  // Gửi song song tất cả các thông báo để tối ưu hiệu năng
  await Promise.allSettled(notificationPromises);
}

module.exports = { handleAlert };
