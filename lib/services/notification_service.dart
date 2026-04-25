import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Servicio de notificaciones locales para HorusAPP.
/// Gestiona el permiso y la notificación diaria de recordatorio de entrenamiento.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'horus_daily_reminder';
  static const _channelName = 'Recordatorio de entrenamiento';
  static const _channelDescription =
      'Notificación diaria para recordar al usuario que debe entrenar';
  static const _notificationId = 1;

  /// Inicializa el plugin. Llamar una sola vez al arrancar la app.
  static Future<void> init() async {
    tz.initializeTimeZones();
    // Fijar la zona horaria local real del dispositivo
    final String localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
    debugPrint('[NotificationService] Zona horaria: $localTz');
  }

  /// Solicita permiso de notificaciones (Android 13+).
  /// Devuelve true si el permiso fue concedido o ya estaba concedido.
  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Comprueba si el permiso de notificaciones está concedido.
  static Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Devuelve true si el permiso fue denegado permanentemente
  /// (el usuario marcó "No volver a preguntar").
  static Future<bool> isPermanentlyDenied() async {
    final status = await Permission.notification.status;
    return status.isPermanentlyDenied;
  }

  /// Programa una notificación diaria a la hora indicada [hour]:[minute].
  /// Por defecto: 09:00.
  static Future<void> scheduleDailyReminder({
    int hour = 9,
    int minute = 0,
    bool isEnglish = false,
  }) async {
    await _plugin.cancel(_notificationId);

    final title = isEnglish
        ? '💪 Time to train, champion!'
        : '💪 ¡Hora de entrenar, campeón!';
    final body = isEnglish
        ? 'Your daily workout is waiting for you. Don\'t break the streak!'
        : 'Tu entrenamiento diario te está esperando. ¡No rompas la racha!';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );
    const details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // Si ya pasó la hora de hoy, programar para mañana
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _notificationId,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repite diariamente
    );
    debugPrint('[NotificationService] Notificación diaria programada a las $hour:${minute.toString().padLeft(2, '0')}');
  }

  /// Cancela la notificación diaria.
  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_notificationId);
    debugPrint('[NotificationService] Notificación diaria cancelada');
  }
}
