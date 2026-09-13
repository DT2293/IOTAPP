#include "api_service.h"
#include <HTTPClient.h>
#include <ArduinoJson.h>

void sendDataToServer(const String &deviceId, int gas, bool flameDetected, float temp, float hum)
{
    if (WiFi.status() != WL_CONNECTED)
    {
        Serial.println("Mất kết nối WiFi!");
        return;
    }

    HTTPClient http;
    http.setReuse(true);
    http.begin("http://dungtc.iothings.vn/api/sensordata");
    http.addHeader("Content-Type", "application/json");

    StaticJsonDocument<256> doc;
    doc["deviceId"] = deviceId;
    doc["smokeLevel"] = gas;
    doc["flame"] = flameDetected;
    doc["temperature"] = temp;
    doc["humidity"] = hum;

    String requestBody;
    serializeJson(doc, requestBody);

    int httpResponseCode = http.POST(requestBody);
    if (httpResponseCode > 0)
    {
        Serial.printf("Gửi HTTP thành công: %d\n", httpResponseCode);
    }
    else
    {
        Serial.printf("Gửi HTTP thất bại: %s\n", http.errorToString(httpResponseCode).c_str());
    }
    http.end();
}