import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Fuente de datos de Firebase Storage (fotos de perfil)
class StorageDatasource {
  final FirebaseStorage _storage;

  StorageDatasource({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Sube la foto de perfil a Storage y devuelve la URL de descarga.
  /// La ruta en Storage es: avatars/{uid}/profile.jpg
  Future<String> uploadAvatar(String uid, File file) async {
    final ref = _storage.ref().child('avatars/$uid/profile.jpg');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  /// Elimina la foto de perfil de Storage
  Future<void> deleteAvatar(String uid) async {
    try {
      await _storage.ref().child('avatars/$uid/profile.jpg').delete();
    } catch (_) {
      // Si no existe, ignorar
    }
  }
}
