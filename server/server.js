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
app.post("/api/sensordata", async (req, res) => {
  try {
    const { deviceId,smokeLevel, flame } = req.body;

    // Kiểm tra dữ liệu hợp lệ
    if (
      typeof smokeLevel !== "number" ||
      typeof flame !== "boolean"
    ) {
      return res.status(400).json({ message: "Dữ liệu không hợp lệ" });
    }

    // Log dữ liệu
    console.log(`📥 Dữ liệu từ thiết bị ${deviceId}:`);
    console.log(`💨 Mức khói: ${smokeLevel}`);
    console.log(`🔥 Lửa: ${flame ? "Có" : "Không"}`);
    console.log("------------------------------------");

    // Lưu data vào biến previousData hoặc DB
    previousData.set(deviceId, { deviceId, smokeLevel, flame, time: new Date() });

    // Gửi realtime cho tất cả user có quyền deviceId
    const users = await User.find({ devices: deviceId }).select("userId devices");

    for (const user of users) {
      const userClients = clients.get(user.userId);
      if (userClients) {
        for (const ws of userClients) {
          if (ws.readyState === ws.OPEN) {
            ws.send(JSON.stringify({ type: "sensordatas", data: previousData.get(deviceId) }));
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
// Xử lý kết nối WebSocket
wss.on("connection", async (ws) => {
    console.log("⚡ Một client vừa kết nối, chờ xác thực...");

    ws.isAuthenticated = false;

    ws.on("message", async (message) => {
        try {
            const data = JSON.parse(message);

            if (data.type === "authenticate") {
                try {
                    const decoded = jwt.verify(data.token, process.env.JWT_SECRET);

                    // Chuyển decoded.userId thành Number khi tìm kiếm
                    const user = await User.findOne({ userId: Number(decoded.userId) }).select("-password");

                    if (!user) {
                        console.error("❌ User không hợp lệ");
                        ws.send(JSON.stringify({ type: "auth_error", message: "User không hợp lệ!" }));
                        ws.close();
                        return;
                    }

                    console.log(`✅ User ${user.userId} đã xác thực WebSocket`);
                    ws.userId = user.userId;
                    ws.isAuthenticated = true;

                    // Lưu WebSocket theo userId
                    if (!clients.has(user.userId)) {
                        clients.set(user.userId, new Set());
                    }
                    clients.get(user.userId).add(ws);

                    ws.send(JSON.stringify({ type: "auth_success", message: "Xác thực thành công!" }));
                } catch (err) {
                    console.error("❌ Token không hợp lệ:", err.message);
                    ws.send(JSON.stringify({ type: "auth_error", message: "Token không hợp lệ!" }));
                    ws.close();
                }
                return;
            }

            if (!ws.isAuthenticated) {
                ws.send(JSON.stringify({ type: "auth_error", message: "Bạn chưa xác thực!" }));
                return;
            }

            // Kiểm tra quyền truy cập của người dùng đối với deviceId
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

const { handleAlert } = require("./fcm_services/handleAleart2");

// Gửi dữ liệu định kỳ mỗi 2 giây
const sendData = async () => {
    const users = await User.find().select("userId devices");
  
    for (const user of users) {
      for (const deviceId of user.devices) {
        const newData = await fetchData(deviceId);
        if (!newData) continue;
  
        if (JSON.stringify(newData) !== JSON.stringify(previousData.get(deviceId))) {
  
          // 🔥 Gửi cảnh báo nếu nhiệt độ vượt ngưỡng
          if (newData.smokeLevel >= 300 || newData.flame) {
            await handleAlert(deviceId, newData);
          }
  
          previousData.set(deviceId, newData);
  
          // 🔁 Nếu user đang kết nối WebSocket, gửi thêm dữ liệu real-time
          const userClients = clients.get(user.userId);
          if (userClients) {
            for (const client of userClients) {
              client.send(JSON.stringify({ type: "sensordatas", data: newData }));
            }
          }
        }
      }
    }
  };
  
setInterval(sendData, 2000);
// 🚀 Khởi động HTTP + WebSocket Server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log('hello')
    console.log(`🚀 HTTP Server chạy tại http://localhost:${PORT}`);
    console.log(`📡 WebSocket Server chạy tại ws://localhost:${PORT}`);
});