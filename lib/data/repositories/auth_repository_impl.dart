import 'package:horus_app/data/datasources/firebase_auth_datasource.dart';
import 'package:horus_app/data/datasources/firestore_datasource.dart';
import 'package:horus_app/domain/entities/user_entity.dart';
import 'package:horus_app/domain/repositories/auth_repository.dart';

/// Implementación del repositorio de autenticación
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource _authDatasource;
  final FirestoreDatasource _firestoreDatasource;

  AuthRepositoryImpl({
    required FirebaseAuthDatasource authDatasource,
    required FirestoreDatasource firestoreDatasource,
  })  : _authDatasource = authDatasource,
        _firestoreDatasource = firestoreDatasource;

  @override
  String? get currentUserId => _authDatasource.currentUserId;

  @override
  bool get isAuthenticated => _authDatasource.isAuthenticated;

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    final userModel = await _authDatasource.signIn(
      email: email,
      password: password,
    );
    // Recuperar el nombre guardado en Firestore si existe
    final saved = await _firestoreDatasource.getUser(userModel.uid);
    return saved ?? userModel;
  }

  @override
  Future<UserEntity> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final userModel = await _authDatasource.signUp(
      name: name,
      email: email,
      password: password,
    );
    // Guardar el usuario en Firestore tras el registro
    await _firestoreDatasource.saveUser(userModel);
    return userModel;
  }

  @override
  Future<void> signOut() => _authDatasource.signOut();
}
