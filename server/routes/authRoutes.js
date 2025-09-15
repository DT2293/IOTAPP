const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/user");
const { generateId } = require("../models/configs");
const authMiddleware = require("../utils/authMiddleware");
const nodemailer = require("nodemailer");
require("dotenv").config();

const router = express.Router({ strict: false });


router.post("/register", async (req, res) => {
    try {
        let { username, email, phonenumber, password } = req.body;

        email = email.toLowerCase().trim();
        username = username.toLowerCase().trim();
        phonenumber = phonenumber.trim();  

        const existingUser = await User.findOne({ $or: [{ email }, { username }, { phonenumber }] }); 
        if (existingUser) {
            return res.status(400).json({
                error: existingUser.email === email ? "Email đã được sử dụng!" : 
                       existingUser.username === username ? "Username đã được sử dụng!" : 
                       "Số điện thoại đã được sử dụng!"
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const userId = await generateId("User");

        if (!userId) return res.status(500).json({ error: "Không thể tạo userId!" });

        const newUser = new User({ userId, username, phonenumber, email, password: hashedPassword });
        await newUser.save();

        res.status(201).json({ message: "Đăng ký thành công!", user: newUser });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Lỗi khi đăng ký" });
    }
});
router.get("/devices/:userId", authMiddleware, async (req, res) => {
  try {
    const userId = Number(req.params.userId);

    if (userId !== req.user.userId) {
      return res.status(403).json({ error: "Bạn không có quyền truy cập thiết bị của user khác!" });
    }


    const user = await User.findOne({ userId }).populate('devices').exec();

    if (!user) {
      return res.status(404).json({ error: "Không tìm thấy người dùng!" });
    }

    return res.json({ devices: user.devices });
  } catch (error) {
    console.error("Lỗi khi lấy danh sách thiết bị:", error);
    return res.status(500).json({ error: "Lỗi server" });
  }
});


router.post("/login", async (req, res) => {
    try {
        let { username, email, password } = req.body;
        const query = email ? { email: email.toLowerCase().trim() } : { username: username.toLowerCase().trim() };
        const user = await User.findOne(query);

        if (!user) return res.status(401).json({ error: "Sai tài khoản đăng nhập" });

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(401).json({ error: "Sai mật khẩu!" });

        const token = jwt.sign({ userId: user.userId }, process.env.JWT_SECRET, { expiresIn: "7d" });

        res.json({ message: "Đăng nhập thành công!", token, user });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Lỗi khi đăng nhập" });
    }
});
// Cập nhật thông tin người dùng
router.put("/update/:userId", authMiddleware, async (req, res) => {
    try {
        const { username, email, phonenumber } = req.body;
        const userId = Number(req.params.userId);

        if (userId !== req.user.userId) {
            return res.status(403).json({ error: "Bạn không có quyền cập nhật thông tin này!" });
        }

        const user = await User.findOne({ userId });
        if (!user) return res.status(404).json({ error: "Không tìm thấy người dùng!" });

        if (username) user.username = username;
        if (email) {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(email)) {
                return res.status(400).json({ error: "Email không hợp lệ!" });
            }
            user.email = email.toLowerCase().trim();
        }
        if (phonenumber) user.phonenumber = phonenumber.trim(); 
        await user.save();
        res.json({ message: "Cập nhật thành công!", user });
    } catch (error) {
        console.error("Lỗi cập nhật:", error);
        res.status(500).json({ error: "Lỗi khi cập nhật thông tin" });
    }
});


//Đổi mật khẩu
router.put("/updatepassword/:userId", authMiddleware, async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;
        const userId = Number(req.params.userId); 

        if (userId !== req.user.userId) {
            return res.status(403).json({ error: "Bạn không có quyền đổi mật khẩu!" });
        }

        const user = await User.findOne({ userId });
        if (!user) return res.status(404).json({ error: "Không tìm thấy người dùng!" });

        const isMatch = await bcrypt.compare(oldPassword, user.password);
        if (!isMatch) return res.status(400).json({ error: "Mật khẩu cũ không đúng!" });

      
        if (newPassword.length < 6) {
            return res.status(400).json({ error: "Mật khẩu mới phải có ít nhất 6 ký tự!" });
        }

        user.password = await bcrypt.hash(newPassword, 10);
        await user.save();

        res.json({ message: "Đổi mật khẩu thành công!" });
    } catch (error) {
        console.error("Lỗi đổi mật khẩu:", error);
        res.status(500).json({ error: "Lỗi khi đổi mật khẩu" });
    }
});

router.get("/users/:userId", authMiddleware, async (req, res) => {
    try {
        const { userId } = req.params;
        const user = await User.findOne({ userId }).populate("devices");

        if (!user) return res.status(404).json({ error: "Không tìm thấy người dùng!" });

        res.json({
            username: user.username,
            email: user.email,
            phonenumber: user.phonenumber, // 🔹 Thêm phonenumber
            devices: user.devices
        });
    } catch (error) {
        console.error("Lỗi lấy thông tin người dùng:", error);
        res.status(500).json({ error: "Lỗi khi lấy thông tin người dùng" });
    }
});

