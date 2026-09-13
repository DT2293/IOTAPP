const mongoose = require("mongoose");
const { generateId } = require("./configs");

const userSchema = new mongoose.Schema({
  userId: { type: Number, unique: true },
  username: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phonenumber: [{ type: String, required: true }],
  password: { type: String, required: true },
  devices: [{ type: String, ref: "Device" }],
  fcmToken: [{ type: String }],
  language: { type: String, enum: ["vi", "en"], default: "vi" },
});

userSchema.pre("save", async function (next) {
  if (!this.userId || typeof this.userId !== "number") {
    this.userId = await generateId("User");
  }
  next();
});

module.exports = mongoose.model("User", userSchema);
