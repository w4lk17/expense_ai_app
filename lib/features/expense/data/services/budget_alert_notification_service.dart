import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract class BudgetAlertNotificationService {
  Future<void> initialize();
  Future<void> requestPermissions();
  Future<void> showBudgetAlert({
    required int notificationId,
    required String title,
    required String body,
  });
}

class LocalBudgetAlertNotificationService
    implements BudgetAlertNotificationService {
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'budget_alerts',
    'Budget Alerts',
    description: 'Alerts for budget thresholds reached in Expense AI.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    _isInitialized = true;
  }

  @override
  Future<void> requestPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: false, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: false, sound: true);
  }

  @override
  Future<void> showBudgetAlert({
    required int notificationId,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'Alerts for budget thresholds reached in Expense AI.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
