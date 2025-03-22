// #define BLYNK_TEMPLATE_ID "TMPL6SS1f0G7n"
// #define BLYNK_TEMPLATE_NAME "tcd"
// #define BLYNK_AUTH_TOKEN "u1Gt11heKkrE9p1mC7KyLJmxOVg4t9E6"
#define BLYNK_TEMPLATE_ID "TMPL6e8QyMvX4"
#define BLYNK_TEMPLATE_NAME "dung2"
#define BLYNK_AUTH_TOKEN "y1uuRJfoya5d-4LuFATabTxi9gRegI0X"
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>
#include <WiFi.h>
#include <WiFiClient.h>
#include <BlynkSimpleEsp32.h>


// WiFi Credentials
char ssid[] = "Wokwi-GUEST";  
char pass[] = ""; 

// OLED Display
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Cảm biến DHT22
#define DHTPIN 26
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// Cảm biến khói
#define SMOKE_SENSOR_PIN 34  
#define SMOKE_THRESHOLD 800  
#define TEMP_THRESHOLD 30    

// Relay
#define RELAY_PIN 12

// LED
#define LED_RED 14
#define LED_GREEN 27

// Button
#define BUTTON_PIN 25
String deviceID;
bool systemOn = true;
bool lastButtonState = HIGH;
bool relayState = LOW; // Trạng thái relay
unsigned long lastDHTRead = 0;
unsigned long lastSmokeRead = 0;
unsigned long lastButtonCheck = 0;
const long DHT_INTERVAL = 2000;
const long SMOKE_INTERVAL = 1000;
const long BUTTON_DEBOUNCE = 300;

void checkButton(unsigned long currentMillis);
void readDHTSensor(unsigned long currentMillis);
void readSmokeSensor(unsigned long currentMillis, float temperature, float humidity);
void handleAlarm(int smokeValue, float temperature) ;
// Khai báo biến Device ID

void setup() {
    Serial.begin(115200);
    // Lấy địa chỉ MAC làm Device ID
    uint8_t mac[6];
    WiFi.macAddress(mac);
    char macStr[18];
    sprintf(macStr, "%02X:%02X:%02X:%02X:%02X:%02X", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
    deviceID = String(macStr);
    // Khởi động WiFi & Blynk
    WiFi.begin(ssid, pass);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nWiFi connected!");
    Blynk.config(BLYNK_AUTH_TOKEN);
    Blynk.connect();
    // Gửi Device ID (MAC) lên Blynk (V4)
    Blynk.virtualWrite(V4, deviceID);

    pinMode(LED_RED, OUTPUT);
    pinMode(LED_GREEN, OUTPUT);
    pinMode(BUTTON_PIN, INPUT_PULLUP);
    pinMode(RELAY_PIN, OUTPUT);
    digitalWrite(RELAY_PIN, relayState);

    dht.begin();

    if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        Serial.println("SSD1306 allocation failed");
        while (1);
    }

    // Hiển thị Device ID (MAC) trên OLED
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(WHITE);
    display.setCursor(10, 5);
    display.print("Device ID:");
    display.setCursor(10, 20);
    display.print(deviceID);
    display.display();

    Serial.print("Device ID (MAC): ");
    Serial.println(deviceID);
}


void loop() {
    unsigned long currentMillis = millis();
    checkButton(currentMillis);

    if (systemOn) {
        readDHTSensor(currentMillis);
    } else {
        digitalWrite(LED_RED, LOW);
        digitalWrite(RELAY_PIN, LOW);
        display.clearDisplay();
        display.setTextSize(2);
        display.setCursor(10, 20);
        display.println("OFF");
        display.display();
    }
    Blynk.run();
}

