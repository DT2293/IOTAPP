// flame_sensor.h
#ifndef FLAME_SENSOR_H
#define FLAME_SENSOR_H

void initFlameSensor();
bool isFlameDetected(int& analogValue, int& digitalValue);

#endif
