const cron = require('node-cron');
const SensorDataRaw = require('../models/sensordata_raw');
const SensorData = require('../models/sensordata');

// Hàm tính trung bình dữ liệu theo deviceId và ngày
async function calculateDailyAverage() {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const start = new Date(yesterday.setHours(0, 0, 0, 0));
    const end = new Date(yesterday.setHours(23, 59, 59, 999));

    // Lấy tất cả deviceId hôm qua
    const deviceIds = await SensorDataRaw.distinct('deviceId', {
        timestamp: { $gte: start, $lte: end }
    });

    for (const deviceId of deviceIds) {
        const records = await SensorDataRaw.find({
            deviceId,
            timestamp: { $gte: start, $lte: end }
        });

        if (records.length === 0) continue;

        // Tính trung bình
        const avgTemp = records.reduce((acc, r) => acc + r.temperature, 0) / records.length;
        const avgHumid = records.reduce((acc, r) => acc + r.humidity, 0) / records.length;
        const avgSmoke = records.reduce((acc, r) => acc + r.smokeLevel, 0) / records.length;
        const flameDetected = records.some(r => r.flameDetected === true);

        // Lưu trung bình vào bảng hàng ngày
        await SensorData.create({
            deviceId,
            averageTemperature: avgTemp,
            averageHumidity: avgHumid,
            averageSmokeLevel: avgSmoke,
            flameDetected,
            date: start
        });
    }
}

// Xóa dữ liệu cũ hơn 30 ngày
async function deleteOldRawData() {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 30);
    await SensorDataRaw.deleteMany({ timestamp: { $lt: cutoff } });
}

// Lên lịch chạy lúc 00:05 mỗi ngày
cron.schedule('5 0 * * *', async () => {
    console.log("⏰ Bắt đầu tính trung bình dữ liệu ngày hôm qua và xóa dữ liệu cũ...");
    await calculateDailyAverage();
    await deleteOldRawData();
    console.log("✅ Hoàn thành công việc định kỳ.");
});