// Nút nhấn bật/tắt hệ thống
void checkButton(unsigned long currentMillis) {
    bool buttonState = digitalRead(BUTTON_PIN);

    if (currentMillis - lastButtonCheck >= BUTTON_DEBOUNCE) {
        lastButtonCheck = currentMillis;

        if (buttonState == LOW && lastButtonState == HIGH) {  // Phát hiện nhấn nút
            systemOn = !systemOn;  // Đảo trạng thái hệ thống

            relayState = systemOn ? HIGH : LOW;  
            digitalWrite(RELAY_PIN, relayState);
            digitalWrite(LED_GREEN, systemOn);
            Blynk.virtualWrite(V0, relayState);

            Serial.printf("🔘 Button Pressed -> System: %s, Relay: %s\n",
                          systemOn ? "ON" : "OFF",
                          relayState ? "ON" : "OFF");
        }
        lastButtonState = buttonState;
    }
}
void readDHTSensor(unsigned long currentMillis) {
    if (currentMillis - lastDHTRead >= DHT_INTERVAL) {
        lastDHTRead = currentMillis;
        float temperature = dht.readTemperature();
        float humidity = dht.readHumidity();

        if (!isnan(temperature) && !isnan(humidity)) {
            static float lastTemp = -100, lastHum = -100;
            
            int tempRounded = round(temperature * 10) / 10;  // Giới hạn 1 số thập phân
            int humRounded = round(humidity);

            if (abs(tempRounded - lastTemp) >= 1) {  
                Blynk.virtualWrite(V2, tempRounded);
                lastTemp = tempRounded;
            }
            if (abs(humRounded - lastHum) >= 2) {  
                Blynk.virtualWrite(V1, humRounded);
                lastHum = humRounded;
            }

            readSmokeSensor(currentMillis, tempRounded, humRounded);
        } else {
            Serial.println("⚠️ Lỗi đọc DHT22!");
        }
    }
}

void readSmokeSensor(unsigned long currentMillis, float temperature, float humidity) {
    if (currentMillis - lastSmokeRead >= SMOKE_INTERVAL) {
        lastSmokeRead = currentMillis;
      //  int smokeValue = analogRead(SMOKE_SENSOR_PIN); 
      int smokeValue = random(0,1200); 
        Serial.printf("Khói: %d\n", smokeValue);
        Blynk.virtualWrite(V3, smokeValue);

        display.clearDisplay();
        display.setTextSize(2);

        handleAlarm(smokeValue, temperature);

        display.setCursor(5, 5);
        display.printf("T: %.1fC", temperature);
        display.setCursor(5, 30);
        display.printf("H: %d%%", (int)humidity);
        display.setCursor(5, 55);
        display.printf("S: %d", smokeValue);

        display.display();
    }
}

// Xử lý cảnh báo dựa trên mức khói và nhiệt độ
void handleAlarm(int smokeValue, float temperature) {
    bool smokeDanger = (smokeValue > SMOKE_THRESHOLD);
    bool tempDanger = (temperature > TEMP_THRESHOLD);
    bool danger = smokeDanger || tempDanger; // Kiểm tra có nguy hiểm không

    display.clearDisplay();
    display.setTextSize(2);
    display.setCursor(10, 20);

    if (smokeDanger && tempDanger) {
        Serial.println("🔥 NGUY HIỂM! Khói & Nhiệt độ cao!");
        display.println("DANGER!");
    } 
    else if (smokeDanger) {
        Serial.println("⚠️ Cảnh báo: Phát hiện khói!");
        display.println("SMOKE!");
    } 
    else if (tempDanger) {
        Serial.println("🌡️ Nhiệt độ cao!");
        display.println("HOT!");
    } 
    else {
        Serial.println("✅ Không khí sạch.");
        display.println("SAFE");
    }

    // Cập nhật trạng thái relay & LED
    digitalWrite(LED_RED, danger ? HIGH : LOW);
    digitalWrite(RELAY_PIN, danger ? HIGH : LOW);
    relayState = danger;

    // Gửi trạng thái relay lên Blynk
    Blynk.virtualWrite(V0, relayState);

    display.display();
}


BLYNK_WRITE(V0) {
    relayState = param.asInt();  // Lấy giá trị từ Blynk
    digitalWrite(RELAY_PIN, relayState);
    systemOn = relayState;  // Đồng bộ trạng thái hệ thống với Blynk

   // Serial.printf("🌐 Blynk -> Relay State: %s\n", relayState ? "ON" : "OFF");
}   
// Đồng bộ Device ID khi kết nối lại Blynk
BLYNK_CONNECTED() {
    Blynk.syncVirtual(V0);
    Blynk.virtualWrite(V4, deviceID);
}




