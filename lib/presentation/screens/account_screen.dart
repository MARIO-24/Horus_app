import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horus_app/presentation/providers/auth_provider.dart';
import 'package:horus_app/presentation/providers/chatbot_provider.dart';
import 'package:horus_app/presentation/providers/routine_provider.dart';
import 'package:horus_app/presentation/providers/user_provider.dart';
import 'package:horus_app/presentation/widgets/custom_drawer.dart';
import 'package:horus_app/presentation/widgets/user_avatar.dart';
import 'package:horus_app/routes/app_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Pantalla de cuenta — muestra información del usuario y permite editarla
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // ── Foto de perfil ──────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final userProvider = context.read<UserProvider>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked == null) return;
    await userProvider.uploadAvatar(File(picked.path));
    if (!mounted) return;
    if (userProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.errorMessage!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showAvatarOptions() async {
    final userProvider = context.read<UserProvider>();
    final hasPhoto = userProvider.avatarUrl != null;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Cambiar foto'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              await _pickAvatar();
            },
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar foto',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetCtx);
                userProvider.removeAvatar();
              },
            ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancelar'),
            onTap: () => Navigator.pop(sheetCtx),
          ),
        ],
      ),
    );
  }

  // ── Nombre ──────────────────────────────────────────────────────────────

  Future<void> _showEditNameDialog(String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = ctrl.text.trim();
              if (trimmed.isNotEmpty) Navigator.pop(context, trimmed);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      final ok = await context.read<UserProvider>().updateName(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Nombre actualizado' : 'Error al guardar el nombre'),
          backgroundColor: ok ? null : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Diálogos de confirmación ─────────────────────────────────────────────

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              context.read<RoutineProvider>().clear();
              context.read<UserProvider>().clear();
              context.read<ChatbotProvider>().clear();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordCtrl = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Eliminar cuenta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ Esta acción es permanente. Se eliminarán tu cuenta y todos tus datos.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Introduce tu contraseña para confirmar:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
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
              child: const Text('Cancelar'),
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
                  await context.read<ChatbotProvider>().deleteChat(uid);
                  await firebaseUser.delete();

                  if (context.mounted) {
                    context.read<AuthProvider>().logout();
                    context.read<RoutineProvider>().clear();
                    context.read<UserProvider>().clear();
                    context.read<ChatbotProvider>().clear();
                  }
                } on FirebaseAuthException catch (e) {
                  final msg = e.code == 'wrong-password' ||
                          e.code == 'invalid-credential'
                      ? 'Contraseña incorrecta'
                      : 'Error al eliminar la cuenta: ${e.message}';
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error inesperado: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final authProvider = context.read<AuthProvider>();
    final avatarUrl = userProvider.avatarUrl;
    final isUploading = userProvider.isUploadingAvatar;
    final routineProvider = context.watch<RoutineProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final displayName = (user?.name.isNotEmpty == true)
        ? user!.name
        : (authProvider.user?.name.isNotEmpty == true
            ? authProvider.user!.name
            : 'Atleta');

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Cuenta')),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Avatar + nombre ─────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar con botón de edición superpuesto
                    GestureDetector(
                      onTap: _showAvatarOptions,
                      child: Stack(
                        children: [
                          UserAvatar(
                            avatarUrl: avatarUrl,
                            displayName: displayName,
                            radius: 50,
                            initialsFontSize: 44,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: colorScheme.surface, width: 2),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt,
                                      size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nombre con botón de editar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.edit,
                              size: 20, color: colorScheme.primary),
                          tooltip: 'Editar nombre',
                          onPressed: () => _showEditNameDialog(displayName),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? authProvider.user?.email ?? '',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    if (user?.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Miembro desde ${DateFormat('MMMM yyyy', 'es').format(user!.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Datos de la rutina ──────────────────────────────────────
            if (routineProvider.hasRoutine) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fitness_center,
                              color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Rutina activa',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                          label: 'Objetivo',
                          value: routineProvider.routine!.goal),
                      _InfoRow(
                          label: 'Nivel',
                          value: routineProvider.routine!.fitnessLevel),
                      _InfoRow(
                          label: 'Dónde entrenas',
                          value: routineProvider.routine!.trainingLocation),
                      _InfoRow(
                          label: 'Días/semana',
                          value:
                              '${routineProvider.routine!.daysPerWeek} días'),
                      _InfoRow(
                          label: 'Peso',
                          value:
                              '${routineProvider.routine!.weight.toStringAsFixed(1)} kg'),
                      _InfoRow(
                          label: 'Altura',
                          value:
                              '${routineProvider.routine!.height.toStringAsFixed(0)} cm'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Acciones ────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Acciones',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.routineForm),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generar nueva rutina'),
                    ),
                    const SizedBox(height: 10),

                    OutlinedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                    const SizedBox(height: 10),

                    TextButton.icon(
                      onPressed: _showDeleteAccountDialog,
                      icon: const Icon(Icons.delete_forever,
                          color: Colors.red),
                      label: const Text(
                        'Eliminar cuenta',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
