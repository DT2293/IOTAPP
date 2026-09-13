const express = require("express");
const router = express.Router();

const authRoutes = require("./authRoutes");
const deviceRoutes = require("./deviceRoutes");
const dataRoutes = require("./dataRoutes");
const fcmRoutes = require("./fcmRoutes");
const { receiveSensorData } = require("../controllers/sensorController");

router.use("/auth", authRoutes);
router.use("/devices", deviceRoutes);
router.use("/data", dataRoutes);
router.use("/fcm", fcmRoutes);
router.post("/sensordata", receiveSensorData);
module.exports = router;
