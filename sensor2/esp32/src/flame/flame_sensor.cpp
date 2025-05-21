// flame_sensor.cpp
#include <Arduino.h>
#include "flame_sensor.h"
#include <configs.h>

void initFlameSensor() {
  pinMode(FLAME_SENSOR_PIN, INPUT);
}

// bool isFlameDetected(int& analogValue, int& digitalValue) {
//   analogValue = analogRead(FLAME_SENSOR_ANALOG_PIN);
//   digitalValue = digitalRead(FLAME_SENSOR_PIN);
//   return (digitalValue == LOW || analogValue < FLAME_ANALOG_THRESHOLD);
// }

// bool isFlameDetected(int &analogVal, int &digitalVal) {
//   analogVal = analogRead(ANALOG_FLAME_PIN);
//   digitalVal = digitalRead(DIGITAL_FLAME_PIN);
//   return digitalVal == 1;  // Giờ: 1 là cháy
// }


// bool isFlameDetected(int& analogValue, int& digitalValue) {
//   analogValue = analogRead(FLAME_SENSOR_ANALOG_PIN);
//   digitalValue = digitalRead(FLAME_SENSOR_PIN);

//   Serial.print("Analog = ");
//   Serial.print(analogValue);
//   Serial.print(", Digital = ");
//   Serial.println(digitalValue);

//   bool detected = (digitalValue == LOW || analogValue < FLAME_ANALOG_THRESHOLD);
//   Serial.print("Detected flame? ");
//   Serial.println(detected ? "YES" : "NO");

//   return detected;
// }


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

