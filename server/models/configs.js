const mongoose = require("mongoose");

const configSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  count: { type: Number, required: true },
});

const Config = mongoose.model("configs", configSchema);

async function generateId(modelName = "User") {
  const result = await Config.findOneAndUpdate(
    { _id: modelName },
    { $inc: { count: 1 } },
    { new: true, upsert: true },
  );
  return result.count;
}

module.exports = { generateId };
