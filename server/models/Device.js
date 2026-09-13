const mongoose = require("mongoose");

const deviceSchema = new mongoose.Schema({
  deviceId: { type: String, unique: true, required: true },
  userId: { type: Number, required: true, ref: "User" },
  deviceName: { type: String, required: true },
  location: { type: String, required: true },
  active: { type: Boolean, default: false },
});

module.exports = mongoose.model("Device", deviceSchema, "devices");
