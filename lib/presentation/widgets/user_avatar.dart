import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Widget de avatar de usuario con caché en disco, placeholder y manejo de errores.
/// Si no hay URL muestra las iniciales del nombre dado.
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final double radius;
  final Color? backgroundColor;
  final Color? initialsColor;
  final double? initialsFontSize;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.displayName,
    this.radius = 28,
    this.backgroundColor,
    this.initialsColor,
    this.initialsFontSize,
  });

  String get _initial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.primary;
    final fgColor = initialsColor ?? Colors.white;
    final fontSize = initialsFontSize ?? radius * 0.85;

    // Sin URL: mostrar iniciales directamente
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          _initial,
          style: TextStyle(
            color: fgColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Con URL: CachedNetworkImage con placeholder de iniciales y manejo de error
    return CachedNetworkImage(
      imageUrl: avatarUrl!,
      // Caché en disco para que no re-descargue cada vez
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: SizedBox(
          width: radius * 0.8,
          height: radius * 0.8,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: fgColor,
          ),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          _initial,
          style: TextStyle(
            color: fgColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
