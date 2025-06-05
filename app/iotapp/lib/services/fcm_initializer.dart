 import 'package:flutter_local_notifications/flutter_local_notifications.dart';
 import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iotapp/main.dart';
import 'package:iotapp/theme/message_provider.dart';
import 'package:provider/provider.dart';
import 'package:iotapp/models/message_model.dart' as myModel;
class FCMInitializer {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _fcm.requestPermission();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Đúng: gọi function toàn cục
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground
    FirebaseMessaging.onMessage.listen(_showNotification);

    // Khi mở app từ thông báo
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Opened app from notification: ${message.notification?.title}');
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'iot_alerts_channel',
      'IoT Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      notification.title,
      notification.body,
      platformDetails,
    );

    final context = navigatorKey.currentContext;
  if (context != null) {
   Provider.of<MessageProvider>(context, listen: false).addMessage(
  myModel.Message(
    title: notification.title ?? 'Thông báo',
    content: notification.body ?? '',
    timestamp: DateTime.now(),
    isRead: false,
  ),
);

  }
  }


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📩 Background message: ${message.notification?.title}");

//  Khởi tạo plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: android);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  const androidDetails = AndroidNotificationDetails(
    'iot_alerts_channel',
    'IoT Alerts',
    importance: Importance.max,
    priority: Priority.high,
  );
  const platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? '🔥 Cảnh báo',
    message.notification?.body ?? '',
    platformDetails,
  ); 
}
}