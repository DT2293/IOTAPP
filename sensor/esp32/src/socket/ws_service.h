#ifndef WS_SERVICE_H
#define WS_SERVICE_H

#include <Arduino.h>

void initWebSocketService(const String &deviceId, bool &alarmEnabled);
void loopWebSocketService();

#endif