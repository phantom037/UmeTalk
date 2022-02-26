import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationAPI {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final onNotification = BehaviorSubject<String?>();

  static Future _notificationDetails() async {
    /*
    final largeIconPath = await Utils.downloadFile("https://dlmocha.com/GameImages/MellowSik.PNG");

    final styleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        largeIcon: FilePathAndroidBitmap(largeIconPath));

     */

    return NotificationDetails(
      android: AndroidNotificationDetails(
        'full screen channel id', 'full screen channel name',
        channelDescription: 'full screen channel description',
        //priority: Priority.high,
        importance: Importance.high,
        //styleInformation: styleInformation,
        //fullScreenIntent: true
      ),
      iOS: IOSNotificationDetails(),
    );
  }

  static Future init({bool isScheduled = false}) async {
    final iOS = IOSInitializationSettings();
    final android = AndroidInitializationSettings('app_icon');
    final settings = InitializationSettings(android: android, iOS: iOS);

    //When app is closed
    final details = await _notifications.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      onNotification.add(details.payload);
    }

    await _notifications.initialize(settings,
        onSelectNotification: (payload) async {
      onNotification.add(payload);
    });

    tz.initializeTimeZones();
  }

  static Future showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async =>
      _notifications.show(id, title, body, await _notificationDetails(),
          payload: payload);

  static Future showScheduledNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
    required DateTime scheduleDate,
  }) async =>
      _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 2)),
        await _notificationDetails(),
        payload: payload,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

  static void cancel(int id) => _notifications.cancel(id);
  static void cancelAll() => _notifications.cancelAll();
}

///Notification handle
/*
                SizedBox(
                  height: 30,
                ),
                Material(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  elevation: 5.0,
                  child: Container(
                    width: 300.0,
                    child: MaterialButton(
                        child: Text(
                          "Notification",
                          style: TextStyle(color: Colors.black, fontSize: 16.0),
                        ),
                        textColor: Colors.white,
                        padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                        onPressed: () => NotificationAPI.showNotification(
                            title: "Ume_Talk",
                            body: "Hello world",
                            payload: "Yeah")),
                    margin: EdgeInsets.only(bottom: 1.0),
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                Material(
                  //Scheduled Notification
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  elevation: 5.0,
                  child: Container(
                    width: 300.0,
                    child: MaterialButton(
                        child: Text(
                          "Scheduled Notification",
                          style: TextStyle(color: Colors.black, fontSize: 16.0),
                        ),
                        textColor: Colors.white,
                        padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                        onPressed: () =>
                            NotificationAPI.showScheduledNotification(
                              title: "Ume_Talk",
                              body: "Hello world",
                              payload: "Yeah",
                              scheduleDate:
                                  DateTime.now().add(Duration(seconds: 2)),
                            )),
                    margin: EdgeInsets.only(bottom: 1.0),
                  ),
                ),

                SizedBox(
                  height: 30,
                ),
                Material(
                  //Scheduled Notification
                  color: Colors.yellowAccent,
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  elevation: 5.0,
                  child: Container(
                    width: 300.0,
                    child: MaterialButton(
                        child: Text(
                          "FCM Notification",
                          style: TextStyle(color: Colors.black, fontSize: 16.0),
                        ),
                        textColor: Colors.black,
                        padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                        onPressed: () =>
                            _fcmNotificationService.sendNotificationToUser(
                              title: 'From Ume Talk',
                              body: 'You received a new message',
                              fcmToken: deviceToken,
                            )),
                    margin: EdgeInsets.only(bottom: 1.0),
                  ),
                ),
                 */
