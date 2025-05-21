// // led_buzzer_control.cpp
// #include <Arduino.h>
// #include <configs.h>
// #include <led_buzzer/led_buzzer_control.h>

// static bool ledsOn = false;
// static unsigned long lastBlinkTime = 0;
// static int blinkCount = 0;
// static bool blinkingDone = true;

// void initLedBuzzer() {
//   pinMode(BUZZER_PIN, OUTPUT);
//   pinMode(RED_LED, OUTPUT);
//   pinMode(YELLOW_LED, OUTPUT);
//   pinMode(GREEN_LED, OUTPUT);

//   digitalWrite(RED_LED, LOW);
//   digitalWrite(YELLOW_LED, LOW);
//   digitalWrite(GREEN_LED, LOW);
// }



// void startAlert() {
//   digitalWrite(BUZZER_PIN, HIGH);   
//   blinkingDone = false;
//   blinkCount = 0;
// }

// void stopAlert() {
//   digitalWrite(BUZZER_PIN, LOW);  
//   digitalWrite(RED_LED, LOW);
//   digitalWrite(YELLOW_LED, LOW);
//   digitalWrite(GREEN_LED, LOW);
// }


// void handleBlinking() {
//   if (blinkingDone) return;

//   unsigned long currentMillis = millis();
//   if (currentMillis - lastBlinkTime >= BLINK_INTERVAL) {
//     lastBlinkTime = currentMillis;
//     ledsOn = !ledsOn;

//     digitalWrite(RED_LED, ledsOn);
//     digitalWrite(YELLOW_LED, ledsOn);
//     digitalWrite(GREEN_LED, ledsOn);

//     if (!ledsOn) {
//       blinkCount++;
//       if (blinkCount >= 3) {
//         blinkingDone = true;
//         digitalWrite(RED_LED, LOW);
//         digitalWrite(YELLOW_LED, LOW);
//         digitalWrite(GREEN_LED, LOW);
//       }
//     }
//   }
// }
#include <Arduino.h>
#include <configs.h>
#include <led_buzzer/led_buzzer_control.h>

static unsigned long lastBlinkTime = 0;

void initLedBuzzer() {
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(YELLOW_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(RED_LED, LOW);
  digitalWrite(YELLOW_LED, LOW);
  digitalWrite(GREEN_LED, LOW);
}

void startAlert() {
  digitalWrite(BUZZER_PIN, HIGH);
  digitalWrite(RED_LED, HIGH);
  digitalWrite(YELLOW_LED, LOW);
  digitalWrite(GREEN_LED, LOW);
}

void stopAlert() {
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(RED_LED, LOW);
  digitalWrite(YELLOW_LED, LOW);
  digitalWrite(GREEN_LED, HIGH);
}

// 🟡 Khi cảm biến không hoạt động
void noSignalAlert() {
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(RED_LED, LOW);
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(YELLOW_LED, HIGH);
}
