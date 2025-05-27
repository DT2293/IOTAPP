#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "config.h"
#include <Adafruit_SSD1306.h>
#include <Adafruit_GFX.h>
#include "configs.h"
#include "rtc/rtc_manager.h"
#include "display/display_manager.h"
#include "flame/flame_sensor.h"
#include "led_buzzer/led_buzzer_control.h"
#include <WiFi.h>
#include <WiFiManager.h>
#include "dht22/dht22.h"
#include "mq2/mq_sensor.h"
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
unsigned long lastPrintTime = 0;

String deviceId;

void sendDataToServer(float temp, float humi, int gas, bool flameDetected) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin("http://192.168.1.7:3000/api/sensordata"); // Thay bằng IP server của bạn
    http.addHeader("Content-Type", "application/json");

    StaticJsonDocument<256> doc;
    doc["deviceId"] = deviceId;
    doc["temperature"] = temp;
    doc["humidity"] = humi;
    doc["smokeLevel"] = gas;
    doc["flame"] = flameDetected ? 1 : 0;

    String requestBody;
    serializeJson(doc, requestBody);

    int httpResponseCode = http.POST(requestBody);
    if (httpResponseCode > 0) {
      Serial.printf("✅ Gửi thành công: %d\n", httpResponseCode);
    } else {
      Serial.printf("❌ Gửi thất bại: %s\n", http.errorToString(httpResponseCode).c_str());
    }

    http.end();
  } else {
    Serial.println("❌ Không có WiFi!");
  }
}

void setup()
{
  Serial.begin(115200);
  Wire.begin(19, 21); // OLED

  initRTC();
  initDisplay();
  initFlameSensor();
  initLedBuzzer();
  digitalWrite(BUZZER_PIN, LOW);
  Serial.println("Khởi động WiFiManager...");

  WiFiManager wifiManager;
  if (!wifiManager.autoConnect("ESP32-Config-AP"))
  {
    Serial.println("Không kết nối được WiFi và cấu hình WiFi thất bại!");

  }
  else
  {
    Serial.println("WiFi đã kết nối!");
    Serial.print("Địa chỉ IP hiện tại: ");
    Serial.println(WiFi.localIP());
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(WHITE);
    display.setCursor(0, 0);
    display.println("WiFi Connected!");
    display.print("IP: ");
    display.println(WiFi.localIP());
    display.display();
  }

  WiFi.mode(WIFI_STA);
  deviceId = WiFi.macAddress();

  String jsonPayload = "{\"deviceId\":\"" + deviceId + "\"}";

  showQRCode(jsonPayload);

  unsigned long qrStartTime = millis();
  while (millis() - qrStartTime < 6000)
  {
    delay(10);
  }
  Serial.println("Setup hoàn thành.");
}
unsigned long lastSensorRead = 0;
unsigned long sensorInterval = 2000;

unsigned long lastAlertCheck = 0;
unsigned long alertInterval = 500;

void loop() {
  unsigned long currentMillis = millis();

  // Đọc cảm biến và gửi dữ liệu mỗi 2 giây
  if (currentMillis - lastSensorRead >= sensorInterval) {
    lastSensorRead = currentMillis;

    int analogFlameVal, digitalFlameVal;
    bool flameDetected = isFlameDetected(analogFlameVal, digitalFlameVal);

    float temp, humi;
    bool dhtOk = readDhtSensor(temp, humi);

    int analogGasVal, digitalGasVal;
    readMQSensor(analogGasVal, digitalGasVal);
    bool gasLeaked = (analogGasVal > 800 || digitalGasVal == LOW);

    if (dhtOk) {
      sendDataToServer(temp, humi, analogGasVal, flameDetected);
      Serial.printf("🌡 %.2f°C | 💧 %.2f%% | 💨 %d | 🔥 %s\n",
                    temp, humi, analogGasVal, flameDetected ? "Có lửa" : "Không");
    } else {
      Serial.println("❌ Không đọc được cảm biến DHT22");
    }

    updateDisplay(flameDetected);
  }

  // Kiểm tra cảnh báo mỗi 500ms
  if (currentMillis - lastAlertCheck >= alertInterval) {
    lastAlertCheck = currentMillis;

    int analogGasVal, digitalGasVal;
    readMQSensor(analogGasVal, digitalGasVal);
    bool gasLeaked = (analogGasVal > 800 || digitalGasVal == LOW);
    int analogFlameVal, digitalFlameVal;
    bool flameDetected = isFlameDetected(analogFlameVal, digitalFlameVal);

    if (analogGasVal > 4095 || analogGasVal < 0 || digitalGasVal == -1) {
      noSignalAlert();
    } else if (flameDetected || gasLeaked) {
      startAlert();
    } else {
      stopAlert();
    }
  }
}
// #define BLYNK_TEMPLATE_ID "TMPL6lIbB6__g"
// #define BLYNK_TEMPLATE_NAME "sensor"
// #define BLYNK_AUTH_TOKEN "NoyfeonUVqzMsSW6yGK2fIyEbOsI9FTf"
// #include "config.h"
// #include <Adafruit_SSD1306.h>
// #include <Adafruit_GFX.h>
// #include "configs.h"
// #include "rtc/rtc_manager.h"
// #include "display/display_manager.h"
// #include "flame/flame_sensor.h"
// #include "led_buzzer/led_buzzer_control.h"
// #include <WiFi.h>
// #include <WiFiManager.h>
// #include <BlynkSimpleEsp32.h>
// Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
// unsigned long lastPrintTime = 0;
// String deviceId;  // Global variable to store MAC address

