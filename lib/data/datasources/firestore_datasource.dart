import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:horus_app/core/constants/app_constants.dart';
import 'package:horus_app/data/models/routine_model.dart';
import 'package:horus_app/data/models/user_model.dart';

/// Fuente de datos de Cloud Firestore
class FirestoreDatasource {
  final FirebaseFirestore _firestore;

  FirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Usuarios ──────────────────────────────────────────────────────────────

  /// Obtiene el documento de usuario por uid
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Guarda o actualiza los datos de usuario
  Future<void> saveUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  /// Actualiza únicamente el campo avatarUrl del usuario
  Future<void> updateAvatarUrl(String uid, String? url) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set({'avatarUrl': url}, SetOptions(merge: true));
  }

  /// Elimina el documento de usuario
  Future<void> deleteUser(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .delete();
  }

  // ── Rutinas ───────────────────────────────────────────────────────────────

  /// Obtiene la rutina activa del usuario (se guarda con el userId como doc id)
  Future<RoutineModel?> getRoutine(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.routinesCollection)
        .doc(userId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return RoutineModel.fromMap(doc.data()!);
  }

  /// Guarda o reemplaza la rutina del usuario
  Future<void> saveRoutine(RoutineModel routine) async {
    await _firestore
        .collection(AppConstants.routinesCollection)
        .doc(routine.userId)
        .set(routine.toMap());
  }

  /// Elimina la rutina del usuario
  Future<void> deleteRoutine(String userId) async {
    await _firestore
        .collection(AppConstants.routinesCollection)
        .doc(userId)
        .delete();
  }
}
