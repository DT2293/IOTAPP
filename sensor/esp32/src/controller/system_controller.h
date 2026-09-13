#ifndef SYSTEM_CONTROLLER_H
#define SYSTEM_CONTROLLER_H

#include <Arduino.h>

void initSystemSensors();
void processSystemTasks(const String &deviceId);

#endif