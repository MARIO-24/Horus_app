import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horus_app/core/utils/validators.dart';
import 'package:horus_app/presentation/providers/auth_provider.dart';
import 'package:horus_app/presentation/providers/chatbot_provider.dart';
import 'package:horus_app/presentation/providers/routine_provider.dart';
import 'package:horus_app/presentation/providers/user_provider.dart';
import 'package:horus_app/presentation/widgets/custom_text_field.dart';
import 'package:horus_app/routes/app_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pantalla de inicio de sesión
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() {
          _rememberMe = !(prefs.getBool('prefer_no_persist') ?? false);
        });
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Guardar preferencia de sesión antes de autenticar
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.remove('prefer_no_persist');
    } else {
      await prefs.setBool('prefer_no_persist', true);
    }

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      // Capturar providers ANTES de cualquier await — el GoRouter puede
      // desmontar este widget en cuanto el auth state cambia
      final uid = authProvider.user!.uid;
      final userProvider = context.read<UserProvider>();
      final routineProvider = context.read<RoutineProvider>();
      final chatbotProvider = context.read<ChatbotProvider>();

      await userProvider.loadUser(uid);
      await routineProvider.loadRoutine(uid);
      await chatbotProvider.loadChat(uid);

      if (mounted) context.go(AppRoutes.home);
    } else {
      _showError(authProvider.errorMessage ?? 'Error al iniciar sesión');
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

  void _showForgotPasswordDialog(BuildContext context) {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Introduce tu email y te enviaremos un enlace para restablecer tu contraseña.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El email es obligatorio';
                  }
                  final re = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!re.hasMatch(v.trim())) return 'Email no válido';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogCtx);

              final email = emailCtrl.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await context
                    .read<AuthProvider>()
                    .sendPasswordResetEmail(email);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Enlace enviado a $email. Revisa tu bandeja de entrada.',
                    ),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } on Exception catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Enviar enlace'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── Logo y título ─────────────────────────────────────
                Image.asset(
                  'iconos/Logo_HorusApp.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 16),
                const Text(
                  'HorusAPP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 48),

                // ── Formulario ───────────────────────────────────────
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
                            'Iniciar Sesión',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),

                          CustomTextField(
                            label: 'Email',
                            hint: 'tu@email.com',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: Validators.validateEmail,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'Contraseña',
                            controller: _passwordCtrl,
                            obscureText: true,
                            showPasswordToggle: true,
                            prefixIcon: const Icon(Icons.lock_outline),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'La contraseña es obligatoria';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _onLogin(),
                          ),
                          const SizedBox(height: 4),

                          // ── Olvidaste tu contraseña ──────────────────
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  _showForgotPasswordDialog(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Mantener sesión ─────────────────────────
                          CheckboxListTile(
                            value: _rememberMe,
                            onChanged: (val) =>
                                setState(() => _rememberMe = val ?? true),
                            title: const Text('Mantener sesión iniciada'),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                          const SizedBox(height: 16),

                          // ── Botón de login ──────────────────────────
                          FilledButton(
                            onPressed: isLoading ? null : _onLogin,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Entrar'),
                          ),

                          const SizedBox(height: 16),

                          // ── Ir a registro ───────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('¿No tienes cuenta?'),
                              TextButton(
                                onPressed: () =>
                                    context.go(AppRoutes.register),
                                child: const Text('Regístrate'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
