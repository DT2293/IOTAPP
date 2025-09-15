const axios = require("axios");
const express = require("express");
const router = express.Router();
const Device = require("../models/Device");
const User = require("../models/user");
const authMiddleware = require("../utils/authMiddleware");



router.get("/devices/:userId", authMiddleware, async (req, res) => {
  try {
    const userId = Number(req.params.userId);

    if (userId !== req.user.userId) {
      return res.status(403).json({ error: "Bạn không có quyền truy cập thiết bị của user khác!" });
    }
    const devices = await Device.find({ userId });

    return res.json({ devices });
  } catch (error) {
    console.error("Lỗi khi lấy danh sách thiết bị:", error);
    return res.status(500).json({ error: "Lỗi server" });
  }
});

router.post("/", authMiddleware, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { deviceId ,deviceName, location, active } = req.body;

        const user = await User.findOne({ userId });
        if (!user) return res.status(404).json({ error: "Không tìm thấy User" });
        const existingDevice = await Device.findOne({ deviceId });
        if (existingDevice) {
            return res.status(400).json({ error: "Thiết bị này đã được đăng ký!" });
        }
        const newDevice = new Device({ deviceId, userId, deviceName, location, active });
        await newDevice.save();

        user.devices.push(newDevice.deviceId);
        await user.save();

        res.status(201).json({ message: "Thiết bị được thêm thành công!", device: newDevice });
    } catch (error) {
        console.error("Lỗi khi thêm thiết bị:", error);
        res.status(500).json({ error: "Lỗi khi thêm thiết bị" });
    }
});


router.get("/:deviceId", authMiddleware, async (req, res) => {
    try {
        const deviceId = req.params.deviceId;  
        const device = await Device.findOne({ deviceId });

        if (!device) return res.status(404).json({ error: "Không tìm thấy thiết bị" });

        const user = await User.findOne({ userId: device.userId }).select("username email");

        res.json({ ...device.toObject(), user });
    } catch (error) {
        console.error("Lỗi khi lấy thiết bị:", error);
        res.status(500).json({ error: "Lỗi máy chủ khi lấy thiết bị" });
    }
});

router.put("/:deviceId", authMiddleware, async (req, res) => {
    try {
        const deviceId = req.params.deviceId;  
        const { deviceName, location, active } = req.body;

        const existingDevice = await Device.findOne({ deviceId });
        if (!existingDevice) return res.status(404).json({ error: "Không tìm thấy thiết bị" });

        if (deviceName !== undefined) existingDevice.deviceName = deviceName;
        if (location !== undefined) existingDevice.location = location;
        if (active !== undefined) existingDevice.active = Boolean(active);

        await existingDevice.save();
        res.json({ message: "Cập nhật thành công!", device: existingDevice });
    } catch (error) {
        console.error("Lỗi khi cập nhật thiết bị:", error);
        res.status(500).json({ error: "Lỗi khi cập nhật thiết bị" });
    }
});
router.delete("/:deviceId", authMiddleware, async (req, res) => {
    try {
        const userId = req.user.userId;
        const deviceId = req.params.deviceId;  
        const deletedDevice = await Device.findOneAndDelete({ deviceId, userId });
        if (!deletedDevice) return res.status(404).json({ error: "Không tìm thấy thiết bị của user này" });

        await User.updateOne({ userId }, { $pull: { devices: deviceId } });
        res.json({ message: "Thiết bị đã được xóa thành công!" });
    } catch (error) {
        console.error("Lỗi khi xóa thiết bị:", error);
        res.status(500).json({ error: "Lỗi khi xóa thiết bị" });
    }
});

module.exports = router;
