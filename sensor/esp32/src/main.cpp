#include <Adafruit_SSD1306.h>
#include <Adafruit_GFX.h>
#include "config.h"
#include "configs.h"
#include "display/display_manager.h"
#include "wifi/wifi_service.h"
#include "socket/ws_service.h"
#include "controller/system_controller.h"

extern Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
extern bool alarmEnabled;

String deviceId;

void setup()
{
  Serial.begin(115200);
  Wire.begin(19, 21);
  initSystemSensors();
  if (!initWiFiService(deviceId))
  {
    ESP.restart();
  }
  initWebSocketService(deviceId, alarmEnabled);
  String jsonPayload = "{\"deviceId\":\"" + deviceId + "\"}";
  showQRCode(jsonPayload);
  vTaskDelay(600 / portTICK_PERIOD_MS);
  Serial.println("Setup hoàn thành.");
}

void loop()
{
  processSystemTasks(deviceId);
  loopWebSocketService();
}