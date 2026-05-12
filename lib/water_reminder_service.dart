import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:waterdays/app_localizations.dart';
import 'package:waterdays/water_state.dart';

abstract class WaterReminderService {
  Future<void> initialize();

  Future<void> requestPermissions();

  Future<void> syncReminder({
    required WaterTrackerState state,
    required AppLocalizations l10n,
  });
}

class LocalWaterReminderService implements WaterReminderService {
  LocalWaterReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings);
    _isInitialized = true;
  }

  @override
  Future<void> requestPermissions() async {
    if (!_isInitialized) {
      return;
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> syncReminder({
    required WaterTrackerState state,
    required AppLocalizations l10n,
  }) async {
    if (!_isInitialized) {
      return;
    }

    await _plugin.cancel(_Ids.dailyReminder);

    if (!state.hasStartedTracking || state.isGoalComplete) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);

    if (!scheduled.isAfter(now)) {
      scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, 20);
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _Channels.dailyReminderId,
        _Channels.dailyReminderName,
        channelDescription: _Channels.dailyReminderDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _Ids.dailyReminder,
      l10n.reminderTitle,
      l10n.reminderBody(
        currentCups: state.drankCups,
        remainingCups: state.remainingCups,
      ),
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

class NoopWaterReminderService implements WaterReminderService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> syncReminder({
    required WaterTrackerState state,
    required AppLocalizations l10n,
  }) async {}
}

class _Ids {
  const _Ids._();

  static const dailyReminder = 1204;
}

class _Channels {
  const _Channels._();

  static const dailyReminderId = 'waterdays_daily_reminder';
  static const dailyReminderName = 'Daily reminder';
  static const dailyReminderDescription =
      'Friendly evening reminders for unfinished water goals.';
}
