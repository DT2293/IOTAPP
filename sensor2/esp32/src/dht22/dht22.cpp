// #include <Arduino.h>
// #include <Adafruit_Sensor.h>
// #include <DHT.h>              // Đây là tên file đúng cho thư viện Adafruit
// #include <DHT_U.h>            // Nếu bạn dùng Unified sensor framework
// #include "configs.h"// Giả sử bạn định nghĩa chân DHT22 trong file này
// #define DHT_TYPE DHT22

// DHT dht(DHT_SENSOR_PIN, DHT_TYPE);  // DHT_SENSOR_PIN là chân bạn gán, ví dụ GPIO4

// void initDhtSensor() {
//   dht.begin();
// }

// bool readDhtSensor(float& temperature, float& humidity) {
//   humidity = dht.readHumidity();
//   temperature = dht.readTemperature();

//   if (isnan(humidity) || isnan(temperature)) {
//     return false;  // Lỗi đọc
//   }  // Gửi độ ẩm lên V1
//   delay(2000);  // Đợi 2 giây trước khi đọc lại
//   return true;
//     // Đọc thành công
// }
