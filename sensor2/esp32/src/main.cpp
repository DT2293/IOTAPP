// #include <Wire.h>
// #include <Adafruit_SSD1306.h>
// #include <Adafruit_GFX.h>
// #include <RTClib.h>

// // Khai báo chân
// #define BUZZER_PIN     27
// #define FLAME_SENSOR_PIN 34
// #define FLAME_SENSOR_ANALOG_PIN 32

// #define RED_LED        25
// #define YELLOW_LED     33
// #define GREEN_LED      32

// // DS3231
// #define SDA_DS3231     16
// #define SCL_DS3231     17
// RTC_DS3231 rtc;
// TwoWire I2C_DS3231 = TwoWire(1);  // I2C bus 1 cho DS3231

// // OLED (SDA 21, SCL 22)
// #define SCREEN_WIDTH 128
// #define SCREEN_HEIGHT 64
// Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// // Biến thời gian cho OLED update
// unsigned long lastDisplayUpdate = 0;
// const unsigned long displayInterval = 1000;  // cập nhật mỗi 1s

// // Biến trạng thái chớp LED non-blocking
// unsigned long lastBlinkTime = 0;
// const unsigned long blinkInterval = 500; // 500ms đổi trạng thái LED
// int blinkCount = 0;
// bool ledsOn = false;
// bool blinkingDone = false;

// void setup() {
//   Serial.begin(115200);

//   // Khởi tạo I2C DS3231 (không trùng chân OLED)
//   I2C_DS3231.begin(SDA_DS3231, SCL_DS3231, 100000);
//   if (!rtc.begin(&I2C_DS3231)) {
//     Serial.println("Không tìm thấy DS3231!");
//     while (1);
//   }

//   // Khởi tạo I2C mặc định cho OLED (chân SDA=21, SCL=22)
//   Wire.begin(19, 21);
//   delay(50);  // Delay nhỏ cho bus ổn định

//   // Quét các thiết bị I2C, debug xem OLED có kết nối không
//   Serial.println("Quét I2C devices:");
//   byte error, address;
//   int nDevices = 0;
//   for (address = 1; address < 127; address++) {
//     Wire.beginTransmission(address);
//     error = Wire.endTransmission();

//     if (error == 0) {
//       Serial.print("Found I2C device at 0x");
//       if (address < 16) Serial.print("0");
//       Serial.print(address, HEX);
//       Serial.println(" !");
//       nDevices++;
//     }
//   }
//   if (nDevices == 0)
//     Serial.println("No I2C devices found\n");
//   else
//     Serial.println("Done\n");

//   // Khởi tạo OLED
//   if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {  // 0x3C là địa chỉ phổ biến của OLED
//     Serial.println("Không tìm thấy OLED!");
//     while (1);
//   }
//   display.clearDisplay();
//   display.setTextSize(1);
//   display.setTextColor(SSD1306_WHITE);
//   display.display();  // Hiển thị clear

//   // Cài đặt chân
//   pinMode(BUZZER_PIN, OUTPUT);
//   pinMode(FLAME_SENSOR_PIN, INPUT);
//   pinMode(RED_LED, OUTPUT);
//   pinMode(YELLOW_LED, OUTPUT);
//   pinMode(GREEN_LED, OUTPUT);

//   // Khởi đầu tất cả LED tắt
//   digitalWrite(RED_LED, LOW);
//   digitalWrite(YELLOW_LED, LOW);
//   digitalWrite(GREEN_LED, LOW);
//  //rtc.adjust(DateTime(2025, 5, 18, 21, 57, 0));  // Chỉ cần set 1 lần!
//   Serial.println("Setup hoàn thành.");
// }
// void loop() {
//   // Đọc cảm biến lửa
//   // Đọc cảm biến lửa digital
//   int flameDigital = digitalRead(FLAME_SENSOR_PIN);
//   // Đọc cảm biến lửa analog
//   int flameAnalog = analogRead(FLAME_SENSOR_ANALOG_PIN);

//   Serial.print("Flame Digital: ");
//   Serial.print(flameDigital);
//   Serial.print(" | Flame Analog: ");
//   Serial.println(flameAnalog);

//   // Ngưỡng analog để phát hiện lửa (bạn có thể điều chỉnh thử)
//   const int flameAnalogThreshold = 200;

//   // Nếu phát hiện lửa dựa trên digital hoặc analog
//   if (flameDigital == LOW || flameAnalog < flameAnalogThreshold) {
//     Serial.println("🔥 Phát hiện lửa!");
//     digitalWrite(BUZZER_PIN, HIGH);
//     blinkingDone = false;
//     blinkCount = 0;
//   } else {
//     digitalWrite(BUZZER_PIN, LOW);

