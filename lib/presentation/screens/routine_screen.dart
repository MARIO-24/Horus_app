import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horus_app/domain/entities/routine_entity.dart';
import 'package:horus_app/presentation/providers/routine_provider.dart';
import 'package:horus_app/presentation/widgets/custom_drawer.dart';
import 'package:horus_app/presentation/widgets/exercise_card.dart';
import 'package:horus_app/routes/app_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Pantalla de visualización completa de la rutina
class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routineProvider = context.watch<RoutineProvider>();

    if (routineProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!routineProvider.hasRoutine) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Rutina')),
        drawer: const CustomDrawer(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No tienes ninguna rutina aún'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(AppRoutes.routineForm),
                child: const Text('Crear rutina'),
              ),
            ],
          ),
        ),
      );
    }

    final routine = routineProvider.routine!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('iconos/Icono_Rutina.png', width: 28, height: 28),
            const SizedBox(width: 10),
            const Text('Mi Rutina'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nueva rutina',
            onPressed: () => context.push(AppRoutes.routineForm),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // ── Resumen de la rutina ──────────────────────────────────────
          _RoutineSummaryHeader(routine: routine),

          // ── Lista de días con expansión ──────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: routine.days.length,
              itemBuilder: (context, i) =>
                  _DayExpansionCard(day: routine.days[i]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Encabezado con resumen de la rutina
class _RoutineSummaryHeader extends StatelessWidget {
  final RoutineEntity routine;
  const _RoutineSummaryHeader({required this.routine});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _HeaderStat(
                  label: 'Objetivo',
                  value: routine.goal,
                  icon: Icons.flag)),
              Expanded(child: _HeaderStat(
                  label: 'Nivel',
                  value: routine.fitnessLevel,
                  icon: Icons.trending_up)),
              Expanded(child: _HeaderStat(
                  label: 'Días',
                  value: '${routine.daysPerWeek}/sem',
                  icon: Icons.calendar_today)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _HeaderStat(
                  label: 'Peso',
                  value: '${routine.weight.toStringAsFixed(1)} kg',
                  icon: Icons.monitor_weight_outlined)),
              Expanded(child: _HeaderStat(
                  label: 'Altura',
                  value: '${routine.height.toStringAsFixed(0)} cm',
                  icon: Icons.height)),
              Expanded(child: _HeaderStat(
                  label: 'IMC',
                  value: routine.bmi.toStringAsFixed(1),
                  icon: Icons.analytics_outlined)),
              Expanded(child: _HeaderStat(
                  label: 'Generada',
                  value: DateFormat('dd/MM/yy').format(routine.createdAt),
                  icon: Icons.event)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

/// Card expandible que muestra los ejercicios de un día
class _DayExpansionCard extends StatelessWidget {
  final WorkoutDayEntity day;
  const _DayExpansionCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.dayNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          title: Text(
            day.dayName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                Icons.fitness_center,
                size: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                '${day.exercises.length} ejercicios',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    day.focus,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          children: day.exercises.asMap().entries.map((entry) {
            return ExerciseCard(
              exercise: entry.value,
              index: entry.key + 1,
            );
          }).toList(),
        ),
      ),
    );
  }
}
