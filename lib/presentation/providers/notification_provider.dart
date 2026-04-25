import 'package:flutter/material.dart';
import 'package:horus_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kNotifEnabled = 'notif_enabled';
const _kNotifHour = 'notif_hour';
const _kNotifMinute = 'notif_minute';

/// Gestiona el estado del toggle de notificaciones y la hora programada.
class NotificationProvider extends ChangeNotifier {
  bool _enabled = false;
  int _hour = 9;
  int _minute = 0;

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;
  TimeOfDay get timeOfDay => TimeOfDay(hour: _hour, minute: _minute);

  /// Carga el estado persistido desde SharedPreferences.
  Future<void> load({bool isEnglish = false}) async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kNotifEnabled) ?? false;
    _hour = prefs.getInt(_kNotifHour) ?? 9;
    _minute = prefs.getInt(_kNotifMinute) ?? 0;

    // Si estaba activado, reprogramar al arrancar (por si se mató el proceso)
    if (_enabled) {
      final hasPermission = await NotificationService.hasPermission();
      if (hasPermission) {
        await NotificationService.scheduleDailyReminder(
          hour: _hour,
          minute: _minute,
          isEnglish: isEnglish,
        );
      } else {
        _enabled = false;
        await prefs.setBool(_kNotifEnabled, false);
      }
    }
    notifyListeners();
  }

  /// Activa o desactiva la notificación diaria.
  Future<bool> setEnabled(bool value, {bool isEnglish = false}) async {
    if (value) {
      // Comprobar si ya tiene permiso antes de solicitarlo
      final alreadyGranted = await NotificationService.hasPermission();
      if (!alreadyGranted) {
        final granted = await NotificationService.requestPermission();
        if (!granted) return false; // el usuario denegó el permiso
      }
      await NotificationService.scheduleDailyReminder(
        hour: _hour,
        minute: _minute,
        isEnglish: isEnglish,
      );
    } else {
      await NotificationService.cancelDailyReminder();
    }

    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifEnabled, value);
    notifyListeners();
    return true;
  }

  /// Cambia la hora de la notificación.
  Future<void> setTime(int hour, int minute, {bool isEnglish = false}) async {
    _hour = hour;
    _minute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kNotifHour, hour);
    await prefs.setInt(_kNotifMinute, minute);

    if (_enabled) {
      await NotificationService.scheduleDailyReminder(
        hour: _hour,
        minute: _minute,
        isEnglish: isEnglish,
      );
    }
    notifyListeners();
  }
}
