const express = require("express");
const axios = require("axios");
const cors = require("cors");
const mongoose = require("mongoose");
require("dotenv").config();

const SensorData = require("./models/SensorData");
const User = require("./models/user"); // ⚠️ Thêm import model User
const authMiddleware = require("./middleware/authMiddleware");

// Import routes
const deviceRoutes = require("./routes/deviceRoutes");
const authRoutes = require("./routes/authRoutes");

// Khởi tạo ứng dụng Express
const app = express();
const port = 3000;
const wsPort = 8080;
//const BLYNK_TOKEN = process.env.BLYNK_TOKEN;

app.use(express.json());
app.use(cors({
    origin: "*", // Hoặc chỉ định domain frontend
    methods: ["GET", "POST", "PUT", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"]
}));

// Kết nối MongoDB
mongoose.connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
}).then(async () => {
    console.log("✅ Kết nối MongoDB thành công!");

    // Tạo TTL Index tự động nếu chưa có
    const collection = mongoose.connection.db.collection("sensordatas");
    await collection.createIndex({ timestamp: 1 }, { expireAfterSeconds: 604800 });

    console.log("✅ TTL Index thiết lập (dữ liệu cũ hơn 7 ngày sẽ tự động bị xóa).");
}).catch(err => console.error("❌ Lỗi kết nối MongoDB:", err));

app.get("/", (req, res) => {
    res.send("🚀 Server IoT Báo Cháy đã sẵn sàng!");
});

// Routes API

// Xử lý route không tìm thấy
app.use((req, res) => {
    res.status(404).json({ error: "🔍 Không tìm thấy API!" });
});

// Xử lý lỗi máy chủ
app.use((err, req, res, next) => {
    console.error("💥 Lỗi máy chủ:", err.message);
    res.status(500).json({ error: "💥 Lỗi máy chủ!" });
});

// ====================================================
// 🔥 WebSocket Server
// ====================================================
// const http = require("http");
// const WebSocket = require("ws");
// const jwt = require("jsonwebtoken"); // Import User model
// require("dotenv").config();

// //const app = express();
// const server = http.createServer(app);
// const wss = new WebSocket.Server({ server });

// const BLYNK_TOKEN = process.env.BLYNK_TOKEN;
// const clients = new Map();
// const previousData = new Map();

// const fetchData = async (deviceId) => {
//     try {
//         const [tempRes, humidRes, smokeRes] = await Promise.all([
//             axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V1`),
//             axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V2`),
//             axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V3`),
//         ]);

//         const data = {
//             deviceId,
//             temperature: parseFloat(tempRes.data),
//             humidity: parseFloat(humidRes.data),
//             smokeLevel: parseInt(smokeRes.data),
//         };

//         if (isNaN(data.temperature) || isNaN(data.humidity) || isNaN(data.smokeLevel)) {
//             console.warn(`⚠️ Dữ liệu không hợp lệ từ ${deviceId}:`, data);
//             return null;
//         }

//         return data;
//     } catch (error) {
//         console.error(`❌ Lỗi lấy dữ liệu từ Blynk (${deviceId}):`, error.message);
//         return null;
//     }
// };

// // 📥 Xử lý kết nối WebSocket
// wss.on("connection", async (ws) => {
//     console.log("⚡ Một client vừa kết nối, chờ xác thực...");

//     ws.isAuthenticated = false;

//     // 📥 Xử lý message từ client
//     ws.on("message", async (message) => {
//         try {
//             const data = JSON.parse(message);

//             // 🔐 Nếu client gửi token để xác thực
//             if (data.type === "authenticate") {
//                 try {
//                     const decoded = jwt.verify(data.token, process.env.JWT_SECRET);
//                     const user = await User.findById(decoded.id).select("-password");

//                     if (!user) {
//                         console.error("❌ User không hợp lệ");
//                         ws.send(JSON.stringify({ type: "auth_error", message: "User không hợp lệ!" }));
//                         ws.close();
//                         return;
//                     }

