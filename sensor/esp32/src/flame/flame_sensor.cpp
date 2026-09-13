// flame_sensor.cpp
#include <Arduino.h>
#include "flame_sensor.h"
#include <configs.h>

void initFlameSensor() {
  pinMode(FLAME_SENSOR_PIN, INPUT);
}

bool isFlameDetected(int& analogValue, int& digitalValue) {
  analogValue = analogRead(FLAME_SENSOR_ANALOG_PIN);
  digitalValue = digitalRead(FLAME_SENSOR_PIN);
  bool detected = (digitalValue == LOW || analogValue < FLAME_ANALOG_THRESHOLD);
  return detected;
}

