const mongoose = require("mongoose");

const { generateId } = require("../models/configs");

const deviceSchema = new mongoose.Schema({
    deviceId: { type: Number, unique: true },
    userId: { type: Number, required: true, ref: "User" }, /*model */
    deviceName: { type: String, required: true },
    location: { type: String, required: true },
    active: { type: Boolean, default: false }
});

// Tạo deviceId trước khi lưu
deviceSchema.pre("save", async function (next) {
    if (!this.deviceId) {
        this.deviceId = await generateId("Device");
    }
    next();
});

// Đặt collection thành "devices"
const Device = mongoose.model("Device", deviceSchema, "devices");
module.exports = Device;

