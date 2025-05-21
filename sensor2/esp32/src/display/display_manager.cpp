// display_manager.cpp
#include <Wire.h>
#include <Adafruit_SSD1306.h>
#include <configs.h>
#include <RTClib.h>
#include <rtc/rtc_manager.h>
#include <QRCode.h>

extern Adafruit_SSD1306 display;

unsigned long lastDisplayUpdate = 0;

void initDisplay() {
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("Không tìm thấy màn hình OLED!");
    while (true);  // Dừng chương trình nếu không có màn hình
  }

  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("OLED sẵn sàng");
  display.display();
}


void updateDisplay(bool isFlame) {
  unsigned long currentMillis = millis();
  if (currentMillis - lastDisplayUpdate >= DISPLAY_INTERVAL) {
    lastDisplayUpdate = currentMillis;

    DateTime now = getCurrentTime();

    display.clearDisplay();
    display.setCursor(0, 0);
    display.print("Time: ");
    display.printf("%02d:%02d:%02d", now.hour(), now.minute(), now.second());

    display.setCursor(0, 10);
    display.print("Date: ");
    display.printf("%02d/%02d/%04d", now.day(), now.month(), now.year());

    if (isFlame) {
      display.setCursor(0, 25);
      display.setTextSize(2);
      display.setTextColor(WHITE);
      display.print("CHAY !!!");
      display.setTextSize(1);  
    }

    display.display();
  }
}


 void showQRCode(const String &data) {
  QRCode qrcode;
  uint8_t qrcodeData[qrcode_getBufferSize(3)];

  qrcode_initText(&qrcode, qrcodeData, 3, ECC_LOW, data.c_str());

  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  int offset_x = 20;
  int offset_y = 0;
  int scale = 2;

  for (uint8_t y = 0; y < qrcode.size; y++) {
    for (uint8_t x = 0; x < qrcode.size; x++) {
      if (qrcode_getModule(&qrcode, x, y)) {
        display.fillRect(offset_x + x * scale, offset_y + y * scale, scale, scale, SSD1306_WHITE);
      }
    }
  }

  display.display();
}