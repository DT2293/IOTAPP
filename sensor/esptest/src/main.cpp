#define BLYNK_TEMPLATE_ID "TMPL6SS1f0G7n"
#define BLYNK_TEMPLATE_NAME "tcd"
#define BLYNK_AUTH_TOKEN "u1Gt11heKkrE9p1mC7KyLJmxOVg4t9E6"

// #define BLYNK_TEMPLATE_ID "TMPL6e8QyMvX4"
// #define BLYNK_TEMPLATE_NAME "dung2"
// #define BLYNK_AUTH_TOKEN "y1uuRJfoya5d-4LuFATabTxi9gRegI0X"



// #define BLYNK_TEMPLATE_ID "TMPL66YWsXpxC"
// #define BLYNK_TEMPLATE_NAME "dung3"
// #define BLYNK_AUTH_TOKEN "SjYxhIlL8EpEBq19k2WQaCWsvgtpXJv7"
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


#define TEMP_WARNING      50     // °C
#define TEMP_CRITICAL     60     // °C
#define SMOKE_WARNING     300    // PPM
#define SMOKE_CRITICAL    400    // PPM
#define RATE_OF_RISE_TH   8      // °C/phút

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

unsigned long fireStartTime = 0;
bool isFireDetected = false;
const long DHT_INTERVAL = 2000;
const long SMOKE_INTERVAL = 1000;
const long BUTTON_DEBOUNCE = 300;

void checkButton(unsigned long currentMillis);
void readDHTSensor(unsigned long currentMillis);
void readSmokeSensor(unsigned long currentMillis, float temperature, float humidity, float rateOfRise);
void handleAlarm(int smokeValue, float temperature,float rateOfRise) ;
// Khai báo biến Device ID
void setup() {
    Serial.begin(115200);

    // Lấy địa chỉ MAC làm Device ID
    uint8_t mac[6];
    WiFi.macAddress(mac);
    char macStr[18];
    sprintf(macStr, "%02X:%02X:%02X:%02X:%02X:%02X", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
    deviceID = String(macStr);

    // Khai báo chân LED, Relay, Nút
    pinMode(LED_RED, OUTPUT);
    pinMode(LED_GREEN, OUTPUT);
    pinMode(BUTTON_PIN, INPUT_PULLUP);
    pinMode(RELAY_PIN, OUTPUT);
    digitalWrite(RELAY_PIN, relayState);

    // Kết nối WiFi
    WiFi.begin(ssid, pass);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nWiFi connected!");

    // NHÁY ĐÈN 3 LẦN BÁO HIỆU
    for (int i = 0; i < 3; i++) {
        digitalWrite(LED_RED, HIGH);
        digitalWrite(LED_GREEN, HIGH);
        delay(200);
        digitalWrite(LED_RED, LOW);
        digitalWrite(LED_GREEN, LOW);
        delay(200);
    }

    // Kết nối Blynk
    Blynk.config(BLYNK_AUTH_TOKEN);
    Blynk.connect();

    // Gửi Device ID lên Blynk
    Blynk.virtualWrite(V4, deviceID);

    // Khởi động cảm biến DHT
    dht.begin();

    // Khởi động màn hình OLED
    if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        Serial.println("SSD1306 allocation failed");
        while (1);
    }

    // Hiển thị MAC trên OLED
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
            static float lastTempForRate = -100;

            int tempRounded = round(temperature * 10) / 10;  // Giới hạn 1 số thập phân
            int humRounded = round(humidity);

            float rateOfRise = (lastTempForRate == -100) ? 0 : (temperature - lastTempForRate);
            lastTempForRate = temperature;

            if (abs(tempRounded - lastTemp) >= 1) {  
                Blynk.virtualWrite(V2, tempRounded);
                lastTemp = tempRounded;
            }
            if (abs(humRounded - lastHum) >= 2) {  
                Blynk.virtualWrite(V1, humRounded);
                lastHum = humRounded;
            }

            readSmokeSensor(currentMillis, tempRounded, humRounded, rateOfRise);
        } else {
            Serial.println("⚠️ Lỗi đọc DHT22!");
        }
    }
}

void readSmokeSensor(unsigned long currentMillis, float temperature, float humidity, float rateOfRise)
{
    if (currentMillis - lastSmokeRead >= SMOKE_INTERVAL) {
        lastSmokeRead = currentMillis;
        int smokeValue = random(0,1200); 
        Serial.printf("Khói: %d\n", smokeValue);
        Blynk.virtualWrite(V3, smokeValue);
        display.clearDisplay();
        display.setTextSize(2);
        handleAlarm(smokeValue, temperature, rateOfRise);
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
void handleAlarm(int smokeValue, float temperature, float rateOfRise) {
    bool smokeWarning  = smokeValue >= SMOKE_WARNING;
    bool smokeCritical = smokeValue >= SMOKE_CRITICAL;
    bool tempWarning   = temperature >= TEMP_WARNING;
    bool tempCritical  = temperature >= TEMP_CRITICAL;
    bool rorDanger     = rateOfRise >= RATE_OF_RISE_TH;

    bool isDanger = smokeCritical || tempCritical;
    unsigned long currentMillis = millis();

    display.clearDisplay();
    display.setTextSize(2);
    display.setCursor(10, 20);

    if (isDanger) {
        if (!isFireDetected) {
            fireStartTime = currentMillis;
            isFireDetected = true;
        } else if (currentMillis - fireStartTime >= 10000) {
            Serial.println("🚨 CHÁY NGHIÊM TRỌNG!");
            display.println("CRITICAL!");
            digitalWrite(LED_RED, HIGH);
            digitalWrite(RELAY_PIN, HIGH);
            relayState = HIGH;
            Blynk.virtualWrite(V0, relayState);
        }
    } else if (smokeWarning || tempWarning || rorDanger) {
        Serial.println("⚠️ CẢNH BÁO NGUY CƠ CHÁY!");
        display.println("WARNING!");
        // Có thể bật đèn vàng nếu bạn có
    } else {
        isFireDetected = false;
        fireStartTime = 0;
        digitalWrite(LED_RED, LOW);
        digitalWrite(RELAY_PIN, LOW);
        relayState = LOW;
        Blynk.virtualWrite(V0, relayState);
    }

    // Serial & OLED hiển thị chi tiết
    if (smokeCritical && tempCritical) {
        Serial.println("🔥 NGHIÊM TRỌNG! Khói & Nhiệt độ cao!");
    } else if (smokeWarning && tempWarning) {
        Serial.println("⚠️ Cảnh báo: Cả khói & nhiệt độ cảnh báo!");
    } else if (smokeWarning) {
        Serial.println("💨 Mức khói cao!");
    } else if (tempWarning) {
        Serial.println("🌡️ Nhiệt độ cao!");
    } else if (rorDanger) {
        Serial.println("🚀 Tăng nhiệt nhanh bất thường!");
    } else {
        Serial.println("✅ Bình thường.");
        display.println("SAFE");
    }

    display.display();
}


BLYNK_WRITE(V0) {
    relayState = param.asInt();  // Lấy giá trị từ Blynk
    digitalWrite(RELAY_PIN, relayState);
    systemOn = relayState;  // Đồng bộ trạng thái hệ thống với Blynk
    digitalWrite(LED_GREEN, systemOn); 
   // Serial.printf("🌐 Blynk -> Relay State: %s\n", relayState ? "ON" : "OFF");
}   
// Đồng bộ Device ID khi kết nối lại Blynk
BLYNK_CONNECTED() {
    Blynk.syncVirtual(V0);
    Blynk.virtualWrite(V4, deviceID);
}



