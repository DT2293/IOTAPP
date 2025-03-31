const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/user");
const { generateId } = require("../models/configs");
const authMiddleware = require("../middleware/authMiddleware");
require("dotenv").config();

const router = express.Router({ strict: false });

// 📌 Đăng ký người dùng
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

// 📌 Đăng nhập
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

// 📌 Cập nhật thông tin user
router.put("/update/:userId", authMiddleware, async (req, res) => {
    try {
        const { username, email } = req.body;
        const { userId } = req.params;

        if (parseInt(userId) !== req.user.userId) {
            return res.status(403).json({ error: "Bạn không có quyền cập nhật thông tin này!" });
        }

        const user = await User.findOne({ userId });
        if (!user) return res.status(404).json({ error: "Không tìm thấy người dùng!" });

        if (username) user.username = username;
        if (email) user.email = email.toLowerCase().trim();

        await user.save();
        res.json({ message: "Cập nhật thành công!", user });
    } catch (error) {
        console.error("Lỗi cập nhật:", error);
        res.status(500).json({ error: "Lỗi khi cập nhật thông tin" });
    }
});

// 📌 Đổi mật khẩu
router.put("/updatepassword/:userId", authMiddleware, async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;
        const { userId } = req.params;

        const user = await User.findOne({ userId });
        if (!user) return res.status(404).json({ error: "Không tìm thấy người dùng!" });

        const isMatch = await bcrypt.compare(oldPassword, user.password);
        if (!isMatch) return res.status(400).json({ error: "Mật khẩu cũ không đúng!" });

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
        const user = await User.findOne({ userId: req.user.userId }).select("-password");
        if (!user) return res.status(404).json({ error: "Không tìm thấy người dùng!" });

        res.json(user);
    } catch (error) {
        res.status(500).json({ error: "Lỗi khi lấy thông tin người dùng" });
    }
});

// 📌 Đăng xuất
router.post("/logout", (req, res) => {
    res.clearCookie("token", { httpOnly: true, secure: true, sameSite: "None" });
    res.json({ message: "Đăng xuất thành công!" });
});

module.exports = router;
