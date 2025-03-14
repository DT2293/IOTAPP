const express = require("express");
const axios = require("axios");
const WebSocket = require("ws");
const cors = require("cors");
require("dotenv").config();

const app = express();
const port = 3000;
const wsPort = 8080;

const BLYNK_TOKEN = "u1Gt11heKkrE9p1mC7KyLJmxOVg4t9E6"; // Thay bằng Token của bạn

app.use(cors());
const mongoose = require('mongoose');
const MONGO_URI = process.env.MONGO_URI;

mongoose.connect(MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => console.log("✅ Kết nối MongoDB thành công!"))
  .catch(err => console.error("❌ Lỗi kết nối MongoDB:", err));

const sensorSchema = new mongoose.Schema({
    deviceId: String,
    temperature: Number,
    humidity: Number,
    smokeLevel: Number,
    timestamp: { type: Date, default: Date.now }
});

const SensorData = mongoose.model('datas', sensorSchema);

// API lấy dữ liệu từ Blynk
app.get("/get-data", async (req, res) => {
    try {
        const temperature = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V2`);
        const humidity = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V1`);
        const smoke = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V3`);

        const data = {
            temperature: parseFloat(temperature.data),
            humidity: parseFloat(humidity.data),
            smoke: parseInt(smoke.data),
        };

        res.json(data);
    } catch (error) {
        res.status(500).json({ error: "Lỗi khi lấy dữ liệu từ Blynk" });
    }
});

// WebSocket Server
const wss = new WebSocket.Server({ port: wsPort });
const clients = new Set(); // Lưu danh sách client đang kết nối
let previousData = null; // Lưu dữ liệu lần trước

// Hàm lấy dữ liệu từ Blynk
const fetchData = async () => {
    try {
        const temperature = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V1`);
        const humidity = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V2`);
        const smoke = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V3`);

        return {
            temperature: parseFloat(temperature.data),
            humidity: parseFloat(humidity.data),
            smoke: parseInt(smoke.data),
            
        };
    } catch (error) {
        console.error("Lỗi khi lấy dữ liệu từ Blynk:", error);
        return null;
    }
};
const sendData = async () => {
    if (clients.size === 0) return; // Không có client thì không cần gửi dữ liệu

    const newData = await fetchData();
    if (!newData) return; // Nếu lỗi khi lấy dữ liệu thì bỏ qua

    if (JSON.stringify(newData) !== JSON.stringify(previousData)) {
        previousData = newData; // Cập nhật dữ liệu mới

        // Lưu dữ liệu vào MongoDB
        const dataToSave = new SensorData({
            deviceId: "ESP32_001", // Thay bằng ID thiết bị thực tế nếu có
            temperature: newData.temperature,
            humidity: newData.humidity,
            smokeLevel: newData.smoke,
            timestamp : newData.timestamp
        });

        try {
            await dataToSave.save();
            console.log("✅ Dữ liệu đã được lưu vào MongoDB");
        } catch (error) {
            console.error("❌ Lỗi khi lưu dữ liệu vào MongoDB:", error);
        }

        // Gửi dữ liệu đến tất cả client
        for (const client of clients) {
            client.send(JSON.stringify(newData));
        }
    }
};


// Lặp lại việc gửi dữ liệu mỗi 2 giây
const interval = setInterval(sendData, 2000);

wss.on("connection", (ws) => {
    console.log("⚡ Client kết nối WebSocket");
    clients.add(ws);

    ws.on("close", () => {
        console.log("⚡ Client ngắt kết nối");
        clients.delete(ws);
    });
});
app.listen(port, () => {
    console.log(`🚀 Server chạy tại http://localhost:${port}`);
    console.log(`📡 WebSocket chạy trên ws://localhost:${wsPort}`);
});

 