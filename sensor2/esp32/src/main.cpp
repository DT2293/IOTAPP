

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
  #include "mq2/mq_sensor.h"
  #include <ArduinoWebsockets.h>
#include "dht22/dht22.h"
  using namespace websockets;

  WebsocketsClient wsClient;
  Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
  unsigned long lastPrintTime = 0;

  String deviceId;

  void sendDataToServer(int gas, bool flameDetected, float dhtTemperature = 0.0, float dhtHumidity = 0.0)
  {
    if (WiFi.status() == WL_CONNECTED)
    {
      HTTPClient http;
      http.begin("http://dungtc.iothings.vn/api/sensordata"); // Thay bằng IP server của bạn
      http.addHeader("Content-Type", "application/json");

      StaticJsonDocument<256> doc;
      doc["deviceId"] = deviceId;
      doc["smokeLevel"] = gas;
      //  doc["flame"] = flameDetected ? 1 : 0;
      doc["flame"] = flameDetected; // gửi đúng kiểu boolean

      doc["Temperature"] = dhtTemperature; // Thêm nhiệt độ từ cảm biến DHT22 (nếu có)
      doc["Humidity"] = dhtHumidity; // Thêm độ ẩm từ cảm biến DHT22 (nếu có)
      String requestBody;
      serializeJson(doc, requestBody);

      int httpResponseCode = http.POST(requestBody);
      if (httpResponseCode > 0)
      {
      //  Serial.printf("✅ Gửi thành công: %d\n", httpResponseCode);
      } 
      else
      {
        Serial.printf("Gửi thất bại: %s\n", http.errorToString(httpResponseCode).c_str());
      }

      http.end();
    }
    else
    {
      Serial.println("Không có WiFi!");
    }
  }
  void sendDeviceAuthenticate()
  {
    StaticJsonDocument<128> doc;
    doc["type"] = "device_authenticate";
    doc["deviceId"] = deviceId;

    String jsonStr;
    serializeJson(doc, jsonStr);

    wsClient.send(jsonStr);
    Serial.println("[WS] Đã gửi xác thực device_authenticate: " + jsonStr);
  }

  void onMessageCallback(WebsocketsMessage message);
  void onWsEvent(WebsocketsEvent event, String data) {
    if (event == WebsocketsEvent::ConnectionOpened) {
      Serial.println("WebSocket đã kết nối, gửi xác thực...");
      sendDeviceAuthenticate();
    }
  }

  void setup() {
    Serial.begin(115200);
    Wire.begin(19, 21); // OLED
    initRTC();
    initDisplay();
    initFlameSensor();
    initLedBuzzer();
     initDhtSensor();
    digitalWrite(BUZZER_PIN, LOW);
    Serial.println("Khởi động WiFiManager...");

    WiFiManager wifiManager;
    if (!wifiManager.autoConnect("ESP32-Config-AP")) {
      Serial.println("Không kết nối được WiFi và cấu hình WiFi thất bại!");
    } else {
      Serial.println("WiFi đã kết nối!");
      Serial.print("Địa chỉ IP hiện tại: ");
      Serial.println(WiFi.localIP());

      deviceId = WiFi.macAddress();

      display.clearDisplay();
      display.setTextSize(1);
      display.setTextColor(WHITE);
      display.setCursor(0, 0);
      display.println("WiFi Connected!");
      display.print("IP: ");
      display.println(WiFi.localIP());

      wsClient.onEvent(onWsEvent);        
      wsClient.onMessage(onMessageCallback); 

      wsClient.connect("ws://dungtc.iothings.vn:3000");

      display.display();
    }

    WiFi.mode(WIFI_STA);

    String jsonPayload = "{\"deviceId\":\"" + deviceId + "\"}";
    showQRCode(jsonPayload);

    unsigned long qrStartTime = millis();
    while (millis() - qrStartTime < 600) {
      delay(10);
    }
    Serial.println("Setup hoàn thành.");
  }


  unsigned long lastSensorRead = 0;
  unsigned long sensorInterval = 2000;

  unsigned long lastAlertCheck = 0;
  unsigned long alertInterval = 500;
  bool alarmEnabled = true;
  void onMessageCallback(WebsocketsMessage message)
  {
    Serial.print("Nhận tin nhắn từ server: ");
    Serial.println(message.data());

    StaticJsonDocument<200> doc;
    DeserializationError err = deserializeJson(doc, message.data());
    if (err)
    {
      Serial.println("Lỗi parse JSON");
      return;
    }

    const char *typeMsg = doc["type"];
    if (strcmp(typeMsg, "alarm_command") == 0)
    {
      const char *command = doc["command"];
      if (strcmp(command, "alarm_off") == 0)
      {
        alarmEnabled = false;
        stopAlert();
        Serial.println("Còi báo bị tắt từ xa");
      }
      else if (strcmp(command, "alarm_on") == 0)
      {
        alarmEnabled = true;
        startAlert();
        Serial.println("🔔 Còi báo bật lại");
      }
    }
  }

  void loop()
  {

    unsigned long currentMillis = millis();
    float temperature, humidity;
bool dhtSuccess = readDhtSensor(temperature, humidity);
    if (currentMillis - lastSensorRead >= sensorInterval)
    {
      lastSensorRead = currentMillis;

      int analogFlameVal, digitalFlameVal;
      bool flameDetected = isFlameDetected(analogFlameVal, digitalFlameVal);

      int analogGasVal, digitalGasVal;
      readMQSensor(analogGasVal, digitalGasVal);
     if (dhtSuccess) {
  sendDataToServer(analogGasVal, flameDetected, temperature, humidity);
} else {

  sendDataToServer(analogGasVal, flameDetected);
}

      updateDisplay(flameDetected);
    }

    if (currentMillis - lastAlertCheck >= alertInterval)
    {
      lastAlertCheck = currentMillis;

      int analogGasVal, digitalGasVal;
      readMQSensor(analogGasVal, digitalGasVal);
      bool gasLeaked = (analogGasVal > 300 || digitalGasVal == LOW);
      int analogFlameVal, digitalFlameVal;
      bool flameDetected = isFlameDetected(analogFlameVal, digitalFlameVal);

      if (analogGasVal > 4095 || analogGasVal < 0 || digitalGasVal == -1)
      {
        noSignalAlert();
      }
      else if (flameDetected || gasLeaked)
      {
        if (alarmEnabled)
        {
          startAlert();
        }
        else
        {
          stopAlert(); 
        }
        // startAlert();
      }
      else
      {
        stopAlert();
      }
    }
    wsClient.poll();
  }
