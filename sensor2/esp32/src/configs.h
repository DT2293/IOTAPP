#ifndef CONFIG_H
#define CONFIG_H

#define MQ_ANALOG_PIN 33
#define MQ_DIGITAL_PIN 13
//#define DHT22 4
// Pin definitions
#define BUZZER_PIN     15
#define FLAME_SENSOR_PIN 34
#define FLAME_SENSOR_ANALOG_PIN 32
#define DHT_SENSOR_PIN 4

#define RED_LED        27
#define YELLOW_LED     26
#define GREEN_LED      25

#define SDA_DS3231 16
#define SCL_DS3231 17


// OLED
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

// Ngưỡng phát hiện lửa
#define FLAME_ANALOG_THRESHOLD 200

// Thời gian
#define DISPLAY_INTERVAL 1000
#define BLINK_INTERVAL   500

#endif
