const jwt = require("jsonwebtoken");
require("dotenv").config();


const authMiddleware = (req, res, next) => {
    const token = req.header("Authorization");
    if (!token) {
        return res.status(401).json({ error: "Truy cập bị từ chối, không có token!" });
    }

    try {
      //  const decoded = jwt.verify(token.replace("Bearer ", ""), "SECRET_KEY");
      const decoded = jwt.verify(token.replace("Bearer ", ""), process.env.JWT_SECRET);

        req.user = decoded; // Gán thông tin user từ token
        next();
    } catch (error) {
        res.status(401).json({ error: "Token không hợp lệ!" });
    }
};

module.exports = authMiddleware;

// const WebSocket = require("ws");
// const axios = require("axios");
// const jwt = require("jsonwebtoken");
// const User = require("../models/user"); // Kiểm tra lại đường dẫn
// const wsPort = 8080;

// const wss = new WebSocket.Server({ port: wsPort });
// const clients = new Map();
// let previousData = new Map();

// console.log(`📡 WebSocket Server chạy trên ws://localhost:${wsPort}`);

// wss.on("connection", async (ws, req) => {
//     // 🔹 Lấy token từ URL (WebSocket không có headers)
//     const urlParams = new URLSearchParams(req.url.split("?")[1]);
//     const token = urlParams.get("token");

//     if (!token) {
//         console.error("❌ Không có token, từ chối kết nối WebSocket");
//         ws.close();
//         return;
//     }

//     try {
//         // ✅ Giải mã token bằng JWT
//         const decoded = jwt.verify(token, process.env.JWT_SECRET);
//         const user = await User.findById(decoded.id).select("-password");

//         if (!user) {
//             console.error("❌ User không hợp lệ");
//             ws.close();
//             return;
//         }

//         console.log(`⚡ User ${user.id} đã kết nối WebSocket`);

//         // Lấy danh sách thiết bị của user
//         const userDevices = await User.findById(user.id).select("devices").lean();
//         if (!userDevices) {
//             ws.close();
//             return;
//         }

//         // Lưu client theo userId
//         if (!clients.has(user.id)) {
//             clients.set(user.id, new Set());
//         }
//         clients.get(user.id).add(ws);

//         ws.on("close", () => {
//             console.log(`⚡ User ${user.id} ngắt kết nối`);
//             clients.get(user.id)?.delete(ws);
//         });
//     } catch (err) {
//         console.error("❌ Token không hợp lệ:", err.message);
//         ws.close();
//     }
// });
