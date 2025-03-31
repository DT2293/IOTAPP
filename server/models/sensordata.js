
const mongoose = require("mongoose");

const sensorDataSchema = new mongoose.Schema({
    userId: { type: Number, required: true, ref: "users" },
    deviceId: { type: Number, required: true, ref: "devices" },
    temperature: { type: Number, required: true },
    humidity: { type: Number, required: true },
    smokeLevel: { type: Number, required: true },
    timestamp: { type: Date, default: Date.now }
});

// Đặt collection thành "sensordatas"
const SensorData = mongoose.model("SensorData", sensorDataSchema, "sensordatas");
module.exports = SensorData;

