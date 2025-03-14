// const mongoose = require("mongoose");
// const User = require("../models/user"); // Đường dẫn đúng tới User model


// const deviceSchema = new mongoose.Schema({
//     userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true }, // Tham chiếu đến User
//     deviceName: { type: String, required: true },
//     location: { type: String, required: true },
//     active: { type: Boolean, default: false } 
// });

// // Middleware: Ép kiểu `active` thành Boolean trước khi lưu
// deviceSchema.pre("save", function (next) {
//     this.active = Boolean(this.active);
//     next();
// });

// const Device = mongoose.model("Device", deviceSchema);
// module.exports = Device;

const mongoose = require("mongoose");
const User = require("../models/user");
const deviceSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "users", required: true }, // Tham chiếu đúng bảng users
    deviceName: { type: String, required: true },
    location: { type: String, required: true },
    active: { type: Boolean, default: false }
});

// Middleware: Ép kiểu `active` thành Boolean trước khi lưu
deviceSchema.pre("save", function (next) {
    this.active = Boolean(this.active);
    next();
});

const Device = mongoose.model("devices", deviceSchema); // Đúng với tên bảng trong MongoDB
module.exports = Device;
