import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:horus_app/core/l10n/app_l10n.dart';
import 'package:horus_app/presentation/providers/auth_provider.dart';
import 'package:horus_app/presentation/providers/chatbot_provider.dart';
import 'package:horus_app/presentation/providers/locale_provider.dart';
import 'package:horus_app/presentation/providers/notification_provider.dart';
import 'package:horus_app/presentation/providers/routine_provider.dart';
import 'package:horus_app/presentation/providers/theme_provider.dart';
import 'package:horus_app/presentation/providers/user_provider.dart';
import 'package:horus_app/presentation/widgets/custom_drawer.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de opciones/configuración
class OptionsScreen extends StatelessWidget {
  const OptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppL10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('iconos/Icono_Opciones.png', width: 28, height: 28),
            const SizedBox(width: 10),
            Text(l10n.settings),
          ],
        ),
      ),
      drawer: const CustomDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Apariencia ─────────────────────────────────────────────────
          _SectionHeader(title: l10n.appearance, icon: Icons.palette_outlined),
          Card(
            child: Column(
              children: ThemeMode.values.map((mode) {
                final label = _themeModeLabel(mode, l10n);
                final icon = _themeModeIcon(mode);
                final isSelected = themeProvider.themeMode == mode;

                return RadioListTile<ThemeMode>(
                  value: mode,
                  groupValue: themeProvider.themeMode,
                  title: Text(label),
                  secondary: Icon(icon),
                  onChanged: (v) {
                    if (v != null) themeProvider.setThemeMode(v);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  selected: isSelected,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // ── Idioma ──────────────────────────────────────────────────
          _SectionHeader(title: l10n.language, icon: Icons.language),
          Card(
            child: Column(
              children: [
                RadioListTile<Locale>(
                  value: const Locale('es', 'ES'),
                  groupValue: localeProvider.locale,
                  title: Text(l10n.spanish),
                  secondary: const Text('🇪🇸', style: TextStyle(fontSize: 20)),
                  onChanged: (v) {
                    if (v != null) localeProvider.setLocale(v);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  selected: localeProvider.locale.languageCode == 'es',
                ),
                RadioListTile<Locale>(
                  value: const Locale('en', 'GB'),
                  groupValue: localeProvider.locale,
                  title: Text(l10n.english),
                  secondary: const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                  onChanged: (v) {
                    if (v != null) localeProvider.setLocale(v);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  selected: localeProvider.locale.languageCode == 'en',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Notificaciones ─────────────────────────────────────────────
          _SectionHeader(title: l10n.notificationsSection, icon: Icons.notifications_outlined),
          _NotificationsCard(l10n: l10n),
          const SizedBox(height: 24),

          // ── Rutina ─────────────────────────────────────────────────────
          _SectionHeader(title: l10n.routineSection, icon: Icons.fitness_center),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.orange),
                  title: Text(l10n.deleteRoutine),
                  subtitle: Text(l10n.deleteRoutineSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _showDeleteRoutineDialog(context, l10n),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Cuenta ─────────────────────────────────────────────────────
          _SectionHeader(title: l10n.accountSection, icon: Icons.person_outline),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.blue),
                  title: Text(l10n.logout),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLogoutDialog(context, l10n),
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  leading: const Icon(Icons.delete_forever,
                      color: Colors.red),
                  title: Text(
                    l10n.deleteAccount,
                    style: const TextStyle(color: Colors.red),
                  ),
                  subtitle: Text(
                    l10n.deleteAccountSubtitle,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _showDeleteAccountDialog(context, l10n),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Acerca de ─────────────────────────────────────────────────
          _SectionHeader(title: l10n.about, icon: Icons.info_outline),
          Card(
            child: Column(
              children: [
                _InfoTile(title: l10n.appNameLabel, value: 'HorusAPP v1.1.0'),
                const Divider(height: 1, indent: 16),
                _InfoTile(title: l10n.developer, value: 'Rufito'),
                const Divider(height: 1, indent: 16),
                _InfoTile(title: l10n.project, value: 'TFG — Grado Superior DAM'),
                const Divider(height: 1, indent: 16),
                _InfoTile(title: l10n.technologies, value: 'Flutter · Firebase · Gemini AI'),
                const Divider(height: 1, indent: 16),
                _InfoTile(title: l10n.architecture, value: 'Clean Architecture · Provider'),
                const Divider(height: 1, indent: 16),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: Text(l10n.sourceCode),
                  subtitle: const Text('github.com/MARIO-24/Horus_app',
                      style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse('https://github.com/MARIO-24/Horus_app'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode, AppL10n l10n) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }

  IconData _themeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  void _showDeleteRoutineDialog(BuildContext context, AppL10n l10n) {
    final routineProvider = context.read<RoutineProvider>();
    if (!routineProvider.hasRoutine) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.noActiveRoutine)));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteRoutineTitle),
        content: Text(l10n.deleteRoutineBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(context);
              final uid = context.read<AuthProvider>().user!.uid;
              await routineProvider.deleteRoutine(uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.routineDeleted),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(l10n.deleteConfirm),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppL10n l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              context.read<RoutineProvider>().clear();
              context.read<UserProvider>().clear();
              context.read<ChatbotProvider>().clear();
            },
            child: Text(l10n.logoutConfirm),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AppL10n l10n) {
    final passwordCtrl = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l10n.deleteAccountTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteAccountWarning),
              const SizedBox(height: 16),
              Text(
                l10n.enterPasswordConfirm,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: l10n.passwordHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final password = passwordCtrl.text;
                if (password.isEmpty) return;
                Navigator.pop(dialogCtx);

                final messenger = ScaffoldMessenger.of(context);
                try {
                  final firebaseUser = FirebaseAuth.instance.currentUser!;
                  final uid = firebaseUser.uid;
                  final email = firebaseUser.email!;

                  final credential = EmailAuthProvider.credential(
                    email: email,
                    password: password,
                  );
                  await firebaseUser.reauthenticateWithCredential(credential);

                  await context.read<UserProvider>().deleteFullAccount(uid);
                  await context.read<RoutineProvider>().deleteRoutine(uid);
                  await firebaseUser.delete();

                  if (context.mounted) {
                    context.read<AuthProvider>().logout();
                    context.read<RoutineProvider>().clear();
                    context.read<ChatbotProvider>().clear();
                  }
                } on FirebaseAuthException catch (e) {
                  final msg = e.code == 'wrong-password' ||
                          e.code == 'invalid-credential'
                      ? l10n.wrongPassword
                      : l10n.deleteAccountError(e.message ?? '');
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.unexpectedError(e.toString())),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(l10n.deleteConfirm),
            ),
          ],
        ),
      ),
    );
  }
} // end _OptionsScreenState

/// Encabezado de sección
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: isLight ? colorScheme.onSurface : colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLight ? colorScheme.onSurface : colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── Tarjeta de notificaciones ────────────────────────────────────────────────
class _NotificationsCard extends StatelessWidget {
  final AppL10n l10n;
  const _NotificationsCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final isEnglish = AppL10n.of(context).isEnglish;

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              notifProvider.enabled
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color: notifProvider.enabled ? Colors.orange : null,
            ),
            title: Text(l10n.dailyReminder),
            subtitle: Text(l10n.dailyReminderSubtitle),
            value: notifProvider.enabled,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (v) async {
              final granted =
                  await notifProvider.setEnabled(v, isEnglish: isEnglish);
              if (!granted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.notifPermissionDenied),
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          if (notifProvider.enabled) ...[
            const Divider(height: 1, indent: 16),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.orange),
              title: Text(l10n.reminderTime),
              trailing: Text(
                '${notifProvider.hour.toString().padLeft(2, '0')}:'
                '${notifProvider.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                ),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: notifProvider.timeOfDay,
                );
                if (picked != null && context.mounted) {
                  await notifProvider.setTime(
                    picked.hour,
                    picked.minute,
                    isEnglish: isEnglish,
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
