// // handleAlert.js
const User = require("../models/user");
const { sendNotificationToDevice } = require("./sendNotification");  // Đảm bảo chỉ import một lần

// async function handleAlert(deviceId, sensorData) {
//   const users = await User.find({ devices: deviceId });

//   for (const user of users) {
//     const fcmTokens = user.fcmToken;  // Lấy mảng fcmTokens từ cơ sở dữ liệu

//     console.log(`🔍 Đang xử lý user ${user.userId} với FCM tokens:`, fcmTokens);

//     if (fcmTokens && Array.isArray(fcmTokens) && fcmTokens.length > 0) {
//       const title = "🚨 Cảnh báo cháy!";
//       const body = `Nhiệt độ: ${sensorData.temperature}°C, Khói: ${sensorData.smokeLevel}`;

//       // Lặp qua tất cả các FCM token của user và gửi thông báo
//       for (const fcmToken of fcmTokens) {
//         console.log(`📬 Gửi thông báo đến FCM Token: ${fcmToken}`);
        
//         await sendNotificationToDevice(fcmToken, title, body, { deviceId, type: "fire_alert" });
//       }
//     } else {
//       console.error(`❌ FCM token không hợp lệ cho user ${user.userId}`);
//     }
//   }
// }

// module.exports = { handleAlert };



// Các ngưỡng theo nghiên cứu khoa học (ví dụ có thể điều chỉnh theo từng môi trường cụ thể)
const FIRE_THRESHOLDS = {
  temperature_warning: 50,
  temperature_critical: 60,
  smoke_warning: 300,
  smoke_critical: 400,
  rateOfRise: 8 // °C/phút
};

async function handleAlert(deviceId, sensorData) {
  const users = await User.find({ devices: deviceId });
  const { temperature, smokeLevel, rateOfRise } = sensorData;

  // ===== Xác định cấp độ cảnh báo cháy =====
  let fireLevel = "normal";
  if (
    temperature >= FIRE_THRESHOLDS.temperature_critical ||
    smokeLevel >= FIRE_THRESHOLDS.smoke_critical
  ) {
    fireLevel = "critical";
  } else if (
    temperature >= FIRE_THRESHOLDS.temperature_warning ||
    smokeLevel >= FIRE_THRESHOLDS.smoke_warning
  ) {
    fireLevel = "warning";
  }

  // ===== Xác định có cần cảnh báo tăng nhiệt nhanh không =====
  const isRateOfRiseDanger = rateOfRise >= FIRE_THRESHOLDS.rateOfRise;

  for (const user of users) {
    const fcmTokens = user.fcmToken;

    console.log(`🔍 Đang xử lý user ${user.userId} với FCM tokens:`, fcmTokens);

    if (Array.isArray(fcmTokens) && fcmTokens.length > 0) {

      // --- Gửi cảnh báo tăng nhiệt nhanh nếu có ---
      if (isRateOfRiseDanger) {
        const rorTitle = "⚠️ Cảnh báo tăng nhiệt nhanh!";
        const rorBody = `🚀 Thiết bị ${deviceId} có tốc độ tăng nhiệt đáng ngờ:\n📈 ${rateOfRise}°C/phút\n🌡 Nhiệt độ hiện tại: ${temperature}°C`;

        for (const token of fcmTokens) {
          console.log(`📬 Gửi cảnh báo ROR đến FCM Token: ${token}`);
          await sendNotificationToDevice(token, rorTitle, rorBody, {
            deviceId,
            type: "ror_warning",
            rateOfRise,
            temperature,
            timestamp: Date.now()
          });
        }
      }

      // --- Gửi cảnh báo cháy nếu đủ điều kiện ---
      if (fireLevel !== "normal") {
        const title = fireLevel === "critical"
          ? "🚨 CHÁY NGHIÊM TRỌNG!"
          : "⚠️ Cảnh báo nguy cơ cháy";
        const body = `🔥 Thiết bị ${deviceId}\n🌡 Nhiệt độ: ${temperature}°C\n💨 Mức khói: ${smokeLevel} ppm`;

        for (const token of fcmTokens) {
          console.log(`📬 Gửi cảnh báo cháy (${fireLevel}) đến FCM Token: ${token}`);
          await sendNotificationToDevice(token, title, body, {
            deviceId,
            type: "fire_alert",
            level: fireLevel,
            timestamp: Date.now()
          });
        }
      }

    } else {
      console.warn(`⚠️ User ${user.userId} không có FCM token hợp lệ.`);
    }
  }
}

module.exports = { handleAlert };
