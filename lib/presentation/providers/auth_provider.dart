import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horus_app/data/datasources/firebase_auth_datasource.dart';
import 'package:horus_app/data/datasources/firestore_datasource.dart';
import 'package:horus_app/data/repositories/auth_repository_impl.dart';
import 'package:horus_app/domain/entities/user_entity.dart';
import 'package:horus_app/domain/usecases/auth_usecases.dart';

/// Estados posibles del proceso de autenticación
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Proveedor de autenticación — gestiona login, registro y cierre de sesión
class AuthProvider extends ChangeNotifier {
  late final SignInUseCase _signIn;
  late final SignUpUseCase _signUp;
  late final SignOutUseCase _signOut;

  AuthStatus _status = AuthStatus.initial;
  UserEntity? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    // Construir dependencias internamente
    final authDs = FirebaseAuthDatasource();
    final firestoreDs = FirestoreDatasource();
    final repo = AuthRepositoryImpl(
      authDatasource: authDs,
      firestoreDatasource: firestoreDs,
    );
    _signIn = SignInUseCase(repo);
    _signUp = SignUpUseCase(repo);
    _signOut = SignOutUseCase(repo);

    // Inicialización asíncrona: respeta preferencia de "no mantener sesión"
    _initAuth();
  }

  Future<void> _initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final preferNoPersist = prefs.getBool('prefer_no_persist') ?? false;
    if (preferNoPersist && FirebaseAuth.instance.currentUser != null) {
      // El usuario no quiso mantener sesión: cerrar sesión restaurada
      await FirebaseAuth.instance.signOut();
      await prefs.remove('prefer_no_persist');
    }
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? firebaseUser) {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      _status = AuthStatus.authenticated;
      // Si aun no tenemos el usuario en memoria, creamos uno básico
      _user ??= UserEntity(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        createdAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  /// Inicia sesión con email y contraseña
  Future<bool> login({required String email, required String password}) async {
    _setLoading();
    try {
      _user = await _signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado. Inténtalo de nuevo.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Registra un nuevo usuario
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      _user = await _signUp(name: name, email: email, password: password);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado. Inténtalo de nuevo.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Envía un correo de restablecimiento de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  /// Cierra la sesión actual
  Future<void> logout() async {
    await _signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  /// Traduce errores de Firebase Auth a mensajes amigables en español
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con ese email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese email.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'invalid-email':
        return 'El formato del email no es válido.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';
      default:
        return 'Error de autenticación. Inténtalo de nuevo.';
    }
  }
}