// void setup()
// {
//   Serial.begin(115200);
//   Wire.begin(19, 21); // OLED

//   initRTC();
//   initDisplay();
//   initFlameSensor();
//   initLedBuzzer();
//   digitalWrite(BUZZER_PIN, LOW);

//   Serial.println("Khởi động WiFiManager...");

//   WiFiManager wifiManager;
//   if (!wifiManager.autoConnect("ESP32-Config-AP")) {
//     Serial.println("Không kết nối được WiFi và cấu hình WiFi thất bại!");
//     // ESP.restart(); // nếu muốn restart
//   } else {
//     Serial.println("WiFi đã kết nối!");
//     Serial.print("Địa chỉ IP hiện tại: ");
//     Serial.println(WiFi.localIP());

//     display.clearDisplay();
//     display.setTextSize(1);
//     display.setTextColor(WHITE);
//     display.setCursor(0, 0);
//     display.println("WiFi Connected!");
//     display.print("IP: ");
//     display.println(WiFi.localIP());
//     display.display();
//   }

//   WiFi.mode(WIFI_STA);
//   deviceId = WiFi.macAddress();

//   String jsonPayload = "{\"deviceId\":\"" + deviceId + "\"}";

//   showQRCode(jsonPayload);

//   unsigned long qrStartTime = millis();
//   while (millis() - qrStartTime < 60000) {
//     Blynk.run();  // Giữ kết nối Blynk trong lúc hiển thị QR
//     delay(100);
//   }

//   // Khởi động Blynk sau khi WiFi đã kết nối
//   Blynk.config(BLYNK_AUTH_TOKEN);
//   while (Blynk.connect() == false) {
//     delay(500);
//     Serial.println("Đang kết nối Blynk...");
//   }

//   Serial.println("Setup hoàn thành.");
// }

// void loop()
// {
//   int analogVal, digitalVal;

//   bool flameDetected = isFlameDetected(analogVal, digitalVal);

//   if (digitalVal == -1 || analogVal > 4095)
//   {
//     noSignalAlert();
//   }
//   else if (flameDetected)
//   {
//     startAlert();
//   }
//   else
//   {
//     stopAlert();
//   }
//   Blynk.virtualWrite(V2, flameDetected ? "🔥 Có lửa!" : "✅ An toàn");
//   updateDisplay(isFlameDetected(analogVal, digitalVal));
//   Blynk.run();
// }

// BLYNK_CONNECTED() {
//   Blynk.virtualWrite(V0, deviceId);  // V4 sẽ hiển thị deviceId
// }

// #include "config.h"
// #include <Adafruit_SSD1306.h>
// #include <Adafruit_GFX.h>
// #include "configs.h"
// #include "rtc/rtc_manager.h"
// #include "display/display_manager.h"
// #include "flame/flame_sensor.h"
// #include "led_buzzer/led_buzzer_control.h"
// #include <WiFi.h>
// #include <WiFiManager.h>

// Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
// unsigned long lastPrintTime = 0;

// void setup()
// {
//   Serial.begin(115200);
//   Wire.begin(19, 21); // OLED

//   initRTC();
//   initDisplay();
//   initFlameSensor();
//   initLedBuzzer();
//   digitalWrite(BUZZER_PIN, LOW);
// // Nếu ESP32 không kết nối được WiFi đã lưu thì sẽ tạo AP để cấu hình
//   Serial.println("Khởi động WiFiManager...");

//   WiFiManager wifiManager;
//   if (!wifiManager.autoConnect("ESP32-Config-AP")) {
//     Serial.println("Không kết nối được WiFi và cấu hình WiFi thất bại!");
//     // Có thể reset lại hoặc dừng ở đây tùy nhu cầu
//     // ESP.restart();
//   } else {
//     Serial.println("WiFi đã kết nối!");
//     Serial.print("Địa chỉ IP hiện tại: ");
//     Serial.println(WiFi.localIP());

//     // Hiển thị IP lên OLED (ví dụ)
//     display.clearDisplay();
//     display.setTextSize(1);
//     display.setTextColor(WHITE);
//     display.setCursor(0, 0);
//     display.println("WiFi Connected!");
//     display.print("IP: ");
//     display.println(WiFi.localIP());
//     display.display();
//   }

//     WiFi.mode(WIFI_STA);  // Khởi động WiFi chế độ station để lấy MAC
//   String deviceId = WiFi.macAddress();
//   String jsonPayload = "{\"deviceId\":\"" + deviceId + "\"}";

//   showQRCode(jsonPayload);
//    unsigned long qrStartTime = millis();
//   while (millis() - qrStartTime < 60000) {
//     // Giữ QR code trên màn hình 60 giây, có thể chèn thêm logic nếu cần
//     delay(100);
//   }
//   Serial.println("Setup hoàn thành.");
// }

// void loop()
// {
//   int analogVal, digitalVal;

//   bool flameDetected = isFlameDetected(analogVal, digitalVal);

//   if (digitalVal == -1 || analogVal > 4095)
//   {
//     noSignalAlert();
//   }
//   else if (flameDetected)
//   {
//     startAlert();
//   }
//   else
//   {
//     stopAlert();
//   }

//   updateDisplay(isFlameDetected(analogVal, digitalVal));
// }