import 'package:horus_app/data/datasources/firestore_datasource.dart';
import 'package:horus_app/data/models/routine_model.dart';
import 'package:horus_app/domain/entities/routine_entity.dart';
import 'package:horus_app/domain/repositories/routine_repository.dart';

/// Implementación del repositorio de rutinas
class RoutineRepositoryImpl implements RoutineRepository {
  final FirestoreDatasource _datasource;

  RoutineRepositoryImpl({required FirestoreDatasource datasource})
      : _datasource = datasource;

  @override
  Future<RoutineEntity?> getRoutine(String userId) =>
      _datasource.getRoutine(userId);

  @override
  Future<void> saveRoutine(RoutineEntity routine) =>
      _datasource.saveRoutine(RoutineModel.fromEntity(routine));

  @override
  Future<void> deleteRoutine(String userId) =>
      _datasource.deleteRoutine(userId);
}
