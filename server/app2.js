const mongoose = require('mongoose');

const sensorDataSchema = new mongoose.Schema({
    userId: { type: Number, required: true },
    deviceId: { type: String, required: true },
    temperature: { type: Number, required: true },
    humidity: { type: Number, required: true },
    smokeLevel: { type: Number, required: true },
    flameDetected: { type: Boolean, default: false, required: true },
    timestamp: { type: Date, default: Date.now }
});

const SensorData = mongoose.model('SensorData', sensorDataSchema);

const uri = 'mongodb://localhost:27017/iotdb'; // Thay bằng URI thật nếu cần

function randomDate(start, end) {
    return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
}

function generateRecords(deviceId, userId, count, flameCount) {
    const records = [];
    const startDate = new Date('2025-04-01');
    const endDate = new Date('2025-05-23');

    for (let i = 0; i < count; i++) {
        const hasFlame = i < flameCount;
        const data = {
            userId,
            deviceId,
            temperature: 20 + Math.random() * 15, // 20–35 °C
            humidity: 40 + Math.random() * 30, // 40–70 %
            smokeLevel: Math.floor(100 + Math.random() * 150), // 100–250
            flameDetected: hasFlame,
            timestamp: randomDate(startDate, endDate)
        };
        records.push(data);
    }

    return records;
}

async function run() {
    try {
        await mongoose.connect(uri, { useNewUrlParser: true, useUnifiedTopology: true });

        const records = [
            ...generateRecords('24:0A:C4:00:01:10', 1, 15, 2), // 15 bản ghi, 2 có cháy
            ...generateRecords('40:22:D8:05:1B:88', 2, 35, 3), // 35 bản ghi, 3 có cháy
        ];

        await SensorData.insertMany(records);
        console.log('✅ 50 bản ghi đã được lưu vào MongoDB.');
    } catch (error) {
        console.error('❌ Lỗi:', error);
    } finally {
        await mongoose.disconnect();
    }
}

run();
