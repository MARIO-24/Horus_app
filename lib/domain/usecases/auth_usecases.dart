import 'package:horus_app/domain/entities/user_entity.dart';
import 'package:horus_app/domain/repositories/auth_repository.dart';

/// Caso de uso: Iniciar sesión
class SignInUseCase {
  final AuthRepository _repository;
  SignInUseCase(this._repository);

  Future<UserEntity> call({
    required String email,
    required String password,
  }) =>
      _repository.signIn(email: email, password: password);
}

/// Caso de uso: Registrar usuario
class SignUpUseCase {
  final AuthRepository _repository;
  SignUpUseCase(this._repository);

  Future<UserEntity> call({
    required String name,
    required String email,
    required String password,
  }) =>
      _repository.signUp(name: name, email: email, password: password);
}

/// Caso de uso: Cerrar sesión
class SignOutUseCase {
  final AuthRepository _repository;
  SignOutUseCase(this._repository);

  Future<void> call() => _repository.signOut();
}
