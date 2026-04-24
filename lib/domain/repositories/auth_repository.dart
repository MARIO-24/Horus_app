import 'package:horus_app/domain/entities/user_entity.dart';

/// Interfaz del repositorio de autenticación (capa de dominio)
abstract class AuthRepository {
  Future<UserEntity> signIn({
    required String email,
    required String password,
  });

  Future<UserEntity> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Retorna el uid del usuario actual (null si no hay sesión)
  String? get currentUserId;

  bool get isAuthenticated;
}
