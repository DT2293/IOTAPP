
// const mongoose = require("mongoose");
// const { generateId } = require("../models/configs");

// const userSchema = new mongoose.Schema({
//     userId: { type: Number, unique: true },  
//     username: { type: String, required: true },
//     email: { type: String, required: true, unique: true },
//     password: { type: String, required: true },
//     devices: [{ type: String, ref: "devices" }]// Đổi kiểu thành String để phù hợp với deviceId từ Blynk
// });

// // ✅ Kiểm tra kỹ lưỡng userId
// userSchema.pre("save", async function (next) {
//     if (!this.userId || typeof this.userId !== "number") {
//         const newId = await generateId();
//         this.userId = newId;
//     }
//     next();
// });

// const User = mongoose.model("User", userSchema);
// module.exports = User;


const mongoose = require("mongoose");
const { generateId } = require("../models/configs");

const userSchema = new mongoose.Schema({
    userId: { type: Number, unique: true },
    username: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    phonenumber: [{type: String, require: true}],
    password: { type: String, required: true },
    devices: [{ type: String, ref: "devices" }], 
    fcmToken: [{ type: String }],
    language: { type: String, enum: ["vi", "en"], default: "vi" }, 
});

// ✅ Kiểm tra kỹ lưỡng userId
userSchema.pre("save", async function (next) {
    if (!this.userId || typeof this.userId !== "number") {
        const newId = await generateId();
        this.userId = newId;
    }
    next();
});

const User = mongoose.model("User", userSchema);
module.exports = User;
