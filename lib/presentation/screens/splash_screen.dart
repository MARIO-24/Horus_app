import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horus_app/core/l10n/app_l10n.dart';
import 'package:horus_app/presentation/providers/chatbot_provider.dart';
import 'package:horus_app/presentation/providers/locale_provider.dart';
import 'package:horus_app/presentation/providers/routine_provider.dart';
import 'package:horus_app/presentation/providers/user_provider.dart';
import 'package:horus_app/routes/app_router.dart';
import 'package:provider/provider.dart';

/// Pantalla de carga inicial — muestra el logo y una frase motivadora
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // La frase se selecciona una vez al construirse el estado
  late int _phraseIndex;

  @override
  void initState() {
    super.initState();

    _phraseIndex = Random().nextInt(12); // 12 frases en AppL10n

    // Configurar animaciones de entrada
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // Navegar tras 3.5 segundos
    Future.delayed(const Duration(milliseconds: 3500), _navigate);
  }

  void _navigate() async {
    if (!mounted) return;

    // Si hay sesión activa, cargar los datos antes de navegar a home
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      await context.read<UserProvider>().loadUser(firebaseUser.uid);
      await context.read<RoutineProvider>().loadRoutine(firebaseUser.uid);
      await context.read<ChatbotProvider>().loadChat(firebaseUser.uid);
    }

    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usar el idioma actual para la frase motivacional
    final l10n = AppL10n._(
      context.watch<LocaleProvider>().locale.languageCode == 'en',
    );
    final phrase = l10n.motivationalPhrases[_phraseIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              const Color(0xFF1A1A2E),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Image.asset(
                      'iconos/Logo_HorusApp.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      '"$phrase"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pantalla de carga inicial — muestra el logo y una frase motivadora
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones de entrada
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // Navegar tras 3.5 segundos
    Future.delayed(const Duration(milliseconds: 3500), _navigate);
  }

  void _navigate() async {
    if (!mounted) return;

    // Si hay sesión activa, cargar los datos antes de navegar a home
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      await context.read<UserProvider>().loadUser(firebaseUser.uid);
      await context.read<RoutineProvider>().loadRoutine(firebaseUser.uid);
      await context.read<ChatbotProvider>().loadChat(firebaseUser.uid);
    }

    if (mounted) {
      // El router redirigirá a /home si hay sesión, o a /login si no
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              const Color(0xFF1A1A2E),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Image.asset(
                  'iconos/Logo_HorusApp.png',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
