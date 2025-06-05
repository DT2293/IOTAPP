// // // handleAlert.js
// const User = require("../models/user");
// const { sendNotificationToDevice } = require("./sendNotification");  // Đảm bảo chỉ import một lần

// async function handleAlert(deviceId, sensorData) {
//   const users = await User.find({ devices: deviceId });

//   for (const user of users) {
//     const fcmTokens = user.fcmToken;  // Lấy mảng fcmTokens từ cơ sở dữ liệu

//   //  console.log(`🔍 Đang xử lý user ${user.userId} với FCM tokens:`, fcmTokens);

//     if (fcmTokens && Array.isArray(fcmTokens) && fcmTokens.length > 0) {
//       const title = "🚨 Cảnh báo cháy!";
//      const body = `🔥 Thiết bị ${deviceId} phát hiện cháy!\nKhói: ${sensorData.smokeLevel} `;
//       // Lặp qua tất cả các FCM token của user và gửi thông báo
//       for (const fcmToken of fcmTokens) {
//      //   console.log(`📬 Gửi thông báo đến FCM Token: ${fcmToken}`);
        
//         await sendNotificationToDevice(fcmToken, title, body, { deviceId, type: "fire_alert" });

//       }
//     } else {
//       console.error(`❌ FCM token không hợp lệ cho user ${user.userId}`);
//     }
//   }
// }

// module.exports = { handleAlert };



const User = require("../models/user");
const { sendNotificationToDevice } = require("./sendNotification");

// Bộ từ vựng đa ngôn ngữ cho thông báo
const translations = {
  vi: {
    title: "🚨 Cảnh báo cháy!",
    body: (deviceId, smokeLevel) =>
      `🔥 Thiết bị ${deviceId} phát hiện cháy!\nMức khói: ${smokeLevel}`,
  },
  en: {
    title: "🚨 Fire Alert!",
    body: (deviceId, smokeLevel) =>
      `🔥 Device ${deviceId} detected fire!\nSmoke level: ${smokeLevel}`,
  },
};

async function handleAlert(deviceId, sensorData) {
  const users = await User.find({ devices: deviceId });

  for (const user of users) {
    const fcmTokens = user.fcmToken;
    const language = user.language || "vi"; // Mặc định tiếng Việt nếu chưa lưu

    // Lấy nội dung dịch phù hợp
    const localized = translations[language] || translations["vi"];
    const title = localized.title;
    const body = localized.body(deviceId, sensorData.smokeLevel);

    if (fcmTokens && Array.isArray(fcmTokens) && fcmTokens.length > 0) {
      for (const fcmToken of fcmTokens) {
        await sendNotificationToDevice(fcmToken, title, body, {
          deviceId,
          type: "fire_alert",
        });
      }
    } else {
      console.error(`❌ FCM token không hợp lệ cho user ${user.userId}`);
    }
  }
}

module.exports = { handleAlert };
