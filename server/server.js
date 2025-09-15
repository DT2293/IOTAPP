const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const cors = require("cors");
const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const axios = require("axios");
require("dotenv").config();
require("./utils/dailydata"); 
const app = express();
app.use(express.json());
app.use(cors());

mongoose.connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
}).then(() => console.log("Kết nối MongoDB thành công!"))
    .catch(err => console.error("Lỗi kết nối MongoDB:", err));

const User = require("./models/user");

app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/devices", require("./routes/deviceRoutes"));
app.use("/api/fcm-token", require("./routes/fcmRoutes"));
app.use("/api/data", require("./routes/dataRoutes")); 


app.get("/", (req, res) => {
    res.send("🚀 Server IoT Báo Cháy đã sẵn sàng!");
});
const server = http.createServer(app);

// ====================================================
// WebSocket Server
// ====================================================
const wss = new WebSocket.Server({ server });
const clients = new Map();
const previousData = new Map();
const latestSensorDataMap = new Map();
const deviceClients = new Map(); 

function sendAlarmCommandToDevice(deviceId, command) {
    const wsDevice = deviceClients.get(deviceId);
    if (wsDevice && wsDevice.readyState === WebSocket.OPEN) {
        const msg = JSON.stringify({ type: "alarm_command", command, deviceId });
        wsDevice.send(msg);
        console.log("Đã gửi lệnh đến thiết bị");
    } else {
        console.warn(`Không tìm thấy kết nối thiết bị ${deviceId}`);
    }
}

app.post("/api/sensordata", async (req, res) => {
    try {
        const { deviceId, smokeLevel, flame } = req.body;

        if (typeof smokeLevel !== "number" || typeof flame !== "boolean") {
            return res.status(400).json({ message: "Dữ liệu không hợp lệ" });
        }


        const sensorData = { deviceId, smokeLevel, flame, time: new Date() };
        previousData.set(deviceId, sensorData);
        latestSensorDataMap.set(deviceId, sensorData); 
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
        console.error("Lỗi xử lý dữ liệu:", error);
        res.status(500).json({ message: "Lỗi server" });
    }
});



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
                    console.log(`User ${user.userId} đã xác thực WebSocket`);
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
                return;
            }
            if (data.type === "alarm_command") {
                if (!ws.isAuthenticated || !ws.userId) {
                    ws.send(JSON.stringify({ type: "error", message: "Chưa xác thực user" }));
                    return;
                }
                const userDevices = await User.findOne({ userId: ws.userId }).select("devices").lean();
                if (!userDevices || !Array.isArray(userDevices.devices) || !data.deviceId || !userDevices.devices.includes(data.deviceId)) {
                    ws.send(JSON.stringify({ type: "error", message: "Không có quyền truy cập device này" }));
                    return;
                }
                sendAlarmCommandToDevice(data.deviceId, data.command);

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

            const userDevices = await User.findOne({ userId: ws.userId }).select("devices").lean();

            if (!userDevices || !Array.isArray(userDevices.devices) || !data.deviceId || !userDevices.devices.includes(data.deviceId)) {
                console.warn(`User ${ws.userId} không có quyền truy cập deviceId ${data.deviceId}`);
                return;
            }
        } catch (err) {
            console.error("Lỗi xử lý dữ liệu từ client:", err);
        }
    });

    ws.on("close", () => {

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
        console.error(`Lỗi WebSocket: ${err.message}`);
    });
    ws.on("error", (err) => {
        console.error(`Lỗi WebSocket: ${err.message}`);
    });
});



const { handleAlert } = require("./fcm_services/handleAleart2");
const authMiddleware = require("./utils/authMiddleware");

const sendData = async () => {
    const users = await User.find().select("userId devices");

    for (const user of users) {
        for (const deviceId of user.devices) {
            const newData = latestSensorDataMap.get(deviceId);
            if (!newData) continue;
            if (newData.smokeLevel >= 300 || newData.flame === true) {
                await handleAlert(deviceId, newData);
            }
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

        console.log("Đã lưu dữ liệu sensor raw vào MongoDB");
    } catch (err) {
        console.error("Lỗi khi lưu sensor raw:", err);
    }
};
setInterval(saveRawSensorData, 5 * 60 * 1000); 
setInterval(sendData, 5000);
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
   // console.log('hello')
    console.log(`🚀 HTTP Server chạy tại http://localhost:${PORT}`);
    console.log(`📡 WebSocket Server chạy tại ws://localhost:${PORT}`);
});




