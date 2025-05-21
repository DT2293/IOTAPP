// rtc_manager.cpp
#include "rtc_manager.h"
#include <configs.h>

RTC_DS3231 rtc;
TwoWire I2C_DS3231 = TwoWire(1);

void initRTC() {
  I2C_DS3231.begin(SDA_DS3231, SCL_DS3231, 100000);
  if (!rtc.begin(&I2C_DS3231)) {
    Serial.println("Không tìm thấy DS3231!");
    while (1);
  }
  //rtc.adjust(DateTime(2025, 5, 19, 22, 12, 30)); // Chỉ chạy 1 lần nếu cần
}

DateTime getCurrentTime() {
  return rtc.now();
}
