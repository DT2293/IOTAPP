// const { sendNotificationToDevice } = require("./fcm_services/sendNotification");

// const fcmToken = "eey0mME-QkeM1wLYqR99BE:APA91bG3pDlDDSbtevwAKeGPafRaTsFZwr8ywnYg-PTlamaDz8pE4jX-OOohH_Grumct47QXKUimS09_CJQAtrqvF85JfxbGwKqG_TsYKaVu7P_Jb-ilz7o"; // 🔁 Thay bằng token thật từ thiết bị
// const title = "🔥 Test Notification";
// const body = "Đây là thông báo test FCM từ test.js";
// const data = {
//   deviceId: "test_device_123",
//   type: "fire_alert",
// };

// (async () => {
//   console.log("🚀 Đang gửi thông báo test...");
//   await sendNotificationToDevice(fcmToken, title, body, data);
// })();




const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const cors = require("cors");
const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const axios = require("axios");
require("dotenv").config();
//console.log("JWT_SECRET:", process.env.JWT_SECRET);
require("./utils/dailydata"); 
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
const deviceClients = new Map(); // key: deviceId, value: ws
// Hàm gửi lệnh báo động đến tất cả WebSocket của user


function sendAlarmCommandToDevice(deviceId, command) {
    console.log(`👉 Gửi lệnh đến thiết bị: ${deviceId}, command: ${command}`);
    const wsDevice = deviceClients.get(deviceId);
    console.log("🔍 wsDevice:", wsDevice ? "ĐÃ TÌM THẤY" : "KHÔNG TÌM THẤY");

    if (wsDevice && wsDevice.readyState === WebSocket.OPEN) {
        const msg = JSON.stringify({ type: "alarm_command", command, deviceId });
        wsDevice.send(msg);
        console.log("✅ Đã gửi lệnh đến thiết bị");
    } else {
        console.warn(`⚠️ Không tìm thấy kết nối thiết bị ${deviceId}`);
    }
}
// app.post("/api/alarm/:userId/:command", async (req, res) => {
//     const userId = Number(req.params.userId);
//     const command = req.params.command;

//     if (!["alarm_on", "alarm_off"].includes(command)) {
//         return res.status(400).json({ error: "Lệnh không hợp lệ" });
//     }

//     // Lấy danh sách thiết bị user được phép điều khiển
//     const user = await User.findOne({ userId }).select("devices").lean();
//     if (!user) {
//         return res.status(404).json({ error: "User không tồn tại" });
//     }

//     for (const deviceId of user.devices) {
//         sendAlarmCommandToDevice(deviceId, command);
//     }

//     res.json({ message: `Đã gửi lệnh ${command} đến tất cả thiết bị của user ${userId}` });
// });


