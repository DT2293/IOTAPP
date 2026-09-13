const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const nodemailer = require("nodemailer");
const User = require("../models/user");
const authMiddleware = require("../utils/authMiddleware");
const asyncHandler = require("../utils/asyncHandler");
require("dotenv").config();

const router = express.Router({ strict: false });

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
});
const otpStore = new Map();

// Helper kiểm tra quyền truy cập
const checkOwnership = (req, res, userIdParam) => {
  if (Number(userIdParam) !== req.user.userId) {
    res
      .status(403)
      .json({ error: "Bạn không có quyền thực hiện hành động này!" });
    return false;
  }
  return true;
};

router.post(
  "/register",
  asyncHandler(async (req, res) => {
    let { username, email, phonenumber, password } = req.body;
    email = email.toLowerCase().trim();
    username = username.toLowerCase().trim();
    phonenumber = phonenumber.trim();

    const existingUser = await User.findOne({
      $or: [{ email }, { username }, { phonenumber }],
    });

    if (existingUser) {
      const errorMsg =
        existingUser.email === email
          ? "Email đã được sử dụng!"
          : existingUser.username === username
            ? "Username đã được sử dụng!"
            : "Số điện thoại đã được sử dụng!";
      return res.status(400).json({ error: errorMsg });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new User({
      username,
      phonenumber,
      email,
      password: hashedPassword,
    });
    await newUser.save();

    res.status(201).json({ message: "Đăng ký thành công!", user: newUser });
  }),
);

router.post(
  "/login",
  asyncHandler(async (req, res) => {
    let { username, email, password } = req.body;
    const query = email
      ? { email: email.toLowerCase().trim() }
      : { username: username.toLowerCase().trim() };

    const user = await User.findOne(query);
    if (!user)
      return res.status(401).json({ error: "Sai tài khoản đăng nhập" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ error: "Sai mật khẩu!" });

    const token = jwt.sign({ userId: user.userId }, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });
    res.json({ message: "Đăng nhập thành công!", token, user });
  }),
);

router.post("/logout", (req, res) => {
  res.clearCookie("token", { httpOnly: true, secure: true, sameSite: "None" });
  res.json({ message: "Đăng xuất thành công!" });
});

router.get(
  "/devices/:userId",
  authMiddleware,
  asyncHandler(async (req, res) => {
    if (!checkOwnership(req, res, req.params.userId)) return;
    const user = await User.findOne({ userId: req.params.userId })
      .populate("devices")
      .lean();
    if (!user)
      return res.status(404).json({ error: "Không tìm thấy người dùng!" });
    res.json({ devices: user.devices });
  }),
);

router.get(
  "/profile",
  authMiddleware,
  asyncHandler(async (req, res) => {
    const user = await User.findOne({ userId: req.user.userId })
      .select("-password")
      .lean();
    if (!user)
      return res.status(404).json({ error: "Không tìm thấy người dùng!" });
    res.json(user);
  }),
);

router.get(
  "/users/:userId",
  authMiddleware,
  asyncHandler(async (req, res) => {
    const user = await User.findOne({ userId: req.params.userId })
      .populate("devices")
      .lean();
    if (!user)
      return res.status(404).json({ error: "Không tìm thấy người dùng!" });
    res.json({
      username: user.username,
      email: user.email,
      phonenumber: user.phonenumber,
      devices: user.devices,
    });
  }),
);

router.put(
  "/update/:userId",
  authMiddleware,
  asyncHandler(async (req, res) => {
    if (!checkOwnership(req, res, req.params.userId)) return;
    const { username, email, phonenumber } = req.body;

    const user = await User.findOne({ userId: req.params.userId });
    if (!user)
      return res.status(404).json({ error: "Không tìm thấy người dùng!" });

    if (username) user.username = username;
    if (email) {
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
        return res.status(400).json({ error: "Email không hợp lệ!" });
      user.email = email.toLowerCase().trim();
    }
    if (phonenumber) user.phonenumber = phonenumber.trim();

    await user.save();
    res.json({ message: "Cập nhật thành công!", user });
  }),
);

