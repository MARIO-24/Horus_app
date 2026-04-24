import 'package:horus_app/domain/entities/routine_entity.dart';
import 'package:horus_app/domain/repositories/routine_repository.dart';

/// Caso de uso: Obtener rutina del usuario
class GetRoutineUseCase {
  final RoutineRepository _repository;
  GetRoutineUseCase(this._repository);

  Future<RoutineEntity?> call(String userId) =>
      _repository.getRoutine(userId);
}

/// Caso de uso: Guardar rutina
class SaveRoutineUseCase {
  final RoutineRepository _repository;
  SaveRoutineUseCase(this._repository);

  Future<void> call(RoutineEntity routine) =>
      _repository.saveRoutine(routine);
}

/// Caso de uso: Eliminar rutina
class DeleteRoutineUseCase {
  final RoutineRepository _repository;
  DeleteRoutineUseCase(this._repository);

  Future<void> call(String userId) => _repository.deleteRoutine(userId);
}
