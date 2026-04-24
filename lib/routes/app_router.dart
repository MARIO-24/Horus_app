import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horus_app/presentation/screens/account_screen.dart';
import 'package:horus_app/presentation/screens/chatbot_screen.dart';
import 'package:horus_app/presentation/screens/home_screen.dart';
import 'package:horus_app/presentation/screens/login_screen.dart';
import 'package:horus_app/presentation/screens/options_screen.dart';
import 'package:horus_app/presentation/screens/register_screen.dart';
import 'package:horus_app/presentation/screens/routine_form_screen.dart';
import 'package:horus_app/presentation/screens/routine_screen.dart';
import 'package:horus_app/presentation/screens/splash_screen.dart';

/// Nombres de rutas — tipado para evitar errores de tipografía
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const routineForm = '/routine-form';
  static const routine = '/routine';
  static const account = '/account';
  static const chatbot = '/chatbot';
  static const options = '/options';
}

/// Listenable que actualiza el router cuando cambia el estado de Firebase Auth
class _GoRouterAuthRefresh extends ChangeNotifier {
  late final StreamSubscription<User?> _sub;

  _GoRouterAuthRefresh() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Configuración centralizada del router de la aplicación
class AppRouter {
  AppRouter._();

  static final _authRefresh = _GoRouterAuthRefresh();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _authRefresh,
    // ── Redirección automática según estado de autenticación ──────────────
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final location = state.matchedLocation;

      // La splash siempre se muestra primero
      if (location == AppRoutes.splash) return null;

      // Usuario no autenticado intentando acceder a rutas protegidas
      if (!isLoggedIn &&
          location != AppRoutes.login &&
          location != AppRoutes.register) {
        return AppRoutes.login;
      }

      // Usuario autenticado intentando acceder a pantallas de auth
      if (isLoggedIn &&
          (location == AppRoutes.login || location == AppRoutes.register)) {
        return AppRoutes.home;
      }

      return null; // Sin redirección
    },
    routes: [
      // ── Splash ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Autenticación ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // ── App principal (con drawer) ────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),

      // ── Formulario de rutina (pantalla completa) ──────────────────────
      GoRoute(
        path: AppRoutes.routineForm,
        name: 'routineForm',
        builder: (_, __) => const RoutineFormScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoutineFormScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
      ),

      // ── Sub-páginas accesibles desde el drawer ────────────────────────
      GoRoute(
        path: AppRoutes.routine,
        name: 'routine',
        builder: (_, __) => const RoutineScreen(),
      ),
      GoRoute(
        path: AppRoutes.account,
        name: 'account',
        builder: (_, __) => const AccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatbot,
        name: 'chatbot',
        builder: (_, __) => const ChatbotScreen(),
      ),
      GoRoute(
        path: AppRoutes.options,
        name: 'options',
        builder: (_, __) => const OptionsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Página no encontrada: ${state.uri}'),
      ),
    ),
  );
}
