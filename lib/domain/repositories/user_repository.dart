import 'package:horus_app/domain/entities/user_entity.dart';

/// Interfaz del repositorio de usuario (capa de dominio)
abstract class UserRepository {
  Future<UserEntity?> getUser(String uid);

  Future<void> saveUser(UserEntity user);

  Future<void> deleteUser(String uid);
}
