import 'package:horus_app/domain/entities/user_entity.dart';

/// Modelo de usuario con serialización JSON (capa de datos)
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.createdAt,
    super.avatarUrl,
  });

  /// Crea un UserModel desde un mapa de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        avatarUrl: map['avatarUrl'] as String?,
      );

  /// Convierte a mapa para guardar en Firestore
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };

  /// Crea un UserModel desde una UserEntity
  factory UserModel.fromEntity(UserEntity entity) => UserModel(
        uid: entity.uid,
        name: entity.name,
        email: entity.email,
        createdAt: entity.createdAt,
        avatarUrl: entity.avatarUrl,
      );
}
