import 'package:flutter/material.dart';
import 'package:horus_app/data/datasources/firestore_datasource.dart';
import 'package:horus_app/data/repositories/routine_repository_impl.dart';
import 'package:horus_app/domain/entities/routine_entity.dart';
import 'package:horus_app/domain/usecases/routine_usecases.dart';
import 'package:horus_app/services/routine_generator_service.dart';

enum RoutineStatus { initial, loading, loaded, empty, error }

/// Proveedor de rutina — genera, carga, guarda y elimina la rutina del usuario
class RoutineProvider extends ChangeNotifier {
  late final GetRoutineUseCase _getRoutine;
  late final SaveRoutineUseCase _saveRoutine;
  late final DeleteRoutineUseCase _deleteRoutine;

  RoutineEntity? _routine;
  RoutineStatus _status = RoutineStatus.initial;
  String? _errorMessage;

  RoutineEntity? get routine => _routine;
  RoutineStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == RoutineStatus.loading;
  bool get hasRoutine => _routine != null;

  RoutineProvider() {
    final ds = FirestoreDatasource();
    final repo = RoutineRepositoryImpl(datasource: ds);
    _getRoutine = GetRoutineUseCase(repo);
    _saveRoutine = SaveRoutineUseCase(repo);
    _deleteRoutine = DeleteRoutineUseCase(repo);
  }

  /// Carga la rutina del usuario desde Firestore
  Future<void> loadRoutine(String userId) async {
    _status = RoutineStatus.loading;
    notifyListeners();
    try {
      final routine = await _getRoutine(userId);
      _routine = routine;
      _status = routine != null ? RoutineStatus.loaded : RoutineStatus.empty;
    } catch (e) {
      _errorMessage = 'No se pudo cargar la rutina.';
      _status = RoutineStatus.error;
    }
    notifyListeners();
  }

  /// Genera una nueva rutina y la guarda en Firestore
  Future<void> generateAndSaveRoutine({
    required String userId,
    required String goal,
    required String fitnessLevel,
    required int daysPerWeek,
    required String gender,
    required String trainingLocation,
    required double weight,
    required double height,
    required DateTime birthDate,
    bool isEnglish = false,
  }) async {
    _status = RoutineStatus.loading;
    notifyListeners();
    try {
      // Generar los días de la rutina con Gemini (fallback local si falla)
      final days = await RoutineGeneratorService.generateRoutineWithAI(
        goal: goal,
        fitnessLevel: fitnessLevel,
        daysPerWeek: daysPerWeek,
        gender: gender,
        trainingLocation: trainingLocation,
        isEnglish: isEnglish,
      );

      final routine = RoutineEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        createdAt: DateTime.now(),
        goal: goal,
        fitnessLevel: fitnessLevel,
        daysPerWeek: daysPerWeek,
        gender: gender,
        trainingLocation: trainingLocation,
        weight: weight,
        height: height,
        birthDate: birthDate,
        days: days,
      );

      await _saveRoutine(routine);
      _routine = routine;
      _status = RoutineStatus.loaded;
    } catch (e) {
      _errorMessage = 'No se pudo generar la rutina. Inténtalo de nuevo.';
      _status = RoutineStatus.error;
    }
    notifyListeners();
  }

  /// Elimina la rutina del usuario
  Future<void> deleteRoutine(String userId) async {
    _status = RoutineStatus.loading;
    notifyListeners();
    try {
      await _deleteRoutine(userId);
      _routine = null;
      _status = RoutineStatus.empty;
    } catch (e) {
      _errorMessage = 'No se pudo eliminar la rutina.';
      _status = RoutineStatus.error;
    }
    notifyListeners();
  }

  /// Limpia el estado del proveedor (al cerrar sesión)
  void clear() {
    _routine = null;
    _status = RoutineStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