app.post("/api/sensordata", async (req, res) => {
    try {
        const { deviceId,temperature,humidity,smokeLevel, flame } = req.body;

        if (typeof smokeLevel !== "number" || typeof flame !== "boolean") {
            return res.status(400).json({ message: "Dữ liệu không hợp lệ" });
        }

        console.log(`📥 Dữ liệu từ thiết bị ${deviceId}:`);
        console.log(`🌡️ Nhiệt độ: ${temperature}°C`);
        console.log(`💧 Độ ẩm: ${humidity}%`);
        console.log(`💨 Mức khói: ${smokeLevel}`);
        console.log(`🔥 Lửa: ${flame ? "Có" : "Không"}`);
        console.log("------------------------------------");

        const sensorData = { deviceId,temperature,humidity ,smokeLevel, flame, time: new Date() };

        // Lưu dữ liệu
        previousData.set(deviceId, sensorData);
        latestSensorDataMap.set(deviceId, sensorData);// 👈 Thêm dòng này

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
        console.log("📥 Server nhận message từ client:", message);
        console.log("📥 Server nhận message từ client:", message.toString());

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

                    ws.send(JSON.stringify({
                        type: "alarm_command",
                        command: "alarm_on"
                    }));
                } catch (err) {
                    ws.send(JSON.stringify({ type: "auth_error", message: "Token không hợp lệ!" }));
                    ws.close();
                }
                return;
            }

            if (data.type === "device_authenticate") {
                // Xác thực thiết bị đơn giản
                const deviceId = data.deviceId;
                if (typeof deviceId === "string") {
                    ws.isAuthenticated = true;
                    ws.isDevice = true;
                    ws.deviceId = deviceId;
                    deviceClients.set(deviceId, ws);
                    console.log(`⚡ Thiết bị ${deviceId} đã kết nối WebSocket không cần JWT`);
                    ws.send(JSON.stringify({ type: "auth_success", message: "Thiết bị xác thực thành công" }));
                } else {
                    ws.send(JSON.stringify({ type: "auth_error", message: "deviceId không hợp lệ" }));
                    ws.close();
                }
                // Không xóa deviceClients ở đây nữa
                return;
            }
            if (data.type === "alarm_command") {
                // Kiểm tra ws đã xác thực user chưa
                if (!ws.isAuthenticated || !ws.userId) {
                    ws.send(JSON.stringify({ type: "error", message: "Chưa xác thực user" }));
                    return;
                }

                // Kiểm tra user có quyền với deviceId không
                const userDevices = await User.findOne({ userId: ws.userId }).select("devices").lean();
                if (!userDevices || !Array.isArray(userDevices.devices) || !data.deviceId || !userDevices.devices.includes(data.deviceId)) {
                    ws.send(JSON.stringify({ type: "error", message: "Không có quyền truy cập device này" }));
                    return;
                }

                // Gửi lệnh tới thiết bị qua deviceClients
                sendAlarmCommandToDevice(data.deviceId, data.command);

                // Trả phản hồi cho user
                ws.send(JSON.stringify({
                    type: "alarm_command_ack",
                    message: `Lệnh ${data.command} đã được gửi tới thiết bị ${data.deviceId}`
                }));

                return;
            }

            if (!ws.isAuthenticated) {
                ws.send(JSON.stringify({ type: "auth_error", message: "Bạn chưa xác thực!" }));
                return;
            }

            // Kiểm tra quyền truy cập thiết bị
            const userDevices = await User.findOne({ userId: ws.userId }).select("devices").lean();

            if (!userDevices || !Array.isArray(userDevices.devices) || !data.deviceId || !userDevices.devices.includes(data.deviceId)) {
                console.warn(`⚠️ User ${ws.userId} không có quyền truy cập deviceId ${data.deviceId}`);
                return;
            }

            // Xử lý các message khác nếu cần

        } catch (err) {
            console.error("❌ Lỗi xử lý dữ liệu từ client:", err);
        }
    });

    ws.on("close", () => {
        console.log(`⚡ User ${ws.userId || ws.deviceId || "chưa xác thực"} ngắt kết nối`);

        if (ws.userId && clients.has(ws.userId)) {
            clients.get(ws.userId).delete(ws);
            if (clients.get(ws.userId).size === 0) {
                clients.delete(ws.userId);
            }
        }

        if (ws.isDevice && ws.deviceId && deviceClients.has(ws.deviceId)) {
            deviceClients.delete(ws.deviceId);
        }
    });

    ws.on("error", (err) => {
        console.error(`❌ Lỗi WebSocket: ${err.message}`);
    });
    ws.on("error", (err) => {
        console.error(`❌ Lỗi WebSocket: ${err.message}`);
    });
});



const { handleAlert } = require("./fcm_services/handleAleart2");
const authMiddleware = require("./utils/authMiddleware");

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
                //       console.log(`🚨 Gửi cảnh báo cho thiết bị ${deviceId}`);
                await handleAlert(deviceId, newData);
            }

            // Cập nhật dữ liệu cũ nếu muốn dùng cho mục đích khác
            previousData.set(deviceId, newData);
        }
    }
};

const SensorDataRaw = require("./models/sensordata_raw");

const saveRawSensorData = async () => {
    try {
        const users = await User.find().select("userId devices");

        for (const user of users) {
            for (const deviceId of user.devices) {
                const data = latestSensorDataMap.get(deviceId);

                if (!data) continue;

                // 👇 Cập nhật các trường bạn có, ví dụ bạn cần thêm nhiệt độ và độ ẩm
                const { smokeLevel, flame } = data;
                const temperature = data.temperature ?? 0;
                const humidity = data.humidity ?? 0;

                const rawEntry = new SensorDataRaw({
                    userId: user.userId,
                    deviceId,
                    temperature,
                    humidity,
                    smokeLevel,
                    flameDetected: flame
                });

                await rawEntry.save();
            }
        }

        console.log("✅ Đã lưu dữ liệu sensor raw vào MongoDB");
    } catch (err) {
        console.error("❌ Lỗi khi lưu sensor raw:", err);
    }
};
setInterval(saveRawSensorData, 5 * 60 * 1000); // mỗi 5 phút
// Chạy liên tục để gửi cảnh báo (tuỳ chỉnh tần suất)
setInterval(sendData, 5000);
// 🚀 Khởi động HTTP + WebSocket Server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
   // console.log('hello')
    console.log(`🚀 HTTP Server chạy tại http://localhost:${PORT}`);
    console.log(`📡 WebSocket Server chạy tại ws://localhost:${PORT}`);
}); 