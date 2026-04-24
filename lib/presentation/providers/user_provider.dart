import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:horus_app/data/datasources/firestore_datasource.dart';
import 'package:horus_app/data/datasources/storage_datasource.dart';
import 'package:horus_app/data/repositories/user_repository_impl.dart';
import 'package:horus_app/domain/entities/user_entity.dart';
import 'package:horus_app/domain/usecases/user_usecases.dart';

/// Proveedor de datos del perfil de usuario desde Firestore
class UserProvider extends ChangeNotifier {
  late final GetUserUseCase _getUser;
  late final SaveUserUseCase _saveUser;
  late final DeleteUserUseCase _deleteUser;
  late final FirestoreDatasource _firestoreDs;
  late final StorageDatasource _storageDs;

  UserEntity? _user;
  String? _currentUid;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  String? _errorMessage;

  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  bool get isUploadingAvatar => _isUploadingAvatar;
  String? get errorMessage => _errorMessage;

  /// URL pública de la foto de perfil (guardada en Firebase Storage)
  String? get avatarUrl => _user?.avatarUrl;

  UserProvider() {
    _firestoreDs = FirestoreDatasource();
    _storageDs = StorageDatasource();
    final repo = UserRepositoryImpl(datasource: _firestoreDs);
    _getUser = GetUserUseCase(repo);
    _saveUser = SaveUserUseCase(repo);
    _deleteUser = DeleteUserUseCase(repo);
  }

  /// Sube la foto a Firebase Storage y guarda la URL en Firestore
  Future<void> uploadAvatar(File file) async {
    // Intentar obtener uid de memoria; si no, del usuario activo de Firebase Auth
    final uid = _currentUid ?? _user?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('[UserProvider] uploadAvatar: uid null, no se puede subir');
      return;
    }
    // Asegurar que _currentUid queda siempre sincronizado
    if (_currentUid == null) _currentUid = uid;
    _isUploadingAvatar = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final url = await _storageDs.uploadAvatar(uid, file);
      await _firestoreDs.updateAvatarUrl(uid, url);
      _user = _user?.copyWith(avatarUrl: url);
      debugPrint('[UserProvider] Avatar subido correctamente: $url');
    } catch (e) {
      _errorMessage = 'No se pudo subir la foto: $e';
      debugPrint('[UserProvider] Error subiendo avatar: $e');
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  /// Elimina la foto de perfil de Storage y Firestore
  Future<void> removeAvatar() async {
    final uid = _currentUid ?? _user?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_currentUid == null) _currentUid = uid;
    _user = _user?.copyWith(clearAvatarUrl: true);
    notifyListeners();
    try {
      await _storageDs.deleteAvatar(uid);
      await _firestoreDs.updateAvatarUrl(uid, null);
    } catch (e) {
      debugPrint('[UserProvider] Error eliminando avatar: $e');
    }
  }

  /// Carga los datos del usuario desde Firestore
  Future<void> loadUser(String uid) async {
    _currentUid = uid;
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _getUser(uid);
    } catch (e) {
      _errorMessage = 'No se pudo cargar el perfil.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza el usuario en memoria (útil tras registro)
  void setUser(UserEntity user) {
    _currentUid = user.uid;
    _user = user;
    notifyListeners();
  }

  /// Guarda los datos del usuario en Firestore
  Future<void> saveUser(UserEntity user) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _saveUser(user);
      _user = user;
    } catch (e) {
      _errorMessage = 'No se pudo guardar el perfil.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina completamente la cuenta del usuario:
  /// 1. Avatar de Firebase Storage
  /// 2. Documento de usuario en Firestore
  /// Nota: la rutina y la cuenta de Auth se eliminan por separado.
  Future<void> deleteFullAccount(String uid) async {
    // 1. Borrar avatar de Storage (si existe)
    try {
      await _storageDs.deleteAvatar(uid);
    } catch (e) {
      debugPrint('[UserProvider] Error borrando avatar de Storage: $e');
    }
    // 2. Borrar documento de Firestore
    try {
      await _firestoreDs.deleteUser(uid);
    } catch (e) {
      debugPrint('[UserProvider] Error borrando usuario de Firestore: $e');
    }
    _user = null;
    _currentUid = null;
    notifyListeners();
  }

  /// Elimina el documento del usuario en Firestore
  Future<void> deleteUser(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _deleteUser(uid);
      _user = null;
    } catch (e) {
      _errorMessage = 'No se pudo eliminar la cuenta.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia el estado del proveedor (al cerrar sesión)
  void clear() {
    _user = null;
    _currentUid = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Actualiza únicamente el nombre del usuario en Firestore y en memoria
  Future<bool> updateName(String name) async {
    // Si _user es null pero tenemos uid, intentar cargar primero
    if (_user == null) {
      final uid = _currentUid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;
      await loadUser(uid);
      if (_user == null) return false;
    }
    final updated = _user!.copyWith(name: name);
    _user = updated;
    notifyListeners();
    try {
      await _saveUser(updated);
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      return true;
    } catch (e) {
      debugPrint('[UserProvider] Error actualizando nombre: $e');
      _errorMessage = 'No se pudo guardar el nombre';
      notifyListeners();
      return false;
    }
  }
}
