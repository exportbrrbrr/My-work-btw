import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/medicine.dart';

/// Schedules reminder notifications using only the OS's local alarm
/// clock — there is no push service, project ID, or server involved.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
  }

  /// Schedules one repeating daily alarm per HH:mm entry in
  /// [medicine.alarmTimes]. Android uses a full-screen intent so the
  /// scan-to-dismiss screen can launch over the lock screen; iOS opens
  /// the same screen when the notification is tapped (Apple does not
  /// let a third-party app force full-screen presentation).
  static Future<void> scheduleForMedicine(Medicine medicine) async {
    for (final hhmm in medicine.alarmTimes) {
      final parts = hhmm.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final id = _stableId(medicine.id, hhmm);

      await _plugin.zonedSchedule(
        id,
        'แจ้งเตือนการกินยา',
        '${medicine.name} • ${medicine.quantityPerDose} ${medicine.type}',
        _nextInstanceOf(hour, minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_reminders',
            'Medicine Reminders',
            fullScreenIntent: true, // forces the scan-to-dismiss screen open
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: const DarwinNotificationDetails(
            interruptionLevel: InterruptionLevel.critical,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // repeats daily
        payload: medicine.id,
      );
    }
  }

  static Future<void> cancelForMedicine(Medicine medicine) async {
    for (final hhmm in medicine.alarmTimes) {
      await _plugin.cancel(_stableId(medicine.id, hhmm));
    }
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static int _stableId(String medicineId, String hhmm) =>
      (medicineId + hhmm).hashCode & 0x7fffffff;
}
