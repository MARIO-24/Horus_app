import 'package:horus_app/data/datasources/firestore_datasource.dart';
import 'package:horus_app/data/models/user_model.dart';
import 'package:horus_app/domain/entities/user_entity.dart';
import 'package:horus_app/domain/repositories/user_repository.dart';

/// Implementación del repositorio de usuario
class UserRepositoryImpl implements UserRepository {
  final FirestoreDatasource _datasource;

  UserRepositoryImpl({required FirestoreDatasource datasource})
      : _datasource = datasource;

  @override
  Future<UserEntity?> getUser(String uid) => _datasource.getUser(uid);

  @override
  Future<void> saveUser(UserEntity user) =>
      _datasource.saveUser(UserModel.fromEntity(user));

  @override
  Future<void> deleteUser(String uid) => _datasource.deleteUser(uid);
}
