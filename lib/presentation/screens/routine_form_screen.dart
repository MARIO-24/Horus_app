import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horus_app/core/constants/app_constants.dart';
import 'package:horus_app/core/l10n/app_l10n.dart';
import 'package:horus_app/core/utils/validators.dart';
import 'package:horus_app/presentation/providers/auth_provider.dart';
import 'package:horus_app/presentation/providers/routine_provider.dart';
import 'package:horus_app/presentation/widgets/custom_text_field.dart';
import 'package:horus_app/routes/app_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Formulario para recoger los datos del usuario y generar una rutina personalizada
class RoutineFormScreen extends StatefulWidget {
  const RoutineFormScreen({super.key});

  @override
  State<RoutineFormScreen> createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends State<RoutineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  DateTime? _birthDate;
  String _gender = AppConstants.genderOptions[0];
  String _fitnessLevel = AppConstants.fitnessLevelOptions[0];
  String _goal = AppConstants.goalOptions[0];
  String _trainingLocation = AppConstants.trainingLocationOptions[0];
  int _daysPerWeek = 3;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  // ── Selector de fecha ────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(now.year - AppConstants.maxAge),
      lastDate: DateTime(now.year - AppConstants.minAge, 12, 31),
      helpText: 'Selecciona tu fecha de nacimiento',
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  // ── Generar rutina ───────────────────────────────────────────────────────
  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppL10n.readFrom(context);

    // Validación adicional de fecha
    final dateError = Validators.validateBirthDate(_birthDate);
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dateError), backgroundColor: Colors.red),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.user!.uid;
    final routineProvider = context.read<RoutineProvider>();

    await routineProvider.generateAndSaveRoutine(
      userId: uid,
      goal: _goal,
      fitnessLevel: _fitnessLevel,
      daysPerWeek: _daysPerWeek,
      gender: _gender,
      trainingLocation: _trainingLocation,
      weight: double.parse(_weightCtrl.text.replaceAll(',', '.')),
      height: double.parse(_heightCtrl.text.replaceAll(',', '.')),
      birthDate: _birthDate!,
    );

    if (!mounted) return;

    if (routineProvider.status == RoutineStatus.loaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(l10n.routineSuccess),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(AppRoutes.routine);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              routineProvider.errorMessage ?? l10n.routineError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = context.watch<RoutineProvider>().isLoading;
    final l10n = AppL10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routineFormTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Encabezado ────────────────────────────────────────────
              Card(
                color: colorScheme.primary.withValues(alpha: 0.08),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.routineFormSubtitle,
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Fecha de nacimiento ───────────────────────────────────
              _SectionLabel(text: l10n.personalData),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: CustomTextField(
                    label: l10n.birthDate,
                    hint: l10n.birthDateHint,
                    readOnly: true,
                    prefixIcon: const Icon(Icons.cake_outlined),
                    controller: TextEditingController(
                      text: _birthDate != null
                          ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                          : '',
                    ),
                    validator: (_) => Validators.validateBirthDate(_birthDate),
                    onTap: _pickDate,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Peso y altura en fila ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: l10n.weightLabel,
                      hint: l10n.weightHint,
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      prefixIcon:
                          const Icon(Icons.monitor_weight_outlined),
                      validator: Validators.validateWeight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: l10n.heightLabel,
                      hint: l10n.heightHint,
                      controller: _heightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      prefixIcon: const Icon(Icons.height),
                      validator: Validators.validateHeight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Género ────────────────────────────────────────────────
              _SectionLabel(text: l10n.genderLabel),
              const SizedBox(height: 8),
              _OptionChips<String>(
                options: AppConstants.genderOptions,
                selected: _gender,
                labels: l10n.genderOptions,
                onSelected: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 20),

              // ── Nivel físico ──────────────────────────────────────────
              _SectionLabel(text: l10n.fitnessLevelLabel),
              const SizedBox(height: 8),
              _OptionChips<String>(
                options: AppConstants.fitnessLevelOptions,
                selected: _fitnessLevel,
                labels: l10n.fitnessOptions,
                onSelected: (v) => setState(() => _fitnessLevel = v),
              ),
              const SizedBox(height: 20),

              // ── Objetivo ──────────────────────────────────────────────
              _SectionLabel(text: l10n.goalLabel2),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.goalOptions.asMap().entries.map((e) {
                  final idx = e.key;
                  final goal = e.value;
                  final isSelected = _goal == goal;
                  final label = l10n.goalOptions[idx];
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _goal = goal),
                    selectedColor:
                        colorScheme.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Días de entrenamiento ──────────────────────────────────
              _SectionLabel(text: l10n.daysPerWeekLabel(_daysPerWeek)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: AppConstants.trainingDaysOptions.map((days) {
                  final isSelected = _daysPerWeek == days;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _daysPerWeek = days),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$days',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── ¿Dónde entrenas? ──────────────────────────────────────
              _SectionLabel(text: l10n.trainingLocationLabel),
              const SizedBox(height: 8),
              _OptionChips<String>(
                options: AppConstants.trainingLocationOptions,
                selected: _trainingLocation,
                labels: l10n.locationOptions,
                onSelected: (v) => setState(() => _trainingLocation = v),
              ),
              const SizedBox(height: 32),

              // ── Botón generar ─────────────────────────────────────────
              FilledButton.icon(
                onPressed: isLoading ? null : _generate,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(isLoading ? l10n.generatingLabel : l10n.generateRoutine),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de sección
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

/// Chips de opciones horizontales
class _OptionChips<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final void Function(T) onSelected;
  /// Etiquetas opcionales; si se omiten, se usa `opt.toString()`
  final List<String>? labels;

  const _OptionChips({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.asMap().entries.map((entry) {
        final idx = entry.key;
        final opt = entry.value;
        final isSelected = selected == opt;
        final displayLabel = labels != null ? labels![idx] : opt.toString();
        return ChoiceChip(
          label: Text(
            displayLabel,
            textAlign: TextAlign.center,
          ),
          selected: isSelected,
          onSelected: (_) => onSelected(opt),
          selectedColor: colorScheme.primary.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline,
          ),
        );
      }).toList(),
    );
  }
}
