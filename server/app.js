// const express = require("express");
// const http = require("http");
// const WebSocket = require("ws");
// const cors = require("cors");
// const mongoose = require("mongoose");
// const jwt = require("jsonwebtoken");
// require("dotenv").config();

// // Khởi tạo Express app
// const app = express();
// app.use(express.json());
// app.use(cors());

// // Kết nối MongoDB
// mongoose.connect(process.env.MONGO_URI, {
//     useNewUrlParser: true,
//     useUnifiedTopology: true,
// }).then(() => console.log("✅ Kết nối MongoDB thành công!"))
//   .catch(err => console.error("❌ Lỗi kết nối MongoDB:", err));

// // Routes API
// app.use("/api/auth", require("./routes/authRoutes"));
// app.use("/api/devices", require("./routes/deviceRoutes"));

// app.get("/", (req, res) => {
//     res.send("🚀 Server IoT Báo Cháy đã sẵn sàng!");
// });

// // Tạo HTTP Server
// const server = http.createServer(app);

// // 🔥 WebSocket Server
// const wss = new WebSocket.Server({ server });
// const clients = new Map();

// wss.on("connection", (ws) => {
//     console.log("⚡ Client kết nối WebSocket");

//     ws.on("message", async (message) => {
//         try {
//             const data = JSON.parse(message);
//             console.log("📩 Nhận được message:", data);
    
//             if (data.type === "authenticate") {
//                 console.log("🔑 Token nhận được:", data.token);
    
//                 // Giải mã token
//                 const decoded = jwt.verify(data.token, process.env.JWT_SECRET);
//                 console.log("✅ Token hợp lệ:", decoded);
    
//                 ws.userId = decoded.userId;  // Đúng với payload của token
//                 ws.isAuthenticated = true;
    
//                 if (!clients.has(ws.userId)) {
//                     clients.set(ws.userId, new Set());
//                 }
//                 clients.get(ws.userId).add(ws);
    
//                 ws.send(JSON.stringify({ type: "auth_success", message: "Xác thực thành công!" }));
//             }
//         } catch (err) {
//             console.error("❌ Lỗi xác thực WebSocket:", err.message);
//             ws.send(JSON.stringify({ type: "auth_error", message: err.message })); // Gửi lỗi chi tiết về client
//         }
//     });
    

//     ws.on("close", () => {
//         console.log(`🔴 User ${ws.userId || "chưa xác thực"} ngắt kết nối`);
//         if (ws.userId && clients.has(ws.userId)) {
//             clients.get(ws.userId).delete(ws);
//             if (clients.get(ws.userId).size === 0) {
//                 clients.delete(ws.userId);
//             }
//         }
//     });
// });

// // Khởi động HTTP + WebSocket Server
// const PORT = process.env.PORT || 3000;
// server.listen(PORT, () => {
//     console.log(`🚀 HTTP Server chạy tại http://localhost:${PORT}`);
//     console.log(`📡 WebSocket Server chạy tại ws://localhost:${PORT}`);
// });


const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const cors = require("cors");
const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const axios = require("axios");
require("dotenv").config();

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
            console.warn(`⚠️ Dữ liệu không hợp lệ từ ${deviceId}:`, data);
            return null;
        }

        return data;
    } catch (error) {
        console.error(`❌ Lỗi lấy dữ liệu từ Blynk (${deviceId}):`, error.message);
        return null;
    }
};

