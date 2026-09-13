const express = require("express");
const http = require("http");
const cors = require("cors");
require("dotenv").config();
require("./utils/dailydata");

const connectDB = require("./config/db");
const apiRoutes = require("./routes");
const initWebSocket = require("./sockets/wsHandler");
const startJobs = require("./jobs/scheduler");

const app = express();
app.use(express.json());
app.use(cors());

connectDB();

app.use("/api", apiRoutes);
app.get("/", (req, res) => {
  res.send("🚀 Server IoT Báo Cháy đã sẵn sàng!");
});

const server = http.createServer(app);

initWebSocket(server);
startJobs();

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 HTTP Server chạy tại http://localhost:${PORT}`);
  console.log(`📡 WebSocket Server chạy tại ws://localhost:${PORT}`);
});