//                     console.log(`✅ User ${user.id} đã xác thực WebSocket`);
//                     ws.userId = user.id;
//                     ws.isAuthenticated = true;

//                     // 🔹 Lưu WebSocket theo userId
//                     if (!clients.has(user.id)) {
//                         clients.set(user.id, new Set());
//                     }
//                     clients.get(user.id).add(ws);

//                     ws.send(JSON.stringify({ type: "auth_success", message: "Xác thực thành công!" }));
//                 } catch (err) {
//                     console.error("❌ Token không hợp lệ:", err.message);
//                     ws.send(JSON.stringify({ type: "auth_error", message: "Token không hợp lệ!" }));
//                     ws.close();
//                 }
//                 return;
//             }

//             // 🔴 Chặn tin nhắn nếu user chưa xác thực
//             if (!ws.isAuthenticated) {
//                 ws.send(JSON.stringify({ type: "auth_error", message: "Bạn chưa xác thực!" }));
//                 return;
//             }

//             const userDevices = await User.findById(ws.userId).select("devices").lean();
//             if (!userDevices || !userDevices.devices.includes(data.deviceId)) {
//                 console.warn(`⚠️ User ${ws.userId} không có quyền truy cập deviceId ${data.deviceId}`);
//                 return;
//             }

//             // 🔁 Điều khiển relay
//             if (data.action === "toggleRelay") {
//                 console.log(`🔁 Điều khiển relay trên ${data.deviceId}: ${data.state}`);
//                 await axios.get(`https://blynk.cloud/external/api/update?token=${BLYNK_TOKEN}&pin=V0&value=${data.state === "on" ? 1 : 0}`);
//             }
//         } catch (err) {
//             console.error("❌ Lỗi xử lý dữ liệu từ client:", err);
//         }
//     });

//     // ❌ Khi client ngắt kết nối
//     ws.on("close", () => {
//         console.log(`⚡ User ${ws.userId || "chưa xác thực"} ngắt kết nối`);
//         if (ws.userId && clients.has(ws.userId)) {
//             clients.get(ws.userId).delete(ws);
//             if (clients.get(ws.userId).size === 0) {
//                 clients.delete(ws.userId);
//             }
//         }
//     });

//     // 🚨 Xử lý lỗi WebSocket
//     ws.on("error", (err) => {
//         console.error(`❌ Lỗi WebSocket: ${err.message}`);
//     });
// });

// // 📡 Gửi dữ liệu định kỳ mỗi 2 giây
// const sendData = async () => {
//     for (const [userId, userClients] of clients.entries()) {
//         const userDevices = await User.findById(userId).select("devices").lean();
//         if (!userDevices) continue;

//         for (const deviceId of userDevices.devices) {
//             const newData = await fetchData(deviceId);
//             if (!newData) continue;

//             // 🔹 Chỉ gửi nếu dữ liệu thay đổi
//             if (JSON.stringify(newData) !== JSON.stringify(previousData.get(deviceId))) {
//                 previousData.set(deviceId, newData);
//                 for (const client of userClients) {
//                     client.send(JSON.stringify({ type: "sensorData", data: newData }));
//                 }
//             }
//         }
//     }
// };

// // ⏳ Chạy sendData mỗi 2 giây
// setInterval(sendData, 2000);



// 🔥 Khởi động Express Server
// server.listen(wsPort, () => {
//     console.log(`🚀 Server HTTP chạy tại http://localhost:${wsPort}`);
//     console.log(`📡 WebSocket chạy tại ws://localhost:${wsPort}`);
// });
//app.use("/api/auth", authRoutes);

app.use("/api/devices", deviceRoutes);
app.use("/api/auth", authRoutes);

server.listen(port, () => {
    console.log(`🚀 Server HTTP chạy tại http://localhost:${port}`);
   // console.log(`📡 WebSocket chạy tại ws://localhost:${wsPort}`);
});
