import 'package:horus_app/domain/entities/routine_entity.dart';

/// Interfaz del repositorio de rutinas (capa de dominio)
abstract class RoutineRepository {
  Future<RoutineEntity?> getRoutine(String userId);

  Future<void> saveRoutine(RoutineEntity routine);

  Future<void> deleteRoutine(String userId);
}
