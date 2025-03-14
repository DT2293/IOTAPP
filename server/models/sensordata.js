const mongoose = require("mongoose");
const sensorDataSchema = new mongoose.Schema({
    deviceId: { type: mongoose.Schema.Types.ObjectId, ref: "Device" }, // Tham chiếu đến device
    temperature: Number,
    humidity: Number,
    smokeLevel: Number,
    timestamp: { type: Date, default: Date.now }
});

const SensorData = mongoose.model("SensorData", sensorDataSchema);
module.exports = SensorData;
