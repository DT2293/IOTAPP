const express = require("express");
const router = express.Router();
const Device = require("../models/Device");
const mongoose = require('mongoose');
const User = require("../models/user"); // Import User model
const authMiddleware = require("../middleware/authMiddleware");

// 🔹 1️⃣ Thêm thiết bị mới

// router.post("/devices", async (req, res) => {
//     try {
//         console.log("Data received:", req.body); // Debug log

//         let { _id, userId, deviceName, location, active } = req.body;

//         if (!userId || !deviceName || !location || active === undefined) {
//             return res.status(400).json({ error: "Thiếu thông tin thiết bị!" });
//         }

//         // Nếu _id không tồn tại, tự sinh ObjectId mới
//         _id = _id ? new mongoose.Types.ObjectId(_id) : new mongoose.Types.ObjectId();

//         // Chuyển active từ số/chữ thành Boolean
//         active = active === "1" || active === 1 ? true : false;

//         const newDevice = new Device({ _id, userId, deviceName, location, active });
//         await newDevice.save();
        
//         res.status(201).json({ message: "Thiết bị đã được thêm!", device: newDevice });
//     } catch (error) {
//         console.error("Lỗi khi thêm thiết bị:", error);
//         res.status(500).json({ error: "Lỗi khi thêm thiết bị", details: error.message });
//     }
// });

router.post("/devices", authMiddleware, async (req, res) => {
    try {
        console.log("Decoded user:", req.user);
        const userId = req.user.userId;  
        console.log("UserID from token:", userId);

        const { deviceName, location, active } = req.body;

        const user = await User.findById(userId);
        console.log("User found in DB:", user);

        if (!user) return res.status(404).json({ error: "Không tìm thấy User" });

        const newDevice = new Device({ userId, deviceName, location, active });
        await newDevice.save();

        if (!user.devices) {
            user.devices = [];
        }

        user.devices.push(newDevice._id);
        await user.save();

        res.status(201).json({ message: "Thiết bị được thêm thành công!", device: newDevice });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Lỗi khi thêm thiết bị" });
    }
});


// 🔹 2️⃣ Lấy danh sách thiết bị theo userId
// router.get("/devices/:userId", authMiddleware, async (req, res) => {
//     try {
//         const userId = req.params.userId;

//         if (!mongoose.Types.ObjectId.isValid(userId)) {
//             return res.status(400).json({ error: "ID không hợp lệ" });
//         }

//         const devices = await Device.find({ userID: new mongoose.Types.ObjectId(userId) });

//         if (!devices || devices.length === 0) {
//             return res.status(404).json({ error: "Không tìm thấy thiết bị nào" });
//         }

//         res.json(devices);
//     } catch (error) {
//         console.error(error);
//         res.status(500).json({ error: "Lỗi khi lấy danh sách thiết bị" });
//     }
// });

router.get("/devices/:deviceId", authMiddleware, async (req, res) => {
    try {
        const { deviceId } = req.params;

        if (!mongoose.Types.ObjectId.isValid(deviceId)) {
            return res.status(400).json({ error: "ID thiết bị không hợp lệ" });
        }

        const device = await Device.findById(deviceId).populate("userId", "username email"); // Lấy thông tin user

        if (!device) {
            return res.status(404).json({ error: "Không tìm thấy thiết bị" });
        }

        res.json(device);
    } catch (error) {
        console.error("Lỗi khi lấy thiết bị:", error);
        res.status(500).json({ error: "Lỗi máy chủ khi lấy thiết bị" });
    }
});


// 🔹 3️⃣ Cập nhật thông tin thiết bị

router.put("/devices/:deviceId",authMiddleware ,async (req, res) => {
    try {
        const { deviceName, location, active } = req.body;

        // Kiểm tra nếu thiết bị tồn tại
        const existingDevice = await Device.findById(req.params.deviceId);
        if (!existingDevice) {
            return res.status(404).json({ error: "Không tìm thấy thiết bị" });
        }

        // Cập nhật dữ liệu 
        if (deviceName !== undefined) existingDevice.deviceName = deviceName;
        if (location !== undefined) existingDevice.location = location;
        if (active !== undefined) existingDevice.active = Boolean(active);

        await existingDevice.save();

        res.json({ message: "Cập nhật thành công!", device: existingDevice });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Lỗi khi cập nhật thiết bị" });
    }
});



// router.put("/devices/:deviceId", async (req, res) => {
//     try {
//         const { deviceName, location, active } = req.body;

//         // Kiểm tra nếu thiết bị tồn tại
//         const existingDevice = await Device.findById(req.params.deviceId);
//         if (!existingDevice) {
//             return res.status(404).json({ error: "Không tìm thấy thiết bị" });
//         }

//         // Cập nhật thiết bị với active đã ép kiểu
//         const updatedDevice = await Device.findByIdAndUpdate(
//             req.params.deviceId,
//             { 
//                 deviceName, 
//                 location, 
//                 active: Boolean(active) // Chuyển đổi giá trị 
//             },
//             { new: true } 
//         );

//         res.json({ message: "Cập nhật thành công!", device: updatedDevice });
//     } catch (error) {
//         console.error(error);
//         res.status(500).json({ error: "Lỗi khi cập nhật thiết bị" });
//     }
// });


// 🔹 4️⃣ Xóa thiết bị
router.delete("/devices/:deviceId",authMiddleware ,async (req, res) => {
    try {
        const deletedDevice = await Device.findByIdAndDelete(req.params.deviceId);
        if (!deletedDevice) return res.status(404).json({ error: "Không tìm thấy thiết bị" });

        let listcurrentDevice = await Device.find(); // Lấy tất cả thiết bị trong collection
       // res.json(listcurrentDevice);
        res.json({ message: "Thiết bị đã được xóa!", device: listcurrentDevice });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Lỗi khi xóa thiết bị" });
    }
});

// router.delete("/devices/:deviceId", async (req, res) => {
//     try {
//         const deletedDevice = await Device.findByIdAndDelete(req.params.deviceId);
//         if (!deletedDevice) return res.status(404).json({ error: "Không tìm thấy thiết bị" });

//         res.json({ message: "Thiết bị đã được xóa!", deletedDevice });

//         // Nếu muốn trả về danh sách hiện tại sau khi xóa
//         // const listcurrentDevice = await Device.find();
//         // res.json({ message: "Thiết bị đã được xóa!", devices: listcurrentDevice });

//     } catch (error) {
//         console.error(error);
//         res.status(500).json({ error: "Lỗi khi xóa thiết bị" });
//     }
// });

// 🔹 5️⃣ Lấy tất cả thiết bị
// router.get("/devices",authMiddleware ,async (req, res) => {
//     try {
//         const devices = await Device.find(); // Lấy tất cả thiết bị trong collection
//         res.json(devices);
//     } catch (error) {
//         console.error(error);
//         res.status(500).json({ error: "Lỗi khi lấy danh sách thiết bị" });
//     }
// });

router.get("/devices", authMiddleware, async (req, res) => {
    try {
        const userId = req.user.userId; // Lấy userId từ token
        const devices = await Device.find({ userId });

        res.json({ devices });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Lỗi khi lấy danh sách thiết bị" });
    }
});

module.exports = router;
