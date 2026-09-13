#ifndef API_SERVICE_H
#define API_SERVICE_H

#include <Arduino.h>

void sendDataToServer(const String &deviceId, int gas, bool flameDetected, float temp = 0.0, float hum = 0.0);

#endif