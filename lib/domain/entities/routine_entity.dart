/// Entidad de ejercicio individual
class ExerciseEntity {
  final String name;
  final int sets;
  final String reps; // Ej: "12", "12-15", "30 segundos"
  final String rest; // Ej: "60s", "90s"
  final String notes;

  const ExerciseEntity({
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'rest': rest,
        'notes': notes,
      };

  factory ExerciseEntity.fromMap(Map<String, dynamic> map) => ExerciseEntity(
        name: map['name'] as String,
        sets: map['sets'] as int,
        reps: map['reps'] as String,
        rest: map['rest'] as String,
        notes: map['notes'] as String? ?? '',
      );
}

/// Entidad de un día de entrenamiento
class WorkoutDayEntity {
  final int dayNumber;
  final String dayName; // Ej: "Día 1 — Pecho y Tríceps"
  final String focus; // Ej: "Empuje", "Tirón", "HIIT"
  final List<ExerciseEntity> exercises;

  const WorkoutDayEntity({
    required this.dayNumber,
    required this.dayName,
    required this.focus,
    required this.exercises,
  });

  Map<String, dynamic> toMap() => {
        'dayNumber': dayNumber,
        'dayName': dayName,
        'focus': focus,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };

  factory WorkoutDayEntity.fromMap(Map<String, dynamic> map) =>
      WorkoutDayEntity(
        dayNumber: map['dayNumber'] as int,
        dayName: map['dayName'] as String,
        focus: map['focus'] as String,
        exercises: (map['exercises'] as List)
            .map((e) => ExerciseEntity.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Entidad principal de rutina de entrenamiento
class RoutineEntity {
  final String id;
  final String userId;
  final DateTime createdAt;
  final String goal; // "Bajar peso", "Ganar músculo", etc.
  final String fitnessLevel; // "Principiante", "Intermedio", "Avanzado"
  final int daysPerWeek;
  final String gender;
  final String trainingLocation; // "Gimnasio", "Casa", etc.
  final double weight;
  final double height;
  final DateTime birthDate;
  final List<WorkoutDayEntity> days;

  const RoutineEntity({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.goal,
    required this.fitnessLevel,
    required this.daysPerWeek,
    required this.gender,
    this.trainingLocation = 'Gimnasio',
    required this.weight,
    required this.height,
    required this.birthDate,
    required this.days,
  });

  /// Calcula la edad a partir de la fecha de nacimiento
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Calcula el IMC
  double get bmi => weight / ((height / 100) * (height / 100));

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
        'goal': goal,
        'fitnessLevel': fitnessLevel,
        'daysPerWeek': daysPerWeek,
        'gender': gender,
        'trainingLocation': trainingLocation,
        'weight': weight,
        'height': height,
        'birthDate': birthDate.toIso8601String(),
        'days': days.map((d) => d.toMap()).toList(),
      };

  factory RoutineEntity.fromMap(Map<String, dynamic> map) => RoutineEntity(
        id: map['id'] as String,
        userId: map['userId'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        goal: map['goal'] as String,
        fitnessLevel: map['fitnessLevel'] as String,
        daysPerWeek: map['daysPerWeek'] as int,
        gender: map['gender'] as String,
        trainingLocation: map['trainingLocation'] as String? ?? 'Gimnasio',
        weight: (map['weight'] as num).toDouble(),
        height: (map['height'] as num).toDouble(),
        birthDate: DateTime.parse(map['birthDate'] as String),
        days: (map['days'] as List)
            .map((d) => WorkoutDayEntity.fromMap(d as Map<String, dynamic>))
            .toList(),
      );
}