// #define BLYNK_TEMPLATE_ID "TMPL6e8QyMvX4"
// #define BLYNK_TEMPLATE_NAME "dung2"
// #define BLYNK_AUTH_TOKEN "y1uuRJfoya5d-4LuFATabTxi9gRegI0X"

// #include <Wire.h>
// #include <Adafruit_GFX.h>
// #include <Adafruit_SSD1306.h>
// #include <DHT.h>
// #include <WiFi.h>
// #include <WiFiClient.h>
// #include <BlynkSimpleEsp32.h>

// //WiFi Credentials
// char ssid[] = "Wokwi-GUEST";  
// char pass[] = ""; 

// //Device ID từ địa chỉ MAC
// String DEVICE_ID;

// //OLED Display
// #define SCREEN_WIDTH 128
// #define SCREEN_HEIGHT 64
// #define OLED_RESET -1
// Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// //Cảm biến DHT22
// #define DHTPIN 26
// #define DHTTYPE DHT22
// DHT dht(DHTPIN, DHTTYPE);

// //Cảm biến khói
// #define SMOKE_SENSOR_PIN 34  
// #define SMOKE_THRESHOLD 800  
// #define TEMP_THRESHOLD 30    

// //Relay
// #define RELAY_PIN 12

// //LED
// #define LED_RED 14
// #define LED_GREEN 27

// //Button
// #define BUTTON_PIN 25

// bool systemOn = true;
// bool lastButtonState = HIGH;
// bool relayState = LOW; // Trạng thái relay
// unsigned long lastDHTRead = 0;
// unsigned long lastSmokeRead = 0;
// unsigned long lastButtonCheck = 0;
// const long DHT_INTERVAL = 2000;
// const long SMOKE_INTERVAL = 1000;
// const long BUTTON_DEBOUNCE = 300;

// void checkButton(unsigned long currentMillis);
// void readDHTSensor(unsigned long currentMillis);
// void readSmokeSensor(unsigned long currentMillis, float temperature, float humidity);

// void setup() {
//     Serial.begin(115200);

//     //Kết nối WiFi
//     WiFi.begin(ssid, pass);
//     while (WiFi.status() != WL_CONNECTED) {
//         delay(500);
//         Serial.print(".");
//     }
//     Serial.println("\n✅ WiFi connected!");

//    // Lấy địa chỉ MAC làm DEVICE_ID
//     DEVICE_ID = WiFi.macAddress();
//     Serial.println("🔹 Device ID: " + DEVICE_ID);

//     //Kết nối Blynk
//     Blynk.config(BLYNK_AUTH_TOKEN);
//     Blynk.connect();

//     pinMode(LED_RED, OUTPUT);
//     pinMode(LED_GREEN, OUTPUT);
//     pinMode(BUTTON_PIN, INPUT_PULLUP);
//     pinMode(RELAY_PIN, OUTPUT);
//     digitalWrite(RELAY_PIN, relayState);

//     dht.begin();

//     if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
//         Serial.println("❌ SSD1306 allocation failed");
//         while (1);
//     }
//     display.clearDisplay();
//     display.setTextSize(1);
//     display.setTextColor(WHITE);
//     display.display();
// }

// void loop() {
//     unsigned long currentMillis = millis();
//     checkButton(currentMillis);

//     if (systemOn) {
//         readDHTSensor(currentMillis);
//     } else {
//         digitalWrite(LED_RED, LOW);
//         digitalWrite(RELAY_PIN, LOW);
//         display.clearDisplay();
//         display.setTextSize(2);
//         display.setCursor(10, 20);
//         display.println("OFF");
//         display.display();
//     }

//   //  Gửi Device ID lên Blynk (định danh)
//     Blynk.virtualWrite(V4, DEVICE_ID);

//     Blynk.run();
// }

// //Nút nhấn bật/tắt hệ thống
// void checkButton(unsigned long currentMillis) {
//     bool buttonState = digitalRead(BUTTON_PIN);

//     if (currentMillis - lastButtonCheck >= BUTTON_DEBOUNCE) {
//         lastButtonCheck = currentMillis;

//         if (buttonState == LOW && lastButtonState == HIGH) {  // Phát hiện nhấn nút
//             systemOn = !systemOn;  // Đảo trạng thái hệ thống

