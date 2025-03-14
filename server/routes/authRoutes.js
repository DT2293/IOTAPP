const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/user");
const authMiddleware = require("../middleware/authMiddleware");

//const router = express.Router();
const router = express.Router({ strict: false }); 
//  Đăng ký 

router.post("/register", async (req, res) => {
    try {
        let { username, email, password } = req.body;

        // Chuyển email về chữ thường
        email = email.toLowerCase().trim();

        // Kiểm tra nếu email đã tồn tại
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ error: "Email đã được sử dụng!" });
        }

        // Mã hóa mật khẩu
        const hashedPassword = await bcrypt.hash(password, 10);

        // Tạo user mới
        const newUser = new User({ username, email, password: hashedPassword });
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
        let { email, password } = req.body;
        email = email.toLowerCase().trim();

        // Kiểm tra người dùng có tồn tại không
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(401).json({ error: "Sai email hoặc mật khẩu!" });
        }

        // Kiểm tra mật khẩu
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ error: "Sai email hoặc mật khẩu!" });
        }

        // Tạo token JWT
        const token = jwt.sign({ userId: user._id }, "SECRET_KEY", { expiresIn: "7d" });

        res.json({ message: "Đăng nhập thành công!", token, user });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Lỗi khi đăng nhập" });
    }
});

// Cập nhật thông tin người dùng
router.put("/update/:userId", authMiddleware, async (req, res) => {
    try {
        const { username, email, password } = req.body;

        // Kiểm tra nếu userId không khớp với token (Chỉ cho phép cập nhật chính mình)
        if (req.params.userID !== req.user.userId) {
            return res.status(403).json({ error: "Bạn không có quyền cập nhật thông tin này!" });
        }

        // Kiểm tra người dùng có tồn tại không
        const user = await User.findById(req.params.userId);
        if (!user) {
            return res.status(404).json({ error: "Không tìm thấy người dùng!" });
        }

        // Cập nhật thông tin
        if (username) user.username = username;
        if (email) user.email = email.toLowerCase().trim();
        // if (password) {
        //     user.password = await bcrypt.hash(password, 10);
        // }

        await user.save();
        res.json({ message: "Cập nhật thành công!", user });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Lỗi khi cập nhật thông tin" });
    }
});

//đổi mật khẩu 
router.put("/updatepassword/:userId", authMiddleware, async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;

        // Kiểm tra xem user có tồn tại không
        const user = await User.findById(req.params.userId);
        if (!user) {
            return res.status(404).json({ error: "Không tìm thấy người dùng!" });
        }

        // Kiểm tra mật khẩu cũ có đúng không
        const isMatch = await bcrypt.compare(oldPassword, user.password);
        if (!isMatch) {
            return res.status(400).json({ error: "Mật khẩu cũ không đúng!" });
        }

        // Nếu đúng, mã hóa và cập nhật mật khẩu mới
        user.password = await bcrypt.hash(newPassword, 10);
        await user.save();

        res.json({ message: "Đổi mật khẩu thành công!" });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Lỗi khi đổi mật khẩu" });
    }
});

router.get("/users/:userId", authMiddleware, async (req, res) => {
    try {
        const user = await User.findById(req.params.userId).populate("devices"); // Populate danh sách thiết bị
        if (!user) return res.status(404).json({ error: "Không tìm thấy user" });

        res.json(user);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Lỗi khi lấy thông tin user" });
    }
});



//  Lấy thông tin người dùng (cần đăng nhập)
router.get("/profile", authMiddleware, async (req, res) => {
    try {
        const user = await User.findById(req.user.userId).select("-password"); // Không trả về mật khẩu
        if (!user) {
            return res.status(404).json({ error: "Không tìm thấy người dùng!" });
        }
        res.json(user);
    } catch (error) {
        res.status(500).json({ error: "Lỗi khi lấy thông tin người dùng" });
    }
});


//dang xuất
router.post("/logout", (req, res) => {
    res.clearCookie("token", {
        httpOnly: true,
        secure: true,
        sameSite: "None"
    });

    res.json({ message: "Đăng xuất thành công!" });
});

module.exports = router;
