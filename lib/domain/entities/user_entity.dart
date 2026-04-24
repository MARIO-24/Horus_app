/// Entidad de usuario (capa de dominio — sin dependencias externas)
class UserEntity {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final String? avatarUrl; // URL de Firebase Storage de la foto de perfil

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.avatarUrl,
  });

  UserEntity copyWith({
    String? uid,
    String? name,
    String? email,
    DateTime? createdAt,
    String? avatarUrl,
    bool clearAvatarUrl = false,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
