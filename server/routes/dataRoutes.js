const express = require("express");
const router = express.Router();
const SensorData = require("../models/sensordata");
const authMiddleware = require("../utils/authMiddleware");
const asyncHandler = require("../utils/asyncHandler");

router.get(
  "/sensordata/:deviceId",
  authMiddleware,
  asyncHandler(async (req, res) => {
    const records = await SensorData.find({ deviceId: req.params.deviceId })
      .sort({ timestamp: 1 })
      .select(
        "averageTemperature averageHumidity averageSmokeLevel flameDetected date -_id",
      )
      .lean();

    res.json(records);
  }),
);

module.exports = router;
