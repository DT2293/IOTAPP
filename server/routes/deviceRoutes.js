// const express = require("express");
// const router = express.Router();
// const Device = require("../models/Device");
// const User = require("../models/user"); // Import User model
// const authMiddleware = require("../middleware/authMiddleware");

// // 🔹 Thêm thiết bị mới
// router.post("/", authMiddleware, async (req, res) => {
//     try {
//         const userId = req.user.userId;
//         const { deviceId, deviceName, location, active } = req.body;

//         // Kiểm tra user có tồn tại không
//         const user = await User.findOne({ userId });
//         if (!user) return res.status(404).json({ error: "Không tìm thấy User" });

//         // Kiểm tra nếu deviceId bị thiếu
//         if (!deviceId) return res.status(400).json({ error: "deviceId là bắt buộc" });

//         // Tạo mới thiết bị
//         const newDevice = new Device({
//             deviceId,   // Truyền deviceId từ request body
//             userId,
//             deviceName,
//             location,
//             active
//         });

//         await newDevice.save();

//         user.devices.push(newDevice.deviceId);
//         await user.save();

//         res.status(201).json({ message: "Thiết bị được thêm thành công!", device: newDevice });
//     } catch (error) {
//         console.error("Lỗi khi thêm thiết bị:", error);
//         res.status(500).json({ error: "Lỗi khi thêm thiết bị" });
//     }
// });


// // 🔹 Lấy thông tin thiết bị theo deviceId là string
// router.get("/:deviceId", authMiddleware, async (req, res) => {
//     try {
//         const { deviceId } = req.params;

//         // Tìm theo trường deviceId, không phải mặc định _id của MongoDB
//         const device = await Device.findOne({ deviceId }).populate("userId", "username email");

//         if (!device) return res.status(404).json({ error: "Không tìm thấy thiết bị" });

//         res.json(device);
//     } catch (error) {
//         console.error("Lỗi khi lấy thiết bị:", error);
//         res.status(500).json({ error: "Lỗi máy chủ khi lấy thiết bị" });
//     }
// });


// // 🔹 Cập nhật thiết bị theo deviceId (UUID)
// router.put("/:deviceId", authMiddleware, async (req, res) => {
//     try {
//         const { deviceName, location, active } = req.body;

//        // Sửa truy vấn tìm kiếm đúng theo deviceId
// const existingDevice = await Device.findOne({ deviceId: req.params.deviceId });


//         if (!existingDevice) return res.status(404).json({ error: "Không tìm thấy thiết bị" });

//         if (deviceName !== undefined) existingDevice.deviceName = deviceName;
//         if (location !== undefined) existingDevice.location = location;
//         if (active !== undefined) existingDevice.active = Boolean(active);

//         await existingDevice.save();
//         res.json({ message: "Cập nhật thành công!", device: existingDevice });
//     } catch (error) {
//         console.error("Lỗi khi cập nhật thiết bị:", error);
//         res.status(500).json({ error: "Lỗi khi cập nhật thiết bị" });
//     }
// });

// // 🔹 Xóa thiết bị theo deviceId (UUID) và userId (UUID)
// router.delete("/:deviceId", authMiddleware, async (req, res) => {
//     try {
//         const userId = req.user.userId;
//         const { deviceId } = req.params;

//         // Xóa thiết bị dựa trên userId và deviceId (UUID)
//         const deletedDevice = await Device.findOneAndDelete({ deviceId, userId });


//         if (!deletedDevice) return res.status(404).json({ error: "Không tìm thấy thiết bị của user này" });

//         // Xóa deviceId trong danh sách devices của User
//         await User.updateOne({ userId }, { $pull: { devices: deviceId } });

//         res.json({ message: "Thiết bị đã được xóa thành công!" });
//     } catch (error) {
//         console.error("Lỗi khi xóa thiết bị:", error);
//         res.status(500).json({ error: "Lỗi khi xóa thiết bị" });
//     }
// });

// // 🔹 Lấy danh sách tất cả thiết bị của người dùng hiện tại
// router.get("/", authMiddleware, async (req, res) => {
//     try {
//         const userId = req.user.userId;
//         const devices = await Device.find({ userId });
//         res.json({ devices });
//     } catch (error) {
//         console.error("Lỗi khi lấy danh sách thiết bị:", error);
//         res.status(500).json({ error: "Lỗi khi lấy danh sách thiết bị" });
//     }
// });

// module.exports = router;



const express = require("express");
const router = express.Router();
const Device = require("../models/Device");
const User = require("../models/user");
const { generateId } = require("../models/configs"); // ✅ Thêm hàm generateId
const authMiddleware = require("../middleware/authMiddleware");

// 🔹 Thêm thiết bị mới
//const { generateId } = require("../models/configs"); 

// Trong route thêm thiết bị mới
router.post("/", authMiddleware, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { deviceName, location, active } = req.body;

        const user = await User.findOne({ userId });
        if (!user) return res.status(404).json({ error: "Không tìm thấy User" });

        // 🔥 Sử dụng counter riêng cho Device
        const deviceId = await generateId("Device");

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


// 🔹 Lấy thông tin thiết bị theo deviceId
router.get("/:deviceId", authMiddleware, async (req, res) => {
    try {
        const deviceId = Number(req.params.deviceId);
        const device = await Device.findOne({ deviceId });

        if (!device) return res.status(404).json({ error: "Không tìm thấy thiết bị" });

        // Tìm user theo userId (vì userId trong Device là Number)
        const user = await User.findOne({ userId: device.userId }).select("username email");

        res.json({ ...device.toObject(), user });
    } catch (error) {
        console.error("Lỗi khi lấy thiết bị:", error);
        res.status(500).json({ error: "Lỗi máy chủ khi lấy thiết bị" });
    }
});

// 🔹 Cập nhật thiết bị theo deviceId
router.put("/:deviceId", authMiddleware, async (req, res) => {
    try {
        const deviceId = Number(req.params.deviceId); // Ép kiểu
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


// 🔹 Xóa thiết bị theo deviceId
router.delete("/:deviceId", authMiddleware, async (req, res) => {
    try {
        const userId = req.user.userId;
        const deviceId = Number(req.params.deviceId); // Ép kiểu

        const deletedDevice = await Device.findOneAndDelete({ deviceId, userId });
        if (!deletedDevice) return res.status(404).json({ error: "Không tìm thấy thiết bị của user này" });

        await User.updateOne({ userId }, { $pull: { devices: deviceId } });
        res.json({ message: "Thiết bị đã được xóa thành công!" });
    } catch (error) {
        console.error("Lỗi khi xóa thiết bị:", error);
        res.status(500).json({ error: "Lỗi khi xóa thiết bị" });
    }
});

// 🔹 Lấy danh sách tất cả thiết bị của người dùng
router.get("/", authMiddleware, async (req, res) => {
    try {
        const userId = req.user.userId;
        const devices = await Device.find({ userId });
        res.json({ devices });
    } catch (error) {
        console.error("Lỗi khi lấy danh sách thiết bị:", error);
        res.status(500).json({ error: "Lỗi khi lấy danh sách thiết bị" });
    }
});

module.exports = router;
