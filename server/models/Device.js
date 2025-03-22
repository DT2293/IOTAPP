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

// const mongoose = require("mongoose");
// const User = require("../models/user");
// const deviceSchema = new mongoose.Schema({
//     userId: { type: mongoose.Schema.Types.ObjectId, ref: "users", required: true }, // Tham chiếu đúng bảng users
//     deviceName: { type: String, required: true },
//     location: { type: String, required: true },
//     active: { type: Boolean, default: false }
// });

// // Middleware: Ép kiểu `active` thành Boolean trước khi lưu
// deviceSchema.pre("save", function (next) {
//     this.active = Boolean(this.active);
//     next();
// });

// const Device = mongoose.model("devices", deviceSchema); // Đúng với tên bảng trong MongoDB
// module.exports = Device;
const mongoose = require("mongoose");
const { v4: uuidv4 } = require("uuid");

const deviceSchema = new mongoose.Schema({
    deviceId: { type: String, required: true, unique: true },  // Địa chỉ MAC
    userId: { type: String, required: true },  // Tham chiếu userId dạng String
    deviceName: { type: String, required: true },
    location: { type: String, required: true },
    active: { type: Boolean, default: false }
});

// Sinh ID ngẫu nhiên nếu thiếu deviceId (trường hợp kiểm tra trước khi post)
deviceSchema.pre("save", function (next) {
    this.deviceId = this.deviceId || uuidv4();
    next();
});

const Device = mongoose.model("devices", deviceSchema);
module.exports = Device;
