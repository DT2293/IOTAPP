const { sendNotificationToDevice } = require("./fcm_services/sendNotification");

const fcmToken = "eey0mME-QkeM1wLYqR99BE:APA91bG3pDlDDSbtevwAKeGPafRaTsFZwr8ywnYg-PTlamaDz8pE4jX-OOohH_Grumct47QXKUimS09_CJQAtrqvF85JfxbGwKqG_TsYKaVu7P_Jb-ilz7o"; // 🔁 Thay bằng token thật từ thiết bị
const title = "🔥 Test Notification";
const body = "Đây là thông báo test FCM từ test.js";
const data = {
  deviceId: "test_device_123",
  type: "fire_alert",
};

(async () => {
  console.log("🚀 Đang gửi thông báo test...");
  await sendNotificationToDevice(fcmToken, title, body, data);
})();
