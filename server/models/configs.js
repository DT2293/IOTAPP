const mongoose = require("mongoose");

const configSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    count: { type: Number, required: true }
});

const Config = mongoose.model("configs", configSchema);

async function generateId(modelName) {
    let result = await Config.findOne({ _id: modelName });

    if (!result) {
        result = await Config.create({ _id: modelName, count: 0 });
    }

    result = await Config.findOneAndUpdate(
        { _id: modelName },
        { $inc: { count: 1 } },
        { new: true }
    );

    console.log(`Generated ID for ${modelName}:`, result.count); // 🛠 Debug
    return result.count;
}

module.exports = { generateId };
