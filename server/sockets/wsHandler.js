const WebSocket = require("ws");
const jwt = require("jsonwebtoken");
const User = require("../models/user");
const store = require("../store/memoryStore");

function sendAlarmCommandToDevice(deviceId, command) {
  const wsDevice = store.deviceClients.get(deviceId);
  if (wsDevice && wsDevice.readyState === WebSocket.OPEN) {
    const msg = JSON.stringify({ type: "alarm_command", command, deviceId });
    wsDevice.send(msg);
  } else {
    console.warn(`Không tìm thấy kết nối thiết bị ${deviceId}`);
  }
}

const initWebSocket = (server) => {
  const wss = new WebSocket.Server({ server });

  wss.on("connection", async (ws) => {
    ws.isAuthenticated = false;

    ws.on("message", async (message) => {
      try {
        const data = JSON.parse(message);

        if (data.type === "authenticate") {
          try {
            const decoded = jwt.verify(data.token, process.env.JWT_SECRET);
            const user = await User.findOne({
              userId: Number(decoded.userId),
            }).select("-password");

            if (!user) {
              ws.send(
                JSON.stringify({
                  type: "auth_error",
                  message: "User không hợp lệ!",
                }),
              );
              ws.close();
              return;
            }
            ws.userId = user.userId;
            ws.isAuthenticated = true;

            if (!store.clients.has(user.userId)) {
              store.clients.set(user.userId, new Set());
            }
            store.clients.get(user.userId).add(ws);

            ws.send(
              JSON.stringify({
                type: "auth_success",
                message: "Xác thực thành công!",
              }),
            );
            ws.send(
              JSON.stringify({ type: "alarm_command", command: "alarm_on" }),
            );
          } catch (err) {
            ws.send(
              JSON.stringify({
                type: "auth_error",
                message: "Token không hợp lệ!",
              }),
            );
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
            store.deviceClients.set(deviceId, ws);
            console.log(
              `Thiết bị ${deviceId} đã kết nối WebSocket không cần JWT`,
            );
            ws.send(
              JSON.stringify({
                type: "auth_success",
                message: "Thiết bị xác thực thành công",
              }),
            );
          } else {
            ws.send(
              JSON.stringify({
                type: "auth_error",
                message: "deviceId không hợp lệ",
              }),
            );
            ws.close();
          }
          return;
        }

        if (data.type === "alarm_command") {
          if (!ws.isAuthenticated || !ws.userId) {
            ws.send(
              JSON.stringify({ type: "error", message: "Chưa xác thực user" }),
            );
            return;
          }
          const userDevices = await User.findOne({ userId: ws.userId })
            .select("devices")
            .lean();
          if (
            !userDevices ||
            !Array.isArray(userDevices.devices) ||
            !data.deviceId ||
            !userDevices.devices.includes(data.deviceId)
          ) {
            ws.send(
              JSON.stringify({
                type: "error",
                message: "Không có quyền truy cập device này",
              }),
            );
            return;
          }

          sendAlarmCommandToDevice(data.deviceId, data.command);
          ws.send(
            JSON.stringify({
              type: "alarm_command_ack",
              message: `Lệnh ${data.command} đã được gửi tới thiết bị ${data.deviceId}`,
            }),
          );
          return;
        }

        if (!ws.isAuthenticated) {
          ws.send(
            JSON.stringify({
              type: "auth_error",
              message: "Bạn chưa xác thực!",
            }),
          );
          return;
        }
      } catch (err) {
        console.error("Lỗi xử lý dữ liệu từ client:", err);
      }
    });

    ws.on("close", () => {
      if (ws.userId && store.clients.has(ws.userId)) {
        store.clients.get(ws.userId).delete(ws);
        if (store.clients.get(ws.userId).size === 0) {
          store.clients.delete(ws.userId);
        }
      }
      if (ws.isDevice && ws.deviceId && store.deviceClients.has(ws.deviceId)) {
        store.deviceClients.delete(ws.deviceId);
      }
    });

    ws.on("error", (err) => console.error(`Lỗi WebSocket: ${err.message}`));
  });
};

module.exports = initWebSocket;
