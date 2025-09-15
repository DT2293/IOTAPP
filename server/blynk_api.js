const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const cors = require("cors");
const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const axios = require("axios");
require("./utils/dailydata.js"); // Import file dailydata.js để chạy cron job
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
const User = require("./models/user.js");

// 🔹 Routes API
app.use("/api/auth", require("./routes/authRoutes.js"));
app.use("/api/devices", require("./routes/deviceRoutes.js"));
app.use("/api/fcm-token", require("./routes/fcmRoutes.js"));
app.use("/api/data", require("./routes/dataRoutes.js")); // Thêm route cho dữ liệu

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
const BLYNK_TOKEN = "y1uuRJfoya5d-4LuFATabTxi9gRegI0X";


// 📡 Lấy dữ liệu từ Blynk
const fetchData = async (deviceId) => {
    try {
        const [tempRes, humidRes, smokeRes] = await Promise.all([
            axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V2`),
            axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V1`),
            axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V3`),
        ]);

        const data = {
            deviceId,
            temperature: parseFloat(tempRes.data),
            humidity: parseFloat(humidRes.data),
            smokeLevel: parseInt(smokeRes.data),
        };

        if (isNaN(data.temperature) || isNaN(data.humidity) || isNaN(data.smokeLevel)) {
            console.warn(`Dữ liệu không hợp lệ từ ${deviceId}:`, data);
            return null;
        }

        return data;
    } catch (error) {
        console.error(`Lỗi lấy dữ liệu từ Blynk (${deviceId}):`, error.message);
        return null;
    }
};

// Xử lý kết nối WebSocket
wss.on("connection", async (ws) => {
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
                    console.error("Token không hợp lệ:", err.message);
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
                console.warn(`User ${ws.userId} không có quyền truy cập deviceId ${data.deviceId}`);
                return;
            }

            if (data.action === "toggleRelay") {
                try {
                    await axios.get(`https://blynk.cloud/external/api/update?token=${BLYNK_TOKEN}&pin=V0&value=${data.state === "on" ? 1 : 0}`);
                    ws.send(JSON.stringify({
                        deviceId: data.deviceId,
                        message: `Relay đã được ${data.state === "on" ? "bật" : "tắt"}!`
                    }));
                } catch (error) {
                    console.error("Lỗi điều khiển relay:", error.message);
                    ws.send(JSON.stringify({
                        type: "relayError",
                        message: "Không thể điều khiển relay!"
                    }));
                }
            }
            
        } catch (err) {
            console.error("Lỗi xử lý dữ liệu từ client:", err);
        }
    });

    ws.on("close", () => {
        console.log(`User ${ws.userId || "chưa xác thực"} ngắt kết nối`);
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

 const { handleAlert } = require("./fcm_services/handleAlert.js");

const SensorDataRaw = require('./models/sensordata_raw.js');

const sendData = async () => {
    const users = await User.find().select("userId devices");

    for (const user of users) {
        for (const deviceId of user.devices) {
            const newData = await fetchData(deviceId);
            if (!newData) continue;

            await SensorDataRaw.create({
                userId: user.userId,
                deviceId,
                temperature: newData.temperature,
                humidity: newData.humidity,
                smokeLevel: newData.smokeLevel,
                flameDetected: newData.flame === 0,
                timestamp: new Date()
            });

            if (JSON.stringify(newData) !== JSON.stringify(previousData.get(deviceId))) {
                if (newData.flame === 1) {
                    await handleAlert(deviceId, newData);
                }
            }
            previousData.set(deviceId, newData);

            const userClients = clients.get(user.userId);
            if (userClients) {
                for (const client of userClients) {
                    client.send(JSON.stringify({ type: "realtime_data", data: newData }));
                }
            }
        }
    }
};

setInterval(sendData, 2000);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log('hello')
    console.log(`🚀 HTTP Server chạy tại http://localhost:${PORT}`);
    console.log(`📡 WebSocket Server chạy tại ws://localhost:${PORT}`);
});