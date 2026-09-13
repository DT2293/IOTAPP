const cron = require("node-cron");
const SensorDataRaw = require("../models/sensordata_raw");
const SensorData = require("../models/sensordata");

async function calculateDailyAverage() {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const start = new Date(yesterday.setHours(0, 0, 0, 0));
  const end = new Date(yesterday.setHours(23, 59, 59, 999));

  const deviceIds = await SensorDataRaw.distinct("deviceId", {
    timestamp: { $gte: start, $lte: end },
  });

  for (const deviceId of deviceIds) {
    const records = await SensorDataRaw.find({
      deviceId,
      timestamp: { $gte: start, $lte: end },
    });

    if (!records.length) continue;

    const total = records.reduce(
      (acc, r) => {
        acc.temp += r.temperature;
        acc.hum += r.humidity;
        acc.smoke += r.smokeLevel;
        if (r.flameDetected) acc.flame = true;
        return acc;
      },
      { temp: 0, hum: 0, smoke: 0, flame: false },
    );

    await SensorData.create({
      deviceId,
      averageTemperature: total.temp / records.length,
      averageHumidity: total.hum / records.length,
      averageSmokeLevel: total.smoke / records.length,
      flameDetected: total.flame,
      date: start,
    });
  }
}

async function deleteOldRawData() {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 30);
  await SensorDataRaw.deleteMany({ timestamp: { $lt: cutoff } });
}

cron.schedule("5 0 * * *", async () => {
  await calculateDailyAverage();
  await deleteOldRawData();
});