//             relayState = systemOn ? HIGH : LOW;  
//             digitalWrite(RELAY_PIN, relayState);
//             digitalWrite(LED_GREEN, systemOn);
//             Blynk.virtualWrite(V0, relayState);

//             Serial.printf("🔘 Button Pressed -> System: %s, Relay: %s\n",
//                           systemOn ? "ON" : "OFF",
//                           relayState ? "ON" : "OFF");
//         }
//         lastButtonState = buttonState;
//     }
// }

// //Đọc cảm biến DHT22
// void readDHTSensor(unsigned long currentMillis) {
//     if (currentMillis - lastDHTRead >= DHT_INTERVAL) {
//         lastDHTRead = currentMillis;
//         float temperature = dht.readTemperature();
//         float humidity = dht.readHumidity();

//         if (!isnan(temperature) && !isnan(humidity)) {
//             static float lastTemp = 0, lastHum = 0;
            
//             if (abs(temperature - lastTemp) >= 0.5) {  
//                 Blynk.virtualWrite(V2, temperature);
//                 lastTemp = temperature;
//             }

//             if (abs(humidity - lastHum) >= 2) {  
//                 Blynk.virtualWrite(V1, humidity);
//                 lastHum = humidity;
//             }

//             readSmokeSensor(currentMillis, temperature, humidity);
//         } else {
//             Serial.println("⚠️ Lỗi đọc DHT22!");
//         }
//     }
// }
// void readSmokeSensor(unsigned long currentMillis, float temperature, float humidity) {
//         if (currentMillis - lastSmokeRead >= SMOKE_INTERVAL) {
//             lastSmokeRead = currentMillis;
//             int smokeValue = analogRead(SMOKE_SENSOR_PIN);
    
//             static int lastSmoke = 0;
//             if (abs(smokeValue - lastSmoke) >= 50) {  // Chỉ gửi khi thay đổi ≥ 50
//                 Blynk.virtualWrite(V3, smokeValue);
//                 lastSmoke = smokeValue;
//             }
//         }
//     }

// void readSmokeSensor(unsigned long currentMillis, float temperature, float humidity) {
//     if (currentMillis - lastSmokeRead >= SMOKE_INTERVAL) {
//         lastSmokeRead = currentMillis;
//         int smokeValue = analogRead(SMOKE_SENSOR_PIN);

//         static int lastSmoke = 0;
//         if (abs(smokeValue - lastSmoke) >= 50) {  
//             Blynk.virtualWrite(V3, smokeValue);
//             lastSmoke = smokeValue;
//         }

//         display.clearDisplay();
//         display.setTextSize(2);

//         if (smokeValue > SMOKE_THRESHOLD && temperature > TEMP_THRESHOLD) {
//             Serial.println("🔥 DANGER: Smoke + High Temp!");
//             digitalWrite(LED_RED, HIGH);
//             digitalWrite(RELAY_PIN, HIGH);
//             relayState = HIGH;
//             Blynk.virtualWrite(V0, relayState);
//             display.setCursor(10, 20);
//             display.println("DANGER!");
//         } else if (smokeValue > SMOKE_THRESHOLD) {
//             Serial.println("⚠️ WARNING: Smoke Detected!");
//             digitalWrite(LED_RED, HIGH);
//             display.setCursor(10, 20);
//             display.println("SMOKE!");
//         } else {
//             Serial.println("✅ Air is Clear.");
//             digitalWrite(LED_RED, temperature > TEMP_THRESHOLD ? HIGH : LOW);
//             display.setCursor(10, 5);
//             display.printf("T:%.1fC", temperature);
//             display.setCursor(10, 30);
//             display.printf("H:%.1f%%", humidity);
//         }
//         display.display();
//     }
// }

// //Điều khiển relay từ Blynk
// BLYNK_WRITE(V0) {
//     relayState = param.asInt();  
//     digitalWrite(RELAY_PIN, relayState);
//     systemOn = relayState;  
// }

// //Đồng bộ trạng thái relay khi Blynk kết nối
// BLYNK_CONNECTED() {
//     Blynk.syncVirtual(V0);
// }
