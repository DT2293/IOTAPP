const express = require("express");
const router = express.Router();
const User = require("../models/user"); // ✅ Import User model
const Device = require("../models/Device"); // Đảm bảo có Device model

router.get("/users/:userId", async (req, res) => {
    try {
        const user = await User.findById(req.params.userId).populate("devices");
        if (!user) return res.status(404).json({ error: "Không tìm thấy user" });

        res.json(user);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Lỗi khi lấy thông tin user" });
    }
});

module.exports = router;
