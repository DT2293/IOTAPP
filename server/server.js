// const express = require("express");
// const http = require("http");
// const WebSocket = require("ws");
// const cors = require("cors");
// const mongoose = require("mongoose");
// const jwt = require("jsonwebtoken");
// const axios = require("axios");
// require("dotenv").config();
// console.log("JWT_SECRET:", process.env.JWT_SECRET);

// // Khởi tạo Express app
// const app = express();
// app.use(express.json());
// app.use(cors());

// // Kết nối MongoDB
// mongoose.connect(process.env.MONGO_URI, {
//     useNewUrlParser: true,
//     useUnifiedTopology: true,
// }).then(() => console.log("✅ Kết nối MongoDB thành công!"))
//     .catch(err => console.error("❌ Lỗi kết nối MongoDB:", err));

// // Import models
// const User = require("./models/user");

// // 🔹 Routes API
// app.use("/api/auth", require("./routes/authRoutes"));
// app.use("/api/devices", require("./routes/deviceRoutes"));
// app.use("/api/fcm-token", require("./routes/fcmRoutes"));
// app.use("/api/data", require("./routes/dataRoutes"));

const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const cors = require("cors");
const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const axios = require("axios");
require("dotenv").config();
console.log("JWT_SECRET:", process.env.JWT_SECRET);

// Khởi tạo Express app
const app = express();
app.use(express.json());
app.use(cors());

// Kết nối MongoDB
mongoose.connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
}).then(() => console.log("✅ Kết nối MongoDB thành công!"))
    .catch(err => console.error("❌ Lỗi kết nối MongoDB:", err));

// Import models
const User = require("./models/user");

// 🔹 Routes API
app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/devices", require("./routes/deviceRoutes"));
app.use("/api/fcm-token", require("./routes/fcmRoutes"));
app.use("/api/data", require("./routes/dataRoutes")); // Thêm route cho dữ liệu


app.get("/", (req, res) => {
    res.send("🚀 Server IoT Báo Cháy đã sẵn sàng!");
});

// Tạo HTTP Server
const server = http.createServer(app);

// ====================================================
// WebSocket Server
// ====================================================
const wss = new WebSocket.Server({ server });
const clients = new Map();
const previousData = new Map();
const latestSensorDataMap = new Map();

app.post("/api/sensordata", async (req, res) => {
    try {
        const { deviceId, smokeLevel, flame } = req.body;

        if (typeof smokeLevel !== "number" || typeof flame !== "boolean") {
            return res.status(400).json({ message: "Dữ liệu không hợp lệ" });
        }

        console.log(`📥 Dữ liệu từ thiết bị ${deviceId}:`);
        console.log(`💨 Mức khói: ${smokeLevel}`);
        console.log(`🔥 Lửa: ${flame ? "Có" : "Không"}`);
        console.log("------------------------------------");

        const sensorData = { deviceId, smokeLevel, flame, time: new Date() };

        // Lưu dữ liệu
        previousData.set(deviceId, sensorData);
        latestSensorDataMap.set(deviceId, sensorData); // 👈 Thêm dòng này

        // Gửi realtime tới các user có quyền
        const users = await User.find({ devices: deviceId }).select("userId devices");

        for (const user of users) {
            const userClients = clients.get(user.userId);
            if (userClients) {
                for (const ws of userClients) {
                    if (ws.readyState === ws.OPEN) {
                        ws.send(JSON.stringify({ type: "sensordatas", data: sensorData }));
                    }
                }
            }
        }

        res.status(200).json({ message: "Dữ liệu nhận thành công" });
    } catch (error) {
        console.error("❌ Lỗi xử lý dữ liệu:", error);
        res.status(500).json({ message: "Lỗi server" });
    }
});

