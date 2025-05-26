// mq_sensor.cpp
#include <Arduino.h>
#include "mq_sensor.h"
#include <configs.h>


void initMQSensor() {
  pinMode(MQ_DIGITAL_PIN, INPUT);
}

void readMQSensor(int& analogValue, int& digitalValue) {
  analogValue = analogRead(MQ_ANALOG_PIN);
  digitalValue = digitalRead(MQ_DIGITAL_PIN);
}
