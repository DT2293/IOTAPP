const mongoose = require('mongoose');
const SensorData = require("./models/sensordata");


//const SensorData = mongoose.model('SensorData', sensorDataSchema);

mongoose.connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
}).then(() => console.log("✅ Kết nối MongoDB thành công!"))
  .catch(err => console.error("❌ Lỗi kết nối MongoDB:", err));

function randomDate(start, end) {
    return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
}

function generateRecords(deviceId, userId, count, flameCount) {
    const records = [];
    const startDate = new Date('2025-05-01');

    for (let i = 0; i < count; i++) {
        const date = new Date(startDate);
        date.setDate(date.getDate() + i); // Tăng từng ngày

        const hasFlame = i < flameCount;
        const data = {
            userId,
            deviceId,
            averageTemperature: 20 + Math.random() * 15, // 20–35 °C
            averageHumidity: 40 + Math.random() * 30,     // 40–70 %
            averageSmokeLevel: Math.floor(100 + Math.random() * 150), // 100–250
            flameDetected: hasFlame,
            date: date
        };
        records.push(data);
    }

    return records;
}


async function run() {
    try {
        await mongoose.connect(uri, { useNewUrlParser: true, useUnifiedTopology: true });

        const records = [
            ...generateRecords('24:0A:C4:00:01:10', 1, 22, 2), 
            ...generateRecords('40:22:D8:05:1B:88', 2, 22, 3), 
        ];

        await SensorData.insertMany(records);
        console.log('✅  Bản ghi đã được lưu vào MongoDB.');
    } catch (error) {
        console.error('❌ Lỗi:', error);
    } finally {
        await mongoose.disconnect();
    }
}

run();
