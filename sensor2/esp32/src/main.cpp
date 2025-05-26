// #define BLYNK_TEMPLATE_ID "TMPL6lIbB6__g"
// #define BLYNK_TEMPLATE_NAME "sensor"
// #define BLYNK_AUTH_TOKEN "NoyfeonUVqzMsSW6yGK2fIyEbOsI9FTf"

#define BLYNK_TEMPLATE_ID "TMPL66YWsXpxC"
#define BLYNK_TEMPLATE_NAME "dung3"
#define BLYNK_AUTH_TOKEN "SjYxhIlL8EpEBq19k2WQaCWsvgtpXJv7"
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
#include <BlynkSimpleEsp32.h>
#include "dht22/dht22.h"
#include "mq2/mq_sensor.h"
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
unsigned long lastPrintTime = 0;

String deviceId;
void setup()
{
  Serial.begin(115200);
  Wire.begin(19, 21); // OLED

  initRTC();
  initDisplay();
  initFlameSensor();
  initLedBuzzer();
  digitalWrite(BUZZER_PIN, LOW);
  // Nếu ESP32 không kết nối được WiFi đã lưu thì sẽ tạo AP để cấu hình
  Serial.println("Khởi động WiFiManager...");

  WiFiManager wifiManager;
  if (!wifiManager.autoConnect("ESP32-Config-AP"))
  {
    Serial.println("Không kết nối được WiFi và cấu hình WiFi thất bại!");
    // Có thể reset lại hoặc dừng ở đây tùy nhu cầu
    // ESP.restart();
  }
  else
  {
    Serial.println("WiFi đã kết nối!");
    Serial.print("Địa chỉ IP hiện tại: ");
    Serial.println(WiFi.localIP());

    // Hiển thị IP lên OLED (ví dụ)
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(WHITE);
    display.setCursor(0, 0);
    display.println("WiFi Connected!");
    display.print("IP: ");
    display.println(WiFi.localIP());
    display.display();
  }

  //   WiFi.mode(WIFI_STA);  // Khởi động WiFi chế độ station để lấy MAC
  // String deviceId = WiFi.macAddress();
  // String jsonPayload = "{\"deviceId\":\"" + deviceId + "\"}";

  // showQRCode(jsonPayload);
  //  unsigned long qrStartTime = millis();
  // while (millis() - qrStartTime < 60000) {
  //   // Giữ QR code trên màn hình 60 giây, có thể chèn thêm logic nếu cần
  //   delay(100);
  // }

  WiFi.mode(WIFI_STA);
  deviceId = WiFi.macAddress();

  String jsonPayload = "{\"deviceId\":\"" + deviceId + "\"}";

  showQRCode(jsonPayload);

  unsigned long qrStartTime = millis();
  while (millis() - qrStartTime < 6000)
  {
    Blynk.run(); // Giữ kết nối Blynk trong lúc hiển thị QR
    delay(10);
  }

  // Khởi động Blynk sau khi WiFi đã kết nối
  Blynk.config(BLYNK_AUTH_TOKEN);
  while (Blynk.connect() == false)
  {
    delay(500);
    Serial.println("Đang kết nối Blynk...");
  }

  Serial.println("Setup hoàn thành.");
}

// void loop()
// {
//   int analogVal, digitalVal;
//   bool flameDetected = isFlameDetected(analogVal, digitalVal);

//   float temp, humi;
//   if (readDhtSensor(temp, humi)) {
//     Blynk.virtualWrite(V1, temp);
//     Blynk.virtualWrite(V2, humi);
//     Serial.print("Nhiệt độ: ");
//     Serial.print(temp);
//     Serial.print(" °C  |  Độ ẩm: ");
//     Serial.print(humi);
//     Serial.println(" %");
//   } else {
//     Serial.println("❌ Không đọc được cảm biến DHT22");
//   }

//   int analogValue;
// int digitalValue;
// readMQSensor(analogVal, digitalVal);

//   Serial.printf("MQ2 - Analog: %d | Digital: %d\n", analogVal, digitalVal);

//   // Kiểm tra rò rỉ khí gas
//   if (analogVal > 800 || digitalVal == LOW) {
//     Serial.println("⚠️ CẢNH BÁO: Phát hiện rò rỉ khí gas!");
//     // Bật còi, gửi cảnh báo, kích relay, ...
//   } else {
//     Serial.println("✅ An toàn - không phát hiện khí gas.");
//   }
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
//       // Gửi trạng thái lên Blynk
//   Blynk.virtualWrite(V5, flameDetected ?  "🔥 Có lửa!":"✅ An toàn" );

//   // Cập nhật hiển thị với giá trị đã đo
//   updateDisplay(flameDetected);

//   // Gọi Blynk
//   Blynk.run();
// }

void loop()
{
  // Đọc cảm biến lửa
  int analogFlameVal, digitalFlameVal;
  bool flameDetected = isFlameDetected(analogFlameVal, digitalFlameVal);

  // Đọc cảm biến DHT22
  float temp, humi;
  if (readDhtSensor(temp, humi))
  {
    Blynk.virtualWrite(V1, temp); // Gửi nhiệt độ lên Blynk
    Blynk.virtualWrite(V2, humi); // Gửi độ ẩm lên Blynk
    Serial.printf("Nhiệt độ: %.2f °C  |  Độ ẩm: %.2f %%\n", temp, humi);
  }
  else
  {
    Serial.println("❌ Không đọc được cảm biến DHT22");
  }

  // Đọc cảm biến khí gas MQ2
  int analogGasVal, digitalGasVal;
  readMQSensor(analogGasVal, digitalGasVal);
  bool gasLeaked = (analogGasVal > 800 || digitalGasVal == LOW);
  Blynk.virtualWrite(V3, analogGasVal);

  // Gửi trạng thái cảnh báo lên V6
  if (gasLeaked)
  {
    Blynk.virtualWrite(V6, "⚠️ Rò rỉ khí gas!");
    Blynk.virtualWrite(V7, 255); // Bật LED (giá trị 255)
  }
  else
  {
    Blynk.virtualWrite(V6, "✅ Không có rò rỉ khí gas");
    Blynk.virtualWrite(V7, 0); // Tắt LED
  }

  // Phát cảnh báo nếu tín hiệu lỗi hoặc phát hiện lửa/gas
  if (analogGasVal > 4095 || analogGasVal < 0 || digitalGasVal == -1)
  {
    noSignalAlert(); // Cảnh báo mất tín hiệu
  }
  else if (flameDetected || gasLeaked)
  {
    Blynk.virtualWrite(V5, 255);
    startAlert(); // Phát còi hoặc cảnh báo
  }
  else
  {
    stopAlert(); // Dừng còi
  }

  // Gửi trạng thái lên Blynk
  Blynk.virtualWrite(V8, flameDetected ? "🔥 Có lửa!" : "✅ An toàn");

  // Cập nhật hiển thị OLED
  updateDisplay(flameDetected);

  Blynk.run();
}

BLYNK_CONNECTED()
{
  Blynk.virtualWrite(V4, deviceId); // V4 sẽ hiển thị deviceId
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