wss.on("connection", async (ws) => {
    console.log("⚡ Một client vừa kết nối, chờ xác thực...");
    ws.isAuthenticated = false;

    ws.on("message", async (message) => {
        try {
            const data = JSON.parse(message);

            if (data.type === "authenticate") {
                try {
                    const decoded = jwt.verify(data.token, process.env.JWT_SECRET);
                    const user = await User.findOne({ userId: Number(decoded.userId) }).select("-password");

                    if (!user) {
                        ws.send(JSON.stringify({ type: "auth_error", message: "User không hợp lệ!" }));
                        ws.close();
                        return;
                    }

                    console.log(`✅ User ${user.userId} đã xác thực WebSocket`);
                    ws.userId = user.userId;
                    ws.isAuthenticated = true;

                    if (!clients.has(user.userId)) {
                        clients.set(user.userId, new Set());
                    }
                    clients.get(user.userId).add(ws);

                    ws.send(JSON.stringify({ type: "auth_success", message: "Xác thực thành công!" }));
                } catch (err) {
                    ws.send(JSON.stringify({ type: "auth_error", message: "Token không hợp lệ!" }));
                    ws.close();
                }
                return;
            }

            if (!ws.isAuthenticated) {
                ws.send(JSON.stringify({ type: "auth_error", message: "Bạn chưa xác thực!" }));
                return;
            }

            const userDevices = await User.findOne({ userId: ws.userId }).select("devices").lean();
            if (!userDevices || !userDevices.devices.includes(data.deviceId)) {
                console.warn(`⚠️ User ${ws.userId} không có quyền truy cập deviceId ${data.deviceId}`);
                return;
            }

        } catch (err) {
            console.error("❌ Lỗi xử lý dữ liệu từ client:", err);
        }
    });

    ws.on("close", () => {
        console.log(`⚡ User ${ws.userId || "chưa xác thực"} ngắt kết nối`);
        if (ws.userId && clients.has(ws.userId)) {
            clients.get(ws.userId).delete(ws);
            if (clients.get(ws.userId).size === 0) {
                clients.delete(ws.userId);
            }
        }
    });

    ws.on("error", (err) => {
        console.error(`❌ Lỗi WebSocket: ${err.message}`);
    });
});

// const { handleAlert } = require("./fcm_services/handleAleart2");
// const sendData = async () => {
//     console.log("🕒 sendData được gọi");
//     const users = await User.find().select("userId devices");

//     for (const user of users) {
//         for (const deviceId of user.devices) {
//             const newData = latestSensorDataMap.get(deviceId);
//             console.log("📍 newData lấy ra:", newData);
//             if (!newData) continue;

//             const oldData = previousData.get(deviceId);
//             console.log("📍 oldData:", oldData);
//             console.log("📍 newData:", newData);

//             if (JSON.stringify(newData) !== JSON.stringify(oldData)) {
//                 console.log(`📊 Dữ liệu mới khác dữ liệu cũ: smokeLevel=${newData.smokeLevel}, flame=${newData.flame}`);

//                 // if (newData.smokeLevel >= 300 || newData.flame) {
//                 //   console.log(`🚨 Gửi cảnh báo cho thiết bị ${deviceId}`);
//                 //   await handleAlert(deviceId, newData);
//                 // }
//                 if ((newData.smokeLevel >= 300 || newData.flame) && (!oldData || newData.smokeLevel !== oldData.smokeLevel || newData.flame !== oldData.flame)) {
//                     console.log(`🚨 Gửi cảnh báo cho thiết bị ${deviceId}`);
//                     await handleAlert(deviceId, newData);
//                 }

//                 previousData.set(deviceId, newData);
//             }
//         }
//     }
// };


const { handleAlert } = require("./fcm_services/handleAleart2");

const sendData = async () => {
   // console.log("🕒 sendData được gọi");
    const users = await User.find().select("userId devices");

    for (const user of users) {
        for (const deviceId of user.devices) {
            const newData = latestSensorDataMap.get(deviceId);
     //       console.log("📍 newData lấy ra:", newData);
            if (!newData) continue;

            // 🚨 Luôn kiểm tra nếu đang trong trạng thái nguy hiểm
            if (newData.smokeLevel >= 300 || newData.flame === true) {
                console.log(`🚨 Gửi cảnh báo cho thiết bị ${deviceId}`);
                await handleAlert(deviceId, newData);
            }

            // Cập nhật dữ liệu cũ nếu muốn dùng cho mục đích khác
            previousData.set(deviceId, newData);
        }
    }
};

// Chạy liên tục để gửi cảnh báo (tuỳ chỉnh tần suất)
setInterval(sendData, 5000);
// 🚀 Khởi động HTTP + WebSocket Server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log('hello')
    console.log(`🚀 HTTP Server chạy tại http://localhost:${PORT}`);
    console.log(`📡 WebSocket Server chạy tại ws://localhost:${PORT}`);
});
