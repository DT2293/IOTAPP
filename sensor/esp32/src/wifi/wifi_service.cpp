#include "wifi_service.h"
#include <WiFi.h>
#include <WiFiManager.h>
#include <Adafruit_SSD1306.h>

extern Adafruit_SSD1306 display;

bool initWiFiService(String &deviceId)
{
    WiFi.mode(WIFI_STA);
    Serial.println("Khởi động WiFiManager...");

    WiFiManager wifiManager;
    if (!wifiManager.autoConnect("ESP32-Config-AP"))
    {
        Serial.println("Cấu hình WiFi thất bại.");
        return false;
    }

    deviceId = WiFi.macAddress();
    Serial.println("WiFi đã kết nối! IP: " + WiFi.localIP().toString());

    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(WHITE);
    display.setCursor(0, 0);
    display.println("WiFi Connected!");
    display.print("IP: ");
    display.println(WiFi.localIP());
    display.display();

    return true;
}