// Xử lý kết nối WebSocket
wss.on("connection", async (ws) => {
    console.log("⚡ Một client vừa kết nối, chờ xác thực...");

    ws.isAuthenticated = false;

    // Xử lý message từ client
    ws.on("message", async (message) => {
        try {
            const data = JSON.parse(message);

            //Nếu client gửi token để xác thực
            if (data.type === "authenticate") {
                try {
                    const decoded = jwt.verify(data.token, process.env.JWT_SECRET);
                    const user = await User.findById(decoded.userId).select("-password");

                    if (!user) {
                        console.error("❌ User không hợp lệ");
                        ws.send(JSON.stringify({ type: "auth_error", message: "User không hợp lệ!" }));
                        ws.close();
                        return;
                    }

                    console.log(`✅ User ${user.id} đã xác thực WebSocket`);
                    ws.userId = user.id;
                    ws.isAuthenticated = true;

                    // 🔹 Lưu WebSocket theo userId
                    if (!clients.has(user.id)) {
                        clients.set(user.id, new Set());
                    }
                    clients.get(user.id).add(ws);

                    ws.send(JSON.stringify({ type: "auth_success", message: "Xác thực thành công!" }));
                } catch (err) {
                    console.error("❌ Token không hợp lệ:", err.message);
                    ws.send(JSON.stringify({ type: "auth_error", message: "Token không hợp lệ!" }));
                    ws.close();
                }
                return;
            }

            // Chặn tin nhắn nếu user chưa xác thực
            if (!ws.isAuthenticated) {
                ws.send(JSON.stringify({ type: "auth_error", message: "Bạn chưa xác thực!" }));
                return;
            }

            const userDevices = await User.findById(ws.userId).select("devices").lean();
            if (!userDevices || !userDevices.devices.includes(data.deviceId)) {
                console.warn(`⚠️ User ${ws.userId} không có quyền truy cập deviceId ${data.deviceId}`);
                return;
            }

            // if (data.action === "toggleRelay") {
            //     console.log(`🔁 Điều khiển relay trên ${data.deviceId}: ${data.state}`);
            //     await axios.get(`https://blynk.cloud/external/api/update?token=${BLYNK_TOKEN}&pin=V0&value=${data.state === "on" ? 1 : 0}`);
            // }

            if (data.action === "toggleRelay") {
                console.log(`🔁 Điều khiển relay trên ${data.deviceId}: ${data.state}`);
                try {
                    await axios.get(`https://blynk.cloud/external/api/update?token=${BLYNK_TOKEN}&pin=V0&value=${data.state === "on" ? 1 : 0}`);
                    // Gửi phản hồi sau khi điều khiển relay thành công
                    ws.send(JSON.stringify({
                      //  type: "relayStatus",
                        deviceId: data.deviceId,
                      //  state: data.state,
                        message: `Relay đã được ${data.state === "on" ? "bật" : "tắt"}!`
                    }));
                } catch (error) {
                    console.error("❌ Lỗi điều khiển relay:", error.message);
                    ws.send(JSON.stringify({
                        type: "relayError",
                        message: "Không thể điều khiển relay!"
                    }));
                }
            }
            
        } catch (err) {
            console.error("❌ Lỗi xử lý dữ liệu từ client:", err);
        }
    });

    // Khi client ngắt kết nối
    ws.on("close", () => {
        console.log(`⚡ User ${ws.userId || "chưa xác thực"} ngắt kết nối`);
        if (ws.userId && clients.has(ws.userId)) {
            clients.get(ws.userId).delete(ws);
            if (clients.get(ws.userId).size === 0) {
                clients.delete(ws.userId);
            }
        }
    });

    // Xử lý lỗi WebSocket
    ws.on("error", (err) => {
        console.error(`❌ Lỗi WebSocket: ${err.message}`);
    });
});

// Gửi dữ liệu định kỳ mỗi 2 giây
const sendData = async () => {
    for (const [userId, userClients] of clients.entries()) {
        const userDevices = await User.findById(userId).select("devices").lean();
        if (!userDevices) continue;

        for (const deviceId of userDevices.devices) {
            const newData = await fetchData(deviceId);
            if (!newData) continue;

            // 🔹 Chỉ gửi nếu dữ liệu thay đổi
            if (JSON.stringify(newData) !== JSON.stringify(previousData.get(deviceId))) {
                previousData.set(deviceId, newData);
                for (const client of userClients) {
                    client.send(JSON.stringify({ type: "sensordatas", data: newData }));
                }
            }
        }
    }
};

// Chạy sendData mỗi 2 giây
setInterval(sendData, 2000);

// 🚀 Khởi động HTTP + WebSocket Server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`🚀 HTTP Server chạy tại http://localhost:${PORT}`);
    console.log(`📡 WebSocket Server chạy tại ws://localhost:${PORT}`);
});
