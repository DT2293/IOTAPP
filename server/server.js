const mqtt = require("mqtt");
const client = mqtt.connect("mqtt://broker.hivemq.com");

client.on("connect", () => {
    console.log("✅ MQTT Connected!");
    client.subscribe("iot/fire/sensor");
    client.publish("iot/fire/relay", "1"); // Bật relay
});

client.on("message", (topic, message) => {
    console.log(`📥 Received: ${topic} -> ${message.toString()}`);
});