//     // Thực hiện chớp LED nếu chưa hoàn tất
//     if (!blinkingDone) {
//       unsigned long currentMillis = millis();
//       if (currentMillis - lastBlinkTime >= blinkInterval) {
//         lastBlinkTime = currentMillis;
//         ledsOn = !ledsOn;

//         digitalWrite(RED_LED, ledsOn);
//         digitalWrite(YELLOW_LED, ledsOn);
//         digitalWrite(GREEN_LED, ledsOn);

//         if (!ledsOn) {
//           blinkCount++;
//           if (blinkCount >= 3) {
//             blinkingDone = true;
//             digitalWrite(RED_LED, LOW);
//             digitalWrite(YELLOW_LED, LOW);
//             digitalWrite(GREEN_LED, LOW);
//           }
//         }
//       }
//     }
//   }

//   // Cập nhật thời gian lên OLED mỗi giây
//   unsigned long currentMillis = millis();
//   if (currentMillis - lastDisplayUpdate >= displayInterval) {
//     lastDisplayUpdate = currentMillis;

//     DateTime now = rtc.now();

//     display.clearDisplay();
//     display.setCursor(0, 0);
//     display.print("Time: ");
//     display.print(now.hour());
//     display.print(":");
//     if (now.minute() < 10) display.print("0");
//     display.print(now.minute());
//     display.print(":");
//     if (now.second() < 10) display.print("0");
//     display.print(now.second());

//     display.setCursor(0, 10);
//     display.print("Date: ");
//     display.print(now.day());
//     display.print("/");
//     display.print(now.month());
//     display.print("/");
//     display.print(now.year());

//     display.display();
//   }
// }


//-----------------------------------------------------------------------------------------------------------------------
// #define BLYNK_TEMPLATE_ID "TMPL6SS1f0G7n"
// #define BLYNK_TEMPLATE_NAME "tcd"
// #define BLYNK_AUTH_TOKEN "u1Gt11heKkrE9p1mC7KyLJmxOVg4t9E6"

// #define BLYNK_TEMPLATE_ID "TMPL6e8QyMvX4"
// #define BLYNK_TEMPLATE_NAME "dung2"
// #define BLYNK_AUTH_TOKEN "y1uuRJfoya5d-4LuFATabTxi9gRegI0X"



// #define BLYNK_TEMPLATE_ID "TMPL66YWsXpxC"
// #define BLYNK_TEMPLATE_NAME "dung3"
// #define BLYNK_AUTH_TOKEN "SjYxhIlL8EpEBq19k2WQaCWsvgtpXJv7"
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

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
unsigned long lastPrintTime = 0;


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
  if (!wifiManager.autoConnect("ESP32-Config-AP")) {
    Serial.println("Không kết nối được WiFi và cấu hình WiFi thất bại!");
    // Có thể reset lại hoặc dừng ở đây tùy nhu cầu
    // ESP.restart();
  } else {
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

    WiFi.mode(WIFI_STA);  // Khởi động WiFi chế độ station để lấy MAC
  String deviceId = WiFi.macAddress();
  String jsonPayload = "{\"deviceId\":\"" + deviceId + "\"}";

  showQRCode(jsonPayload);
   unsigned long qrStartTime = millis();
  while (millis() - qrStartTime < 60000) {
    // Giữ QR code trên màn hình 60 giây, có thể chèn thêm logic nếu cần
    delay(100);
  }
  Serial.println("Setup hoàn thành.");
}

void loop()
{
  int analogVal, digitalVal;

  bool flameDetected = isFlameDetected(analogVal, digitalVal);

  if (digitalVal == -1 || analogVal > 4095)
  {
    noSignalAlert(); 
  }
  else if (flameDetected)
  {
    startAlert(); 
  }
  else
  {
    stopAlert(); 
  }

  updateDisplay(isFlameDetected(analogVal, digitalVal));
}
// BLYNK_WRITE(V0) {
//     relayState = param.asInt();  // Lấy giá trị từ Blynk
//     digitalWrite(RELAY_PIN, relayState);
//     systemOn = relayState;  // Đồng bộ trạng thái hệ thống với Blynk
//     digitalWrite(LED_GREEN, systemOn); 
//    // Serial.printf("🌐 Blynk -> Relay State: %s\n", relayState ? "ON" : "OFF");
// }   
// // Đồng bộ Device ID khi kết nối lại Blynk
// BLYNK_CONNECTED() {
//     Blynk.syncVirtual(V0);
//     Blynk.virtualWrite(V4, deviceID);
// }