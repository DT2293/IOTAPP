const mongoose = require("mongoose");
const { generateId } = require("../models/configs");

const userSchema = new mongoose.Schema({
    userId: { type: Number, unique: true },  // 🔹 Đảm bảo là Number
    username: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    devices: [{ type: Number, ref: "devices" }]
});

// ✅ Kiểm tra kỹ lưỡng userId
userSchema.pre("save", async function (next) {
    if (!this.userId || typeof this.userId !== "number") {
        const newId = await generateId();
        this.userId = newId;
    }
    next();
});

const User = mongoose.model("User", userSchema, "users");
module.exports = User;
