import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horus_app/core/l10n/app_l10n.dart';
import 'package:horus_app/core/utils/validators.dart';
import 'package:horus_app/presentation/providers/auth_provider.dart';
import 'package:horus_app/presentation/providers/chatbot_provider.dart';
import 'package:horus_app/presentation/providers/routine_provider.dart';
import 'package:horus_app/presentation/providers/user_provider.dart';
import 'package:horus_app/presentation/widgets/custom_text_field.dart';
import 'package:horus_app/routes/app_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// Pantalla de registro de nuevo usuario
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  File? _avatarFile; // foto seleccionada antes del registro

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked == null) return;
    setState(() => _avatarFile = File(picked.path));
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final routineProvider = context.read<RoutineProvider>();
    final avatarFile = _avatarFile;

    final success = await authProvider.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    // NO comprobar mounted aquí — las operaciones de datos no necesitan
    // el widget montado y el router puede haberlo desmontado ya
    if (success) {
      final uid = authProvider.user!.uid;
      // Capturar chatbotProvider ANTES del primer await
      final chatbotProvider = context.read<ChatbotProvider>();

      await userProvider.loadUser(uid);
      await routineProvider.loadRoutine(uid);
      await chatbotProvider.loadChat(uid);

      // Subir avatar a Firebase Storage (no necesita mounted)
      if (avatarFile != null) {
        await userProvider.uploadAvatar(avatarFile);
      }

      if (mounted) context.go(AppRoutes.home);
    } else if (mounted) {
      _showError(authProvider.errorMessage ?? 'Error al registrarse');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = context.watch<AuthProvider>().isLoading;
    final l10n = AppL10n.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.35],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ── Botón atrás + título ─────────────────────────────
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white),
                      onPressed: () => context.go(AppRoutes.login),
                    ),
                    Expanded(
                      child: Text(
                        l10n.registerTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Formulario de registro ───────────────────────────
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.joinTitle,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.joinSubtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // ── Foto de perfil (opcional) ───────────────
                          Center(
                            child: GestureDetector(
                              onTap: _pickAvatar,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 48,
                                    backgroundColor: colorScheme.primaryContainer,
                                    backgroundImage: _avatarFile != null
                                        ? FileImage(_avatarFile!)
                                        : null,
                                    child: _avatarFile == null
                                        ? Icon(
                                            Icons.person,
                                            size: 48,
                                            color: colorScheme.onPrimaryContainer,
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Foto de perfil (opcional)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Nombre
                          CustomTextField(
                            label: l10n.nameLabel,
                            hint: l10n.nameHint,
                            controller: _nameCtrl,
                            prefixIcon: const Icon(Icons.person_outline),
                            validator: Validators.validateName,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),

                          // Email
                          CustomTextField(
                            label: l10n.emailLabel,
                            hint: l10n.emailHint,
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: Validators.validateEmail,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),

                          // Contraseña
                          CustomTextField(
                            label: l10n.passwordLabel,
                            hint: 'Mín. 8 caracteres',
                            controller: _passwordCtrl,
                            obscureText: true,
                            showPasswordToggle: true,
                            prefixIcon: const Icon(Icons.lock_outline),
                            validator: Validators.validatePassword,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),

                          // Confirmar contraseña
                          CustomTextField(
                            label: l10n.confirmPassword,
                            controller: _confirmCtrl,
                            obscureText: true,
                            showPasswordToggle: true,
                            prefixIcon: const Icon(Icons.lock_outline),
                            validator: (v) => Validators.validateConfirmPassword(
                              v,
                              _passwordCtrl.text,
                            ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _onRegister(),
                          ),
                          const SizedBox(height: 28),

                          // ── Botón registrarse ───────────────────────
                          FilledButton(
                            onPressed: isLoading ? null : _onRegister,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.registerButton),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.alreadyAccount),
                              TextButton(
                                onPressed: () =>
                                    context.go(AppRoutes.login),
                                child: Text(l10n.loginLink),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
