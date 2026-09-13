#include <Arduino.h>
#include <Adafruit_Sensor.h>
#include <DHT.h>              
#include <DHT_U.h>            
#include "configs.h"
#define DHT_TYPE DHT22

DHT dht(DHT_SENSOR_PIN, DHT_TYPE);  

void initDhtSensor() {
  dht.begin();
}

bool readDhtSensor(float& temperature, float& humidity) {
  humidity = dht.readHumidity();
  temperature = dht.readTemperature();
  if (isnan(humidity) || isnan(temperature)) {
    return false;  
  } 
  delay(2000);  
}
