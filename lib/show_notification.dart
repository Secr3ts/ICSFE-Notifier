import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void showNotification(String head, String body, String name) async {
  if (head.contains(name)) {return;}
  
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('69', 'icalmabite',
          channelDescription: 'tounsgay',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');

  const DarwinNotificationDetails iosPlatform = DarwinNotificationDetails();
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics, iOS: iosPlatform);

  await FlutterLocalNotificationsPlugin().show(
    0,
    head,
    body,
    platformChannelSpecifics,
    payload: 'item x',
  );
}
