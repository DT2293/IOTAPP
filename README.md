Fire Alarm IoT App: A mobile IoT application built with Flutter to monitor fire hazards in real time using ESP32.

Features
  - Real-time display of temperature, humidity, and smoke level via WebSocket

  - Fire alert notifications via Firebase Cloud Messaging (FCM) even when the app is closed

  - User authentication using JWT, each user manages multiple devices (deviceId)

Technologies
  - Hardware: ESP32 + fire, temperature, humidity sensors

  - Mobile app: Flutter (with Riverpod, Dio, WebSocket, EasyLocalization)

  - Backend: Node.js (JWT auth, WebSocket, FCM push, MongoDB)

  - Cloud: Firebase for notifications

Status
Ongoing – Core features implemented, refining UI/UX and alert logic.
