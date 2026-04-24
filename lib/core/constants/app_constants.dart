/// Constantes globales de la aplicación HorusAPP
class AppConstants {
  AppConstants._();

  static const String appName = 'HorusAPP';
  static const String appTagline = 'Tu entrenador personal inteligente';

  // ── Colecciones Firestore ──────────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String routinesCollection = 'routines';

  // ── Frases motivadoras para el Splash ────────────────────────────────────
  static const List<String> motivationalPhrases = [
    'El dolor de hoy es la fuerza de mañana.',
    'Tu único límite eres tú mismo.',
    'El cuerpo logra lo que la mente cree.',
    'No te rindas, el principio siempre es duro.',
    'Un día a la vez, una rep a la vez.',
    'Suda ahora, brilla después.',
    'La disciplina es el puente entre las metas y los logros.',
    'Haz que tu yo del futuro esté orgulloso.',
    'El éxito es la suma de pequeños esfuerzos repetidos cada día.',
    'No busques la perfección, busca el progreso.',
    'Los campeones no se rinden cuando están cansados; se rinden cuando han ganado.',
    'Cada entrenamiento te acerca un paso más a tu mejor versión.',
  ];

  // ── Opciones de los formularios ───────────────────────────────────────────
  static const List<String> genderOptions = ['Masculino', 'Femenino', 'Otro'];

  static const List<String> fitnessLevelOptions = [
    'Principiante',
    'Intermedio',
    'Avanzado',
  ];

  static const List<String> goalOptions = [
    'Bajar peso',
    'Ganar músculo',
    'Resistencia',
    'Rehabilitación',
  ];

  static const List<int> trainingDaysOptions = [3, 4, 5, 6];

  static const List<String> trainingLocationOptions = [
    'Gimnasio',
    'Casa',
    'Aire libre con equipamiento',
    'Aire libre sin equipamiento',
  ];

  // ── Límites de validación ─────────────────────────────────────────────────
  static const int minAge = 16;
  static const int maxAge = 100;
  static const double minWeight = 30.0;
  static const double maxWeight = 300.0;
  static const double minHeight = 120.0;
  static const double maxHeight = 300.0;
  static const int minPasswordLength = 8;
  static const int minNameLength = 3;
}
