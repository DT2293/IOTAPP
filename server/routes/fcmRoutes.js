// const express = require("express");
// const jwt = require("jsonwebtoken");
// const router = express.Router();
// const User = require("../models/user");
// const authMiddleware = require("../middleware/authMiddleware");

// router.post("/", authMiddleware, async (req, res) => {
//   try {
//     const authHeader = req.headers.authorization;

//     if (!authHeader || !authHeader.startsWith("Bearer ")) {
//       return res.status(401).json({ message: "Không có token" });
//     }

//     const token = authHeader.split(" ")[1];
//     const decoded = jwt.verify(token, process.env.JWT_SECRET);
//     const userId = decoded.userId;

//     const newToken = req.body.fcmToken;
//     if (!newToken) {
//       return res.status(400).json({ message: "Thiếu FCM token" });
//     }

//     const user = await User.findOne({ userId });
//     if (!user) {
//       return res.status(404).json({ message: "Không tìm thấy người dùng" });
//     }

//     // Thêm FCM token nếu chưa có
//     if (!user.fcmToken.includes(newToken)) {
//       user.fcmToken.push(newToken);
//       await user.save();
//     }

//     res.json({ message: "✅ Cập nhật FCM token thành công!" });
//   } catch (err) {
//     console.error("❌ Lỗi cập nhật FCM token:", err.message);
//     res.status(500).json({ message: "Lỗi server" });
//   }
// });

// module.exports = router;


const express = require("express");
const jwt = require("jsonwebtoken");
const router = express.Router();
const User = require("../models/user");
const authMiddleware = require("../utils/authMiddleware");

// ✅ Thêm FCM token vào mảng (nếu chưa có)
router.post("/", authMiddleware, async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      return res.status(401).json({ message: "Không có token" });
    }

    const token = authHeader.split(" ")[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.userId;

    const newToken = req.body.fcmToken;
    if (!newToken) return res.status(400).json({ message: "Thiếu FCM token" });

    const user = await User.findOne({ userId });
    if (!user) return res.status(404).json({ message: "Không tìm thấy người dùng" });

    if (!user.fcmToken.includes(newToken)) {
      user.fcmToken.push(newToken);
      await user.save();
      return res.json({ message: "✅ Thêm FCM token thành công!" });
    }

    res.json({ message: "ℹ️ Token đã tồn tại, không cần thêm." });
  } catch (err) {
    console.error("❌ Lỗi cập nhật FCM token:", err.message);
    res.status(500).json({ message: "Lỗi server" });
  }
});

// ✅ Lấy danh sách FCM token
router.get("/", authMiddleware, async (req, res) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findOne({ userId: decoded.userId });

    if (!user) return res.status(404).json({ message: "Không tìm thấy người dùng" });

    res.json({ fcmToken: user.fcmToken || [] });
  } catch (err) {
    console.error("❌ Lỗi lấy danh sách FCM token:", err.message);
    res.status(500).json({ message: "Lỗi server" });
  }
});

module.exports = router;
