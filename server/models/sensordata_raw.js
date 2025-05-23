// models/sensorDataRaw.js
const mongoose = require('mongoose');
const sensorDataRawSchema = new mongoose.Schema({
    userId: { type: Number, required: true, ref: "users" },
    deviceId: { type: String, required: true, ref: "devices" },
    temperature: { type: Number, required: true },
    humidity: { type: Number, required: true },
    smokeLevel: { type: Number, required: true },
    flameDetected: { type: Boolean, default: false, required: true },
    timestamp: { type: Date, default: Date.now }
});
module.exports = mongoose.model('SensorDataRaw', sensorDataRawSchema);
