const mongoose = require("mongoose");

const configSchema = new mongoose.Schema({
    _id: { type: String, default: "global_counter" },
    count: { type: Number, required: true }
});

const Config = mongoose.model("configs", configSchema);

// ✅ Hàm tạo ID với kiểm tra và khởi tạo nếu chưa tồn tại
async function generateId() {
    let result = await Config.findOne({ _id: "global_counter" });

    if (!result) {
        console.log("Initializing global counter..."); // 🛠 Debug
        result = await Config.create({ _id: "global_counter", count: 0 });
    }

    result = await Config.findOneAndUpdate(
        { _id: "global_counter" },
        { $inc: { count: 1 } },
        { new: true }
    );

    console.log(`Generated ID:`, result.count); // 🛠 Debug
    return result.count;
}

module.exports = { generateId };
