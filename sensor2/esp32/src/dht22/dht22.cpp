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
    // Serial.print("Độ ẩm: ");
    // Serial.print(humidity);
    // Serial.print("%, Nhiệt độ: ");
    // Serial.print(temperature);
    // Serial.println("°C");
  if (isnan(humidity) || isnan(temperature)) {
   // Serial.println("❌ Lỗi đọc cảm biến DHT22!");
    return false;  // Lỗi đọc
  } 
   // Gửi độ ẩm lên V1
  delay(2000);  // Đợi 2 giây trước khi đọc lại
  return true;
    // Đọc thành công
}
