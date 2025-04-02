const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/user");
const { generateId } = require("../models/configs");
const authMiddleware = require("../middleware/authMiddleware");
const nodemailer = require("nodemailer");
require("dotenv").config();

const router = express.Router({ strict: false });

// Đăng ký người dùng
router.post("/register", async (req, res) => {
    try {
        let { username, email, password } = req.body;

        email = email.toLowerCase().trim();
        username = username.toLowerCase().trim();

        const existingUser = await User.findOne({ $or: [{ email }, { username }] });
        if (existingUser) {
            return res.status(400).json({
                error: existingUser.email === email ? "Email đã được sử dụng!" : "Username đã được sử dụng!"
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const userId = await generateId("User");

        if (!userId) return res.status(500).json({ error: "Không thể tạo userId!" });

        const newUser = new User({ userId, username, email, password: hashedPassword });
        await newUser.save();

        res.status(201).json({ message: "Đăng ký thành công!", user: newUser });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Lỗi khi đăng ký" });
    }
});

//  Đăng nhập
router.post("/login", async (req, res) => {
    try {
        let { username, email, password } = req.body;
        const query = email ? { email: email.toLowerCase().trim() } : { username: username.toLowerCase().trim() };
        const user = await User.findOne(query);

        if (!user) return res.status(401).json({ error: "Sai email hoặc mật khẩu!" });

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(401).json({ error: "Sai email hoặc mật khẩu!" });

        const token = jwt.sign({ userId: user.userId }, process.env.JWT_SECRET, { expiresIn: "7d" });

        res.json({ message: "Đăng nhập thành công!", token, user });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Lỗi khi đăng nhập" });
    }
});

// Cập nhật thông tin user
router.put("/update/:userId", authMiddleware, async (req, res) => {
    try {
        const { username, email } = req.body;
        const userId = Number(req.params.userId); // 🔹 Chuyển userId về kiểu số

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
        const userId = Number(req.params.userId); // 🔹 Chuyển userId về kiểu số nếu cần

        if (userId !== req.user.userId) {
            return res.status(403).json({ error: "Bạn không có quyền đổi mật khẩu!" });
        }

        const user = await User.findOne({ userId });
        if (!user) return res.status(404).json({ error: "Không tìm thấy người dùng!" });

        const isMatch = await bcrypt.compare(oldPassword, user.password);
        if (!isMatch) return res.status(400).json({ error: "Mật khẩu cũ không đúng!" });

        // 🔹 Kiểm tra độ dài mật khẩu mới
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


// 📌 Lấy thông tin người dùng kèm thiết bị (✅ Fix lỗi populate)
router.get("/users/:userId", authMiddleware, async (req, res) => {
    try {
        const { userId } = req.params;
        const user = await User.findOne({ userId }).populate("devices");

        if (!user) return res.status(404).json({ error: "Không tìm thấy người dùng!" });

        res.json(user);
    } catch (error) {
        console.error("Lỗi lấy thông tin người dùng:", error);
        res.status(500).json({ error: "Lỗi khi lấy thông tin người dùng" });
    }
});

// 📌 Lấy thông tin profile
router.get("/profile", authMiddleware, async (req, res) => {
    try {
        const userId = req.user.userId; // 🔹 Lấy userId từ token

        // Nếu userId là ObjectId, cần chuyển đổi trước khi truy vấn
        const user = await User.findById(userId).select("-password");

        if (!user) return res.status(404).json({ error: "Không tìm thấy người dùng!" });

        res.json(user);
    } catch (error) {
        console.error("Lỗi lấy thông tin user:", error);
        res.status(500).json({ error: "Lỗi khi lấy thông tin người dùng" });
    }
});

// 🔹 Cấu hình dịch vụ gửi email
const transporter = nodemailer.createTransport({
    service: "gmail",  // Gmail service
    auth: {
        user: process.env.SMTP_USER,  // Lấy user từ .env
        pass: process.env.SMTP_PASS,  // Lấy pass từ .env
    },
});

// 📌 API Quên Mật Khẩu
router.post("/forgot-password", async (req, res) => {
    try {
        const { email } = req.body;
        const user = await User.findOne({ email: email.toLowerCase().trim() });

        if (!user) return res.status(404).json({ error: "Email chưa được đăng ký!" });

        // 🔹 Tạo mật khẩu mới ngẫu nhiên
        const newPassword = Math.random().toString(36).slice(-8); // Mật khẩu mới ngẫu nhiên
        const hashedPassword = await bcrypt.hash(newPassword, 10);  // Mã hóa mật khẩu mới

        // 🔹 Cập nhật mật khẩu mới vào database
        user.password = hashedPassword;
        await user.save();

        // 🔹 Cấu hình email gửi đi
        const mailOptions = {
            from: `"${process.env.SMTP_SENDER_NAME}" <${process.env.SMTP_SENDER_EMAIL}>`, // Hiển thị tên người gửi mà không hiển thị email cá nhân
            to: user.email, // Email người nhận
            subject: "Khôi phục mật khẩu", // Tiêu đề email
            html: `
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Khôi phục mật khẩu</title>
                <style>
                    body {
                        font-family: Arial, sans-serif;
                        background-color: #f4f4f4;
                        margin: 0;
                        padding: 0;
                    }
                    .container {
                        width: 100%;
                        max-width: 600px;
                        margin: 20px auto;
                        background-color: #ffffff;
                        padding: 20px;
                        border-radius: 8px;
                        box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
                        text-align: center;
                    }
                    h2 {
                        color: #333;
                    }
                    p {
                        font-size: 16px;
                        color: #555;
                        line-height: 1.6;
                    }
                    .password {
                        font-size: 18px;
                        font-weight: bold;
                        color: #d9534f;
                        background: #f8d7da;
                        padding: 10px;
                        border-radius: 5px;
                        display: inline-block;
                        margin: 10px 0;
                    }
                    .footer {
                        margin-top: 20px;
                        font-size: 14px;
                        color: #777;
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <h2>Khôi phục mật khẩu thành công!</h2>
                    <p>Xin chào,</p>
                    <p>Bạn đã yêu cầu đặt lại mật khẩu của mình. Dưới đây là mật khẩu mới của bạn:</p>
                    <div class="password">${newPassword}</div>
                    <p>Vui lòng đăng nhập và đổi mật khẩu ngay để đảm bảo an toàn cho tài khoản của bạn.</p>
                </div>
            </body>
            </html>`
        };

        await transporter.sendMail(mailOptions);

        res.json({ message: "Mật khẩu mới đã được gửi đến email của bạn!" });
    } catch (error) {
        console.error("Lỗi quên mật khẩu:", error);
        res.status(500).json({ error: "Lỗi khi xử lý yêu cầu quên mật khẩu" });
    }
});
// 📌 Đăng xuất
router.post("/logout", (req, res) => {
    res.clearCookie("token", { httpOnly: true, secure: true, sameSite: "None" });
    res.json({ message: "Đăng xuất thành công!" });
});

module.exports = router;
