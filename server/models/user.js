// const mongoose = require("mongoose");

// const userSchema = new mongoose.Schema({
//     username: { type: String, required: true },
//     email: { type: String, required: true, unique: true },
//     password: { type: String, required: true },
//     devices: [{ type: mongoose.Schema.Types.ObjectId, ref: "Device" }] // Dùng ObjectId để tham chiếu đến Device
// });

// const User = mongoose.model("users", userSchema);
// module.exports = User;

const mongoose = require("mongoose");
const { v4: uuidv4 } = require("uuid");

const userSchema = new mongoose.Schema({
    userId: { type: String, required: true, unique: true, default: () => uuidv4() },  // Sinh ngẫu nhiên
    username: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    devices: [{ type: String, ref: "devices" }]  // Tham chiếu deviceId dạng String (địa chỉ MAC)
});

const User = mongoose.model("users", userSchema);
module.exports = User;
