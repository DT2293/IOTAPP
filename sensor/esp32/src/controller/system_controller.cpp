#include "system_controller.h"
#include "rtc/rtc_manager.h"
#include "display/display_manager.h"
#include "flame/flame_sensor.h"
#include "led_buzzer/led_buzzer_control.h"
#include "mq2/mq_sensor.h"
#include "dht22/dht22.h"
#include "api_service.h"

static int currentGasAnalog = 0;
static int currentGasDigital = 0;
static bool currentFlameDetected = false;
static float currentTemperature = 0.0;
static float currentHumidity = 0.0;

static unsigned long lastSensorRead = 0;
static const unsigned long sensorInterval = 2000;

static unsigned long lastAlertCheck = 0;
static const unsigned long alertInterval = 500;

bool alarmEnabled = true;

void initSystemSensors()
{
    initRTC();
    initDisplay();
    initFlameSensor();
    initLedBuzzer();
    initDhtSensor();
    digitalWrite(BUZZER_PIN, LOW);
}

void processSystemTasks(const String &deviceId)
{
    unsigned long currentMillis = millis();
    if (currentMillis - lastAlertCheck >= alertInterval)
    {
        lastAlertCheck = currentMillis;

        readMQSensor(currentGasAnalog, currentGasDigital);
        int analogFlameVal, digitalFlameVal;
        currentFlameDetected = isFlameDetected(analogFlameVal, digitalFlameVal);

        bool gasLeaked = (currentGasAnalog > 300 || currentGasDigital == LOW);

        if (currentGasAnalog > 4095 || currentGasAnalog < 0 || currentGasDigital == -1)
        {
            noSignalAlert();
        }
        else if (currentFlameDetected || gasLeaked)
        {
            if (alarmEnabled)
                startAlert();
            else
                stopAlert();
        }
        else
        {
            stopAlert();
        }

        updateDisplay(currentFlameDetected);
    }

    if (currentMillis - lastSensorRead >= sensorInterval)
    {
        lastSensorRead = currentMillis;

        bool dhtSuccess = readDhtSensor(currentTemperature, currentHumidity);
        if (dhtSuccess)
        {
            sendDataToServer(deviceId, currentGasAnalog, currentFlameDetected, currentTemperature, currentHumidity);
        }
        else
        {
            sendDataToServer(deviceId, currentGasAnalog, currentFlameDetected);
        }
    }
}