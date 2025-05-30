const mongoose = require("mongoose");

const sensorDataSchema = new mongoose.Schema({
    deviceId: String,
    averageTemperature: Number,
    averageHumidity: Number,
    averageSmokeLevel: Number,
    flameDetected: Boolean,
    date: Date 
});
const SensorData = mongoose.model("SensorData", sensorDataSchema, "sensordatas");
module.exports = SensorData;

