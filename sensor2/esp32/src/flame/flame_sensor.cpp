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
  // Serial.print("Debug analog: ");
  // Serial.print(analogValue);
  // Serial.print(", digital: ");
  // Serial.println(digitalValue);
  bool detected = (digitalValue == LOW || analogValue < FLAME_ANALOG_THRESHOLD);
//  Serial.print("Detected: ");
 // Serial.println(detected ? "YES" : "NO");
  return detected;
}

