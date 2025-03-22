// const mongoose = require("mongoose");
// const sensorDataSchema = new mongoose.Schema({
//     deviceId: { type: mongoose.Schema.Types.ObjectId, ref: "Device" }, // Tham chiếu đến device
//     temperature: Number,
//     humidity: Number,
//     smokeLevel: Number,
//     timestamp: { type: Date, default: Date.now }
// });

// const SensorData = mongoose.model("SensorData", sensorDataSchema);
// module.exports = SensorData;


const mongoose = require("mongoose");
const { v4: uuidv4 } = require("uuid");

const sensorDataSchema = new mongoose.Schema({
    sensorId: { type: String, required: true, unique: true, default: () => uuidv4() },  // Sinh ngẫu nhiên
    deviceId: { type: String, required: true },  // Địa chỉ MAC
    temperature: Number,
    humidity: Number,
    smokeLevel: Number,
    timestamp: { type: Date, default: Date.now }
});

const SensorData = mongoose.model("sensordatas", sensorDataSchema);
module.exports = SensorData;
