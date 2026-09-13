const express = require("express");
const router = express.Router();
const User = require("../models/user");
const authMiddleware = require("../utils/authMiddleware");
const asyncHandler = require("../utils/asyncHandler");

router.use(authMiddleware);

router.post(
  "/",
  asyncHandler(async (req, res) => {
    const userId = req.user.userId;
    const { fcmToken } = req.body;
    if (!fcmToken) return res.status(400).json({ message: "Thiếu FCM token" });

    const user = await User.findOneAndUpdate(
      { userId },
      { $addToSet: { fcmToken: fcmToken } },
      { new: true },
    );

    if (!user)
      return res.status(404).json({ message: "Không tìm thấy người dùng" });
    res.json({ message: "Xử lý FCM token thành công!" });
  }),
);

router.get(
  "/",
  asyncHandler(async (req, res) => {
    const user = await User.findOne({ userId: req.user.userId })
      .select("fcmToken")
      .lean();
    if (!user)
      return res.status(404).json({ message: "Không tìm thấy người dùng" });

    res.json({ fcmToken: user.fcmToken || [] });
  }),
);

module.exports = router;