router.put(
  "/updatepassword/:userId",
  authMiddleware,
  asyncHandler(async (req, res) => {
    if (!checkOwnership(req, res, req.params.userId)) return;
    const { oldPassword, newPassword } = req.body;

    const user = await User.findOne({ userId: req.params.userId });
    if (!user)
      return res.status(404).json({ error: "Không tìm thấy người dùng!" });

    if (!(await bcrypt.compare(oldPassword, user.password))) {
      return res.status(400).json({ error: "Mật khẩu cũ không đúng!" });
    }
    if (newPassword.length < 6)
      return res
        .status(400)
        .json({ error: "Mật khẩu mới phải có ít nhất 6 ký tự!" });

    user.password = await bcrypt.hash(newPassword, 10);
    await user.save();
    res.json({ message: "Đổi mật khẩu thành công!" });
  }),
);

router.patch(
  "/add-phone/:userId",
  authMiddleware,
  asyncHandler(async (req, res) => {
    const { newPhone } = req.body;
    if (!newPhone || typeof newPhone !== "string" || newPhone.trim() === "") {
      return res.status(400).json({ message: "Số điện thoại là bắt buộc" });
    }

    const user = await User.findOneAndUpdate(
      { userId: req.params.userId },
      { $addToSet: { phonenumber: newPhone } },
      { new: true },
    );

    if (!user) return res.status(404).json({ message: "Không tìm thấy user" });
    res.json({
      message: "Thêm số điện thoại thành công",
      phonenumber: user.phonenumber,
    });
  }),
);

router.post(
  "/update-language",
  authMiddleware,
  asyncHandler(async (req, res) => {
    const { language } = req.body;
    if (!["vi", "en"].includes(language))
      return res.status(400).json({ error: "Ngôn ngữ không hợp lệ" });

    const updatedUser = await User.findOneAndUpdate(
      { userId: req.user.userId },
      { language },
      { new: true },
    );
    if (!updatedUser)
      return res.status(404).json({ error: "Không tìm thấy người dùng" });
    res.json({ success: true, language: updatedUser.language });
  }),
);

router.post(
  "/forgot-password",
  asyncHandler(async (req, res) => {
    const email = req.body.email.toLowerCase().trim();
    const user = await User.findOne({ email });
    if (!user)
      return res.status(404).json({ error: "Email chưa được đăng ký!" });

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    otpStore.set(email, { otp, expiresAt: Date.now() + 60 * 1000 });

    await transporter.sendMail({
      from: `"${process.env.SMTP_SENDER_NAME}" <${process.env.SMTP_SENDER_EMAIL}>`,
      to: user.email,
      subject: "Mã OTP đăng nhập",
      html: `<div style="text-align: center"><h2>Mã OTP:</h2><h1>${otp}</h1><p>Hiệu lực 1 phút.</p></div>`,
    });

    res.json({ message: "Mã OTP đã được gửi đến email của bạn!" });
  }),
);

router.post(
  "/verify-otp",
  asyncHandler(async (req, res) => {
    const { email, otp } = req.body;
    const stored = otpStore.get(email);

    if (!stored || stored.otp !== otp || Date.now() > stored.expiresAt) {
      return res
        .status(400)
        .json({ error: "OTP không hợp lệ hoặc đã hết hạn!" });
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user)
      return res.status(404).json({ error: "Người dùng không tồn tại!" });

    otpStore.delete(email);
    const token = jwt.sign({ userId: user.userId }, process.env.JWT_SECRET, {
      expiresIn: "1h",
    });
    res.json({ message: "Xác thực thành công!", token, user });
  }),
);

router.post(
  "/reset-password",
  asyncHandler(async (req, res) => {
    const { email, newPassword } = req.body;
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    const user = await User.findOneAndUpdate(
      { email },
      { password: hashedPassword },
    );
    if (!user) return res.status(404).json({ message: "Email không tồn tại" });
    res.json({ message: "Đặt lại mật khẩu thành công" });
  }),
);

module.exports = router;
