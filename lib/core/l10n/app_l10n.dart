import 'package:flutter/material.dart';
import 'package:horus_app/presentation/providers/locale_provider.dart';
import 'package:provider/provider.dart';

/// Localizaciones simples para la aplicación (ES / EN).
/// Uso: `final l10n = AppL10n.of(context);` dentro de un método build.
class AppL10n {
  final bool _en;
  const AppL10n._(this._en);

  /// Obtiene la instancia correcta según el idioma del [LocaleProvider].
  static AppL10n of(BuildContext context) =>
      AppL10n._(context.watch<LocaleProvider>().locale.languageCode == 'en');

  // ── Navegación ────────────────────────────────────────────────────────────
  String get settings       => _en ? 'Settings'    : 'Opciones';
  String get routine        => _en ? 'My Routine'  : 'Mi Rutina';
  String get account        => _en ? 'My Account'  : 'Mi Cuenta';

  // ── Apariencia ────────────────────────────────────────────────────────────
  String get appearance     => _en ? 'Appearance'        : 'Apariencia';
  String get themeLight     => _en ? 'Light'             : 'Claro';
  String get themeDark      => _en ? 'Dark'              : 'Oscuro';
  String get themeSystem    => _en ? 'System (default)'  : 'Sistema (por defecto)';

  // ── Idioma ────────────────────────────────────────────────────────────────
  String get language       => _en ? 'Language'  : 'Idioma';
  String get spanish        => _en ? 'Spanish'   : 'Español';
  String get english        => 'English';

  // ── Rutina ────────────────────────────────────────────────────────────────
  String get routineSection          => _en ? 'Routine'                          : 'Rutina';
  String get deleteRoutine           => _en ? 'Delete current routine'           : 'Eliminar rutina actual';
  String get deleteRoutineSubtitle   => _en ? 'You can generate a new routine anytime' : 'Podrás generar una nueva rutina cuando quieras';

  // ── Cuenta ────────────────────────────────────────────────────────────────
  String get accountSection          => _en ? 'Account'                          : 'Cuenta';
  String get logout                  => _en ? 'Log out'                          : 'Cerrar sesión';
  String get deleteAccount           => _en ? 'Delete account'                   : 'Eliminar cuenta';
  String get deleteAccountSubtitle   => _en ? 'This action is permanent and irreversible' : 'Esta acción es permanente e irreversible';

  // ── Acerca de ─────────────────────────────────────────────────────────────
  String get about          => _en ? 'About'          : 'Acerca de';
  String get appNameLabel   => _en ? 'Application'    : 'Aplicación';
  String get developer      => _en ? 'Developer'      : 'Desarrollador';
  String get project        => _en ? 'Project'        : 'Proyecto';
  String get technologies   => _en ? 'Technologies'   : 'Tecnologías';
  String get architecture   => _en ? 'Architecture'   : 'Arquitectura';
  String get sourceCode     => _en ? 'Source code'    : 'Código fuente';

  // ── ChatBot ───────────────────────────────────────────────────────────────
  String get virtualTrainer => _en ? 'Virtual trainer' : 'Entrenador virtual';
  String get typing         => _en ? 'Typing...'       : 'Escribiendo...';
}