router.get("/profile", authMiddleware, async (req, res) => {
    try {
        let userId = req.user.userId;

        if (isNaN(userId)) {
            return res.status(400).json({ error: "userId không hợp lệ!" });
        }

        const user = await User.findOne({ userId }).select("-password");

        if (!user) return res.status(404).json({ error: "Không tìm thấy người dùng!" });

        res.json({
            username: user.username,
            email: user.email,
            phonenumber: user.phonenumber, // 🔹 Thêm phonenumber
            devices: user.devices
        });
    } catch (error) {
        console.error("Lỗi lấy thông tin user:", error);
        res.status(500).json({ error: "Lỗi khi lấy thông tin người dùng" });
    }
});
router.patch("/add-phone/:userId", authMiddleware, async (req, res) => {
  const { userId } = req.params;
  const { newPhone } = req.body;

  // Kiểm tra dữ liệu đầu vào
  if (!newPhone || typeof newPhone !== 'string' || newPhone.trim() === '') {
    return res.status(400).json({ message: "Phone number is required" });
  }

  try {
    const user = await User.findOne({ userId });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!Array.isArray(user.phonenumber)) {
      user.phonenumber = [];
    }

    user.phonenumber.push(newPhone);
    await user.save();

    res.json({
      message: "Phone number added",
      phonenumber: user.phonenumber
    });

  } catch (err) {
    console.error("🚨 Error updating phone number:", err);
    res.status(500).json({ message: "Error updating phone number", error: err.message });
  }
});

const transporter = nodemailer.createTransport({
    service: "gmail",  
    auth: {
        user: process.env.SMTP_USER,  
        pass: process.env.SMTP_PASS,  
    },
});
const otpStore = new Map(); 

router.post("/forgot-password", async (req, res) => {
    try {
        const { email } = req.body;
        const user = await User.findOne({ email: email.toLowerCase().trim() });

        if (!user) return res.status(404).json({ error: "Email chưa được đăng ký!" });

        // 🔹 Tạo mã OTP 6 chữ số
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = Date.now() + 60 * 1000; // OTP có hiệu lực 1 phút

        otpStore.set(email, { otp, expiresAt });

        // 🔹 Cấu hình email gửi đi
        const mailOptions = {
            from: `"${process.env.SMTP_SENDER_NAME}" <${process.env.SMTP_SENDER_EMAIL}>`,
            to: user.email,
            subject: "Mã OTP đăng nhập",
            html: `
            <div style="font-family: Arial, sans-serif; padding: 20px; text-align: center">
                <h2>Xác thực đăng nhập</h2>
                <p>Mã OTP của bạn là:</p>
                <div style="font-size: 24px; font-weight: bold; color: #2c3e50">${otp}</div>
                <p>Mã có hiệu lực trong vòng 1 phút.</p>
            </div>
            `
        };

        await transporter.sendMail(mailOptions);

        res.json({ message: "Mã OTP đã được gửi đến email của bạn!" });
    } catch (error) {
        console.error("Lỗi gửi OTP:", error);
        res.status(500).json({ error: "Không thể gửi OTP" });
    }
});

router.post("/verify-otp", async (req, res) => {
    try {
        const { email, otp } = req.body;
        const stored = otpStore.get(email);

        if (!stored || stored.otp !== otp || Date.now() > stored.expiresAt) {
            return res.status(400).json({ error: "OTP không hợp lệ hoặc đã hết hạn!" });
        }

        const user = await User.findOne({ email: email.toLowerCase().trim() });
        if (!user) return res.status(404).json({ error: "Người dùng không tồn tại!" });

        otpStore.delete(email); 

        const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, { expiresIn: "1h" });
        res.json({ message: "Xác thực thành công!", token, user });
    } catch (error) {
        console.error("Lỗi xác thực OTP:", error);
        res.status(500).json({ error: "Lỗi khi xác thực OTP" });
    }
});

router.post('/reset-password', async (req, res) => {
    const { email, newPassword } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'Email không tồn tại' });

    user.password = await bcrypt.hash(newPassword, 10);
    await user.save();

    res.json({ message: 'Đặt lại mật khẩu thành công' });
});
router.post("/logout", (req, res) => {
    res.clearCookie("token", { httpOnly: true, secure: true, sameSite: "None" });
    res.json({ message: "Đăng xuất thành công!" });
});
router.post('/update-language', authMiddleware, async (req, res) => {
  const userId = req.user.userId; // là số
  const { language } = req.body;

  if (!['vi', 'en'].includes(language)) {
    return res.status(400).json({ error: 'Ngôn ngữ không hợp lệ' });
  }

  try {
    const updatedUser = await User.findOneAndUpdate(
      { userId }, 
      { language },
      { new: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ error: 'Không tìm thấy người dùng' });
    }

    res.json({ success: true, language: updatedUser.language });
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Lỗi server khi cập nhật ngôn ngữ' });
  }
});


router.patch("/add-phone/:userId", authMiddleware, async (req, res) => {
  try {

    const { userId } = req.params;

    const { newPhone } = req.body;

    if (!newPhone || newPhone.trim() === "") {
      return res.status(400).send({ message: "Phone number is required" });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).send({ message: "User not found" });
    }

    user.phonenumber.push(newPhone);

    await user.save();

    res.send({
      message: "Phone number added",
      phonenumber: user.phonenumber,
    });
  } catch (err) {
    console.error(err);
    res.status(500).send({ message: "Error updating phone number" });
  }
});

module.exports = router;
