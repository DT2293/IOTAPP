#include "ws_service.h"
#include <ArduinoWebsockets.h>
#include <ArduinoJson.h>
#include "led_buzzer/led_buzzer_control.h"

using namespace websockets;

static WebsocketsClient wsClient;
static String g_deviceId;
static bool *g_alarmEnabledPtr = nullptr;

static void sendDeviceAuthenticate()
{
    StaticJsonDocument<128> doc;
    doc["type"] = "device_authenticate";
    doc["deviceId"] = g_deviceId;

    String jsonStr;
    serializeJson(doc, jsonStr);
    wsClient.send(jsonStr);
    Serial.println("[WS] Đã gửi xác thực: " + jsonStr);
}

static void onWsEvent(WebsocketsEvent event, String data)
{
    if (event == WebsocketsEvent::ConnectionOpened)
    {
        Serial.println("[WS] Đã kết nối, đang gửi xác thực...");
        sendDeviceAuthenticate();
    }
    else if (event == WebsocketsEvent::ConnectionClosed)
    {
        Serial.println("[WS] Mất kết nối server!");
    }
}

static void onMessageCallback(WebsocketsMessage message)
{
    Serial.print("[WS] Nhận lệnh: ");
    Serial.println(message.data());

    StaticJsonDocument<200> doc;
    if (deserializeJson(doc, message.data()))
        return;

    const char *typeMsg = doc["type"];
    if (typeMsg && strcmp(typeMsg, "alarm_command") == 0)
    {
        const char *command = doc["command"];
        if (command && g_alarmEnabledPtr)
        {
            if (strcmp(command, "alarm_off") == 0)
            {
                *g_alarmEnabledPtr = false;
                stopAlert();
                Serial.println("--> Còi báo BỊ TẮT từ xa");
            }
            else if (strcmp(command, "alarm_on") == 0)
            {
                *g_alarmEnabledPtr = true;
                startAlert();
                Serial.println("--> Còi báo BẬT LẠI từ xa");
            }
        }
    }
}

void initWebSocketService(const String &deviceId, bool &alarmEnabled)
{
    g_deviceId = deviceId;
    g_alarmEnabledPtr = &alarmEnabled;

    wsClient.onEvent(onWsEvent);
    wsClient.onMessage(onMessageCallback);
    wsClient.connect("ws://dungtc.iothings.vn:3000");
}

void loopWebSocketService()
{
    if (wsClient.available())
    {
        wsClient.poll();
    }
    else if (WiFi.status() == WL_CONNECTED)
    {
        static unsigned long lastReconnect = 0;
        if (millis() - lastReconnect > 5000)
        {
            Serial.println("[WS] Thử kết nối lại...");
            wsClient.connect("ws://dungtc.iothings.vn:3000");
            lastReconnect = millis();
        }
    }
}