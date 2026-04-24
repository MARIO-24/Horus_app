import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horus_app/presentation/providers/chatbot_provider.dart';
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
