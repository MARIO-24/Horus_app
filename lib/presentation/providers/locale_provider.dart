import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proveedor del idioma de la aplicación (español / inglés)
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale _locale = const Locale('es', 'ES');
  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_localeKey);
    if (saved != null) {
      _locale = saved == 'en' ? const Locale('en', 'US') : const Locale('es', 'ES');
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  String get languageName =>
      _locale.languageCode == 'en' ? 'English' : 'Español';
}
