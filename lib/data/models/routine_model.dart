import 'package:horus_app/domain/entities/routine_entity.dart';

/// Modelo de rutina con serialización JSON (capa de datos)
class RoutineModel extends RoutineEntity {
  const RoutineModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.goal,
    required super.fitnessLevel,
    required super.daysPerWeek,
    required super.gender,
    super.trainingLocation,
    required super.weight,
    required super.height,
    required super.birthDate,
    required super.days,
  });

  /// Crea desde un mapa de Firestore
  factory RoutineModel.fromMap(Map<String, dynamic> map) {
    final days = (map['days'] as List)
        .map((d) => WorkoutDayEntity.fromMap(d as Map<String, dynamic>))
        .toList();
    return RoutineModel(
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
      days: days,
    );
  }

  /// Crea desde una RoutineEntity
  factory RoutineModel.fromEntity(RoutineEntity entity) => RoutineModel(
        id: entity.id,
        userId: entity.userId,
        createdAt: entity.createdAt,
        goal: entity.goal,
        fitnessLevel: entity.fitnessLevel,
        daysPerWeek: entity.daysPerWeek,
        gender: entity.gender,
        trainingLocation: entity.trainingLocation,
        weight: entity.weight,
        height: entity.height,
        birthDate: entity.birthDate,
        days: entity.days,
      );
}
