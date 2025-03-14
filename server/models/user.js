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

const userSchema = new mongoose.Schema({
    username: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    devices: [{ type: mongoose.Schema.Types.ObjectId, ref: "devices" }] // Tham chiếu đúng bảng devices
});

const User = mongoose.model("users", userSchema); // Phải khớp với bảng trong MongoDB
module.exports = User;
