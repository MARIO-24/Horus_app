import 'package:firebase_auth/firebase_auth.dart';
import 'package:horus_app/data/models/user_model.dart';

/// Fuente de datos de autenticación usando Firebase Auth
class FirebaseAuthDatasource {
  final FirebaseAuth _auth;

  FirebaseAuthDatasource({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  bool get isAuthenticated => _auth.currentUser != null;

  /// Inicia sesión con email y contraseña
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    return UserModel(
      uid: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      createdAt: DateTime.now(),
    );
  }

  /// Registra un nuevo usuario
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    // Actualizar el nombre en Firebase Auth
    await user.updateDisplayName(name.trim());
    return UserModel(
      uid: user.uid,
      name: name.trim(),
      email: user.email ?? '',
      createdAt: DateTime.now(),
    );
  }

  /// Cierra la sesión actual
  Future<void> signOut() => _auth.signOut();

  /// Elimina la cuenta del usuario actual
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
