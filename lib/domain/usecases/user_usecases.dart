import 'package:horus_app/domain/entities/user_entity.dart';
import 'package:horus_app/domain/repositories/user_repository.dart';

/// Caso de uso: Obtener datos del usuario
class GetUserUseCase {
  final UserRepository _repository;
  GetUserUseCase(this._repository);

  Future<UserEntity?> call(String uid) => _repository.getUser(uid);
}

/// Caso de uso: Guardar datos del usuario
class SaveUserUseCase {
  final UserRepository _repository;
  SaveUserUseCase(this._repository);

  Future<void> call(UserEntity user) => _repository.saveUser(user);
}

/// Caso de uso: Eliminar cuenta del usuario
class DeleteUserUseCase {
  final UserRepository _repository;
  DeleteUserUseCase(this._repository);

  Future<void> call(String uid) => _repository.deleteUser(uid);
}
