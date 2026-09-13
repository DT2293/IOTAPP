const User = require("../models/user");
const SensorDataRaw = require("../models/sensordata_raw");
const { handleAlert } = require("../fcm_services/handleAleart2");
const store = require("../store/memoryStore");

const sendData = async () => {
  const users = await User.find().select("userId devices");

  for (const user of users) {
    for (const deviceId of user.devices) {
      const newData = store.latestSensorDataMap.get(deviceId);
      if (!newData) continue;

      if (newData.smokeLevel >= 300 || newData.flame === true) {
        await handleAlert(deviceId, newData);
      }
      store.previousData.set(deviceId, newData);
    }
  }
};

const saveRawSensorData = async () => {
  try {
    const users = await User.find().select("userId devices");

    for (const user of users) {
      for (const deviceId of user.devices) {
        const data = store.latestSensorDataMap.get(deviceId);
        if (!data) continue;

        const { smokeLevel, flame } = data;
        const temperature = data.temperature ?? 0;
        const humidity = data.humidity ?? 0;

        const rawEntry = new SensorDataRaw({
          userId: user.userId,
          deviceId,
          temperature,
          humidity,
          smokeLevel,
          flameDetected: flame,
        });

        await rawEntry.save();
      }
    }
  } catch (err) {
    console.error("Lỗi khi lưu sensor raw:", err);
  }
};

const startJobs = () => {
  setInterval(saveRawSensorData, 5 * 60 * 1000); // 5 phút
  setInterval(sendData, 5000); // 5 giây
  console.log("⏳ Các tiến trình ngầm (Scheduler) đã được khởi động.");
};

module.exports = startJobs;
