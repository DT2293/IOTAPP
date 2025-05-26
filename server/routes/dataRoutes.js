
const express = require("express");
const router = express.Router();
const SensorData = require("../models/sensordata");
const authMiddleware = require("../utils/authMiddleware");
router.get('/sensordata/:deviceId', authMiddleware, async (req, res) => {
  const deviceId = req.params.deviceId;

  try {
    const records = await SensorData.find({ deviceId })
      .sort({ timestamp: 1 })
      .select('averageTemperature averageHumidity averageSmokeLevel flameDetected date -_id'); // chỉ lấy trường cần thiết

    res.json(records);
  } catch (error) {
    console.error('❌ Lỗi lấy data:', error);
    res.status(500).json({ message: 'Lỗi server khi lấy dữ liệu' });
  }
});

module.exports = router;