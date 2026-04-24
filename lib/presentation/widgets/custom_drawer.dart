import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horus_app/presentation/providers/auth_provider.dart';
import 'package:horus_app/presentation/providers/chatbot_provider.dart';
import 'package:horus_app/presentation/providers/routine_provider.dart';
import 'package:horus_app/presentation/providers/user_provider.dart';
import 'package:horus_app/presentation/widgets/user_avatar.dart';
import 'package:horus_app/routes/app_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// Ítem del menú lateral
class _DrawerItem {
  final String label;
  final IconData icon;
  final String route;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

const List<_DrawerItem> _drawerItems = [
  _DrawerItem(label: 'Rutina', icon: Icons.fitness_center, route: AppRoutes.home),
  _DrawerItem(label: 'Cuenta', icon: Icons.person, route: AppRoutes.account),
  _DrawerItem(label: 'ChatBot', icon: Icons.chat_bubble_outline, route: AppRoutes.chatbot),
  _DrawerItem(label: 'Opciones', icon: Icons.settings, route: AppRoutes.options),
];

/// Drawer lateral reutilizable para la navegación principal de la app
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  Future<void> _pickAvatar(BuildContext context) async {
    // Capturar referencia ANTES del primer await
    final userProvider = context.read<UserProvider>();

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked == null) return;

    // Subir a Firebase Storage (gestiona la URL internamente)
    await userProvider.uploadAvatar(File(picked.path));

    // Mostrar error si falló la subida
    if (userProvider.errorMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.errorMessage!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showAvatarOptions(BuildContext context) async {
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
              await _pickAvatar(context);
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final authProvider = context.read<AuthProvider>();
    final routineProvider = context.read<RoutineProvider>();

    // Nombre: priorizar Firestore, luego Firebase Auth displayName
    final displayName = (user?.name.isNotEmpty == true)
        ? user!.name
        : (authProvider.user?.name.isNotEmpty == true
            ? authProvider.user!.name
            : 'Usuario');

    final avatarUrl = userProvider.avatarUrl;
    final isUploading = userProvider.isUploadingAvatar;

    return Drawer(
      child: Column(
        children: [
          // ── Cabecera del drawer ─────────────────────────────────────
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(user?.email ?? authProvider.user?.email ?? ''),
            currentAccountPicture: GestureDetector(
              onTap: () => _showAvatarOptions(context),
              child: Stack(
                children: [
                  UserAvatar(
                    avatarUrl: avatarUrl,
                    displayName: displayName,
                    radius: 36,
                    initialsFontSize: 28,
                  ),
                  // Indicador de subida o icono de cámara
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: isUploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Ítems de navegación ─────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _drawerItems.length,
              itemBuilder: (context, i) {
                final item = _drawerItems[i];
                final isSelected = currentRoute == item.route ||
                    (item.route == AppRoutes.home &&
                        currentRoute == AppRoutes.home);

                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor:
                      colorScheme.primary.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Cerrar drawer
                    context.go(item.route);
                  },
                );
              },
            ),
          ),

          const Divider(),

          // ── Botón cerrar sesión ─────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              await authProvider.logout();
              routineProvider.clear();
              context.read<UserProvider>().clear();
              context.read<ChatbotProvider>().clear();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
