const User = require("../models/user");
const store = require("../store/memoryStore");

const receiveSensorData = async (req, res) => {
  try {
    const { deviceId, temperature, humidity, smokeLevel, flame } = req.body;

    if (typeof smokeLevel !== "number" || typeof flame !== "boolean") {
      return res.status(400).json({ message: "Dữ liệu không hợp lệ" });
    }

    const sensorData = {
      deviceId,
      temperature,
      humidity,
      smokeLevel,
      flame,
      time: new Date(),
    };

    // Cập nhật dữ liệu vào Store chung
    store.previousData.set(deviceId, sensorData);
    store.latestSensorDataMap.set(deviceId, sensorData);

    const users = await User.find({ devices: deviceId }).select(
      "userId devices",
    );

    // Broadcast dữ liệu qua WebSocket cho các user sở hữu thiết bị
    for (const user of users) {
      const userClients = store.clients.get(user.userId);
      if (userClients) {
        for (const ws of userClients) {
          if (ws.readyState === ws.OPEN) {
            ws.send(JSON.stringify({ type: "sensordatas", data: sensorData }));
          }
        }
      }
    }

    res.status(200).json({ message: "Dữ liệu nhận thành công" });
  } catch (error) {
    console.error("Lỗi xử lý dữ liệu:", error);
    res.status(500).json({ message: "Lỗi server" });
  }
};

module.exports = { receiveSensorData };
