const express = require("express");
const router = express.Router();
const Device = require("../models/Device");
const User = require("../models/user");
const authMiddleware = require("../utils/authMiddleware");
const asyncHandler = require("../utils/asyncHandler");

router.use(authMiddleware);

router.get(
  "/devices/:userId",
  asyncHandler(async (req, res) => {
    const userId = Number(req.params.userId);
    if (userId !== req.user.userId) {
      return res
        .status(403)
        .json({ error: "Bạn không có quyền truy cập thiết bị của user khác!" });
    }
    const devices = await Device.find({ userId }).lean();
    res.json({ devices });
  }),
);

router.post(
  "/",
  asyncHandler(async (req, res) => {
    const userId = req.user.userId;
    const { deviceId, deviceName, location, active } = req.body;

    const existingDevice = await Device.findOne({ deviceId });
    if (existingDevice)
      return res.status(400).json({ error: "Thiết bị này đã được đăng ký!" });

    const newDevice = new Device({
      deviceId,
      userId,
      deviceName,
      location,
      active,
    });
    await newDevice.save();

    await User.updateOne(
      { userId },
      { $addToSet: { devices: newDevice.deviceId } },
    );
    res
      .status(201)
      .json({ message: "Thiết bị được thêm thành công!", device: newDevice });
  }),
);

router.get(
  "/:deviceId",
  asyncHandler(async (req, res) => {
    const device = await Device.findOne({
      deviceId: req.params.deviceId,
    }).lean();
    if (!device)
      return res.status(404).json({ error: "Không tìm thấy thiết bị" });

    const user = await User.findOne({ userId: device.userId })
      .select("username email")
      .lean();
    res.json({ ...device, user });
  }),
);

router.put(
  "/:deviceId",
  asyncHandler(async (req, res) => {
    const { deviceName, location, active } = req.body;
    const updateFields = {};

    if (deviceName !== undefined) updateFields.deviceName = deviceName;
    if (location !== undefined) updateFields.location = location;
    if (active !== undefined) updateFields.active = Boolean(active);

    const updatedDevice = await Device.findOneAndUpdate(
      { deviceId: req.params.deviceId },
      { $set: updateFields },
      { new: true },
    );

    if (!updatedDevice)
      return res.status(404).json({ error: "Không tìm thấy thiết bị" });
    res.json({ message: "Cập nhật thành công!", device: updatedDevice });
  }),
);

router.delete(
  "/:deviceId",
  asyncHandler(async (req, res) => {
    const userId = req.user.userId;
    const deviceId = req.params.deviceId;

    const deletedDevice = await Device.findOneAndDelete({ deviceId, userId });
    if (!deletedDevice)
      return res
        .status(404)
        .json({ error: "Không tìm thấy thiết bị của user này" });

    await User.updateOne({ userId }, { $pull: { devices: deviceId } });
    res.json({ message: "Thiết bị đã được xóa thành công!" });
  }),
);

module.exports = router;
