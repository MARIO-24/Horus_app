import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horus_app/presentation/providers/auth_provider.dart';
import 'package:horus_app/presentation/providers/routine_provider.dart';
import 'package:horus_app/presentation/providers/user_provider.dart';
import 'package:horus_app/presentation/widgets/custom_drawer.dart';
import 'package:horus_app/presentation/widgets/user_avatar.dart';
import 'package:horus_app/routes/app_router.dart';
import 'package:provider/provider.dart';

/// Pantalla principal que actúa como contenedor con Drawer.
/// Muestra la rutina del usuario o invita a crear una si no tiene.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final routineProvider = context.watch<RoutineProvider>();
    final routine = routineProvider.routine;
    // Priorizar nombre de Firestore; si no está cargado aún, usar el de FirebaseAuth
    final firestoreName = context.watch<UserProvider>().user?.name;
    final authName = context.read<AuthProvider>().user?.name;
    final userName = (firestoreName?.isNotEmpty == true)
        ? firestoreName!
        : (authName?.isNotEmpty == true ? authName! : 'Atleta');

    final avatarUrl = context.watch<UserProvider>().avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HorusAPP'),
        centerTitle: false,
        actions: [
          if (routine != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Nueva rutina',
              onPressed: () => context.push(AppRoutes.routineForm),
            ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: routine == null
          ? _NoRoutineBody(userName: userName)
          : _RoutinePreviewBody(userName: userName, avatarUrl: avatarUrl),
    );
  }
}

/// Cuerpo cuando el usuario NO tiene rutina generada
class _NoRoutineBody extends StatelessWidget {
  final String userName;
  const _NoRoutineBody({required this.userName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'iconos/Icono_Rutina.png',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '¡Hola, $userName! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes una rutina personalizada.\nVamos a crear una hecha justo para ti.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color:
                        colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.routineForm),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generar mi rutina'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.chatbot),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Hablar con el bot'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuerpo cuando el usuario YA tiene una rutina — muestra un resumen
class _RoutinePreviewBody extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  const _RoutinePreviewBody({required this.userName, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final routine =
        context.watch<RoutineProvider>().routine!;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Saludo ─────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  UserAvatar(
                    avatarUrl: avatarUrl,
                    displayName: userName,
                    radius: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Hola, $userName! 💪',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Tu rutina está lista',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Stats de la rutina ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.flag_outlined,
                  label: 'Objetivo',
                  value: routine.goal,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up,
                  label: 'Nivel',
                  value: routine.fitnessLevel,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Días/semana',
                  value: '${routine.daysPerWeek}',
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Botón ver rutina completa ──────────────────────────────
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.routine),
            icon: const Icon(Icons.list_alt),
            label: const Text('Ver rutina completa'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 12),

          // ── Botón generar nueva rutina ─────────────────────────────
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.routineForm),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generar nueva rutina'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 24),

          // ── Preview de los días ────────────────────────────────────
          Text(
            'Días de entrenamiento',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...routine.days.map(
            (day) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    '${day.dayNumber}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  day.dayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${day.exercises.length} ejercicios • ${day.focus}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.routine),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de estadística pequeña
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
