// const express = require("express");
// const axios = require("axios");
// const WebSocket = require("ws");
// const cors = require("cors");

// const app = express();
// const port = 3000;
// const BLYNK_TOKEN = "u1Gt11heKkrE9p1mC7KyLJmxOVg4t9E6"; // Thay bằng Token thật

// app.use(cors()); // Cho phép gọi API từ Flutter

// // API lấy dữ liệu từ Blynk
// app.get("/get-data", async (req, res) => {
//     try {
//         const temperature = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V2`);
//         const humidity = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V1`);
//         const smoke = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V3`);

//         const data = {
//             temperature: parseFloat(temperature.data),
//             humidity: parseFloat(humidity.data),
//             smoke: parseInt(smoke.data),
//         };

//         res.json(data);
//     } catch (error) {
//         res.status(500).json({ error: "Lỗi khi lấy dữ liệu từ Blynk" });
//     }
// });

// // WebSocket Server để gửi dữ liệu real-time
// const wss = new WebSocket.Server({ port: 8080 });

// wss.on("connection", (ws) => {
//     console.log("⚡ Client kết nối WebSocket");

//     const sendData = async () => {
//         try {
//             const temperature = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V1`);
//             const humidity = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V2`);
//             const smoke = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V3`);

//             const data = {
//                 temperature: parseFloat(temperature.data),
//                 humidity: parseFloat(humidity.data),
//                 smoke: parseInt(smoke.data),
//             };

//             ws.send(JSON.stringify(data)); // Gửi dữ liệu real-time đến Flutter
//         } catch (error) {
//             console.error("Lỗi khi lấy dữ liệu từ Blynk:", error);
//         }
//     };

//     sendData();
//     const interval = setInterval(sendData, 5000); // Gửi dữ liệu mỗi 5s

//     ws.on("close", () => {
//         console.log("⚡ Client ngắt kết nối");
//         clearInterval(interval);
//     });
// });

// app.listen(port, () => {
//     console.log(`🚀 Server chạy tại http://localhost:${port}`);
// });

const express = require("express");
const axios = require("axios");
const WebSocket = require("ws");
const cors = require("cors");

const app = express();
const port = 3000;
const wsPort = 8080;

const BLYNK_TOKEN = "u1Gt11heKkrE9p1mC7KyLJmxOVg4t9E6"; // Thay bằng Token của bạn

app.use(cors());

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

wss.on("connection", (ws) => {
    console.log("⚡ Client kết nối WebSocket");

    const sendData = async () => {
        try {
            const temperature = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V1`);
            const humidity = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V2`);
            const smoke = await axios.get(`https://blynk.cloud/external/api/get?token=${BLYNK_TOKEN}&pin=V3`);

            const data = {
                temperature: parseFloat(temperature.data),
                humidity: parseFloat(humidity.data),
                smoke: parseInt(smoke.data),
            };

            ws.send(JSON.stringify(data)); // Gửi dữ liệu real-time đến Flutter
        } catch (error) {
            console.error("Lỗi khi lấy dữ liệu từ Blynk:", error);
        }
    };

    sendData();
    const interval = setInterval(sendData, 2000); // Gửi dữ liệu mỗi 5s

    ws.on("close", () => {
        console.log("⚡ Client ngắt kết nối");
        clearInterval(interval);
    });
});

// Khởi động server Express
app.listen(port, () => {
    console.log(`🚀 Server chạy tại http://localhost:${port}`);
    console.log(`📡 WebSocket chạy trên ws://localhost:${wsPort}`);
});
