const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json()); // Đọc JSON từ request body

// API nhận dữ liệu cảm biến
app.post('/api/sensordata', (req, res) => {
  const { deviceId, temperature, humidity, smokeLevel, flame } = req.body;

  if (!deviceId) {
    return res.status(400).json({ message: 'Thiếu deviceId' });
  }
  console.log(`📥 Dữ liệu từ thiết bị ${deviceId}:`);
  console.log(`🌡 Nhiệt độ: ${temperature}°C`);
  console.log(`💧 Độ ẩm: ${humidity}%`);
  console.log(`💨 Mức khói: ${smokeLevel}`);
  console.log(`🔥 Lửa: ${flame === 1 ? 'Phát hiện' : 'Không'}`);
  console.log('------------------------------------');

  res.status(200).json({ message: 'Dữ liệu đã nhận' });
});
app.listen(PORT, () => {
  console.log(`🚀 Server chạy tại http://localhost:${PORT}`);
});
