import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:horus_app/core/config/secrets.dart';
import 'package:horus_app/domain/entities/routine_entity.dart';
import 'package:http/http.dart' as http;

/// Servicio de generación de rutinas.
/// Usa Gemini como motor principal con fallback local si la API falla.
class RoutineGeneratorService {
  RoutineGeneratorService._();

  static const _apiKey = AppSecrets.geminiApiKey;
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';

  /// Genera una rutina con Gemini. Si la API falla, usa la generación local.
  static Future<List<WorkoutDayEntity>> generateRoutineWithAI({
    required String goal,
    required String fitnessLevel,
    required int daysPerWeek,
    required String gender,
    required int age,
    required double weight,
    required double height,
    String trainingLocation = 'Gimnasio',
    bool isEnglish = false,
  }) async {
    // ── Calcular IMC ─────────────────────────────────────────────────────────
    final double bmi = weight / ((height / 100) * (height / 100));
    final String bmiCategory = isEnglish
        ? (bmi < 18.5
            ? 'Underweight (BMI ${bmi.toStringAsFixed(1)})'
            : bmi < 25
                ? 'Normal weight (BMI ${bmi.toStringAsFixed(1)})'
                : bmi < 30
                    ? 'Overweight (BMI ${bmi.toStringAsFixed(1)})'
                    : 'Obesity (BMI ${bmi.toStringAsFixed(1)})')
        : (bmi < 18.5
            ? 'Bajo peso (IMC ${bmi.toStringAsFixed(1)})'
            : bmi < 25
                ? 'Peso normal (IMC ${bmi.toStringAsFixed(1)})'
                : bmi < 30
                    ? 'Sobrepeso (IMC ${bmi.toStringAsFixed(1)})'
                    : 'Obesidad (IMC ${bmi.toStringAsFixed(1)})');

    // ── Descripción del equipamiento por ubicación ────────────────────────
    final String equipmentDescription = isEnglish
        ? _equipmentDescriptionEn(trainingLocation)
        : _equipmentDescriptionEs(trainingLocation);

    try {
      final prompt = isEnglish
          ? '''Generate a personalised workout routine in JSON format.

USER BIOMETRIC PROFILE:
- Age: $age years
- Weight: ${weight.toStringAsFixed(1)} kg
- Height: ${height.toStringAsFixed(0)} cm
- BMI: $bmiCategory
- Gender: $gender

TRAINING PARAMETERS:
- Goal: $goal
- Fitness level: $fitnessLevel
- Training days per week: $daysPerWeek
- Training location: $trainingLocation
- Available equipment: $equipmentDescription

INSTRUCTIONS:
1. Adapt the exercise selection STRICTLY to the available equipment described above.
2. Adjust intensity, volume and rest times to the fitness level and BMI.
3. Structure the weekly plan to maximise progress towards the stated goal.
4. Each day must have between 4 and 7 exercises.
5. Return ONLY a JSON array with exactly $daysPerWeek elements.

JSON format for each day:
[{"dayNumber":1,"dayName":"Day 1 — Focus name","focus":"Primary muscle group",
"exercises":[{"name":"Exercise name","sets":3,"reps":"12","rest":"60s",
"notes":"How to perform it correctly, muscles worked and a key technique tip"}]}]

The "notes" field is MANDATORY for every exercise.
Respond ONLY with the valid JSON, no markdown, no extra text.'''
          : '''Genera una rutina de entrenamiento personalizada en formato JSON.

PERFIL BIOMÉTRICO DEL USUARIO:
- Edad: $age años
- Peso: ${weight.toStringAsFixed(1)} kg
- Altura: ${height.toStringAsFixed(0)} cm
- IMC: $bmiCategory
- Género: $gender

PARÁMETROS DE ENTRENAMIENTO:
- Objetivo: $goal
- Nivel físico: $fitnessLevel
- Días de entrenamiento por semana: $daysPerWeek
- Lugar de entrenamiento: $trainingLocation
- Equipamiento disponible: $equipmentDescription

INSTRUCCIONES:
1. Adapta la selección de ejercicios ESTRICTAMENTE al equipamiento disponible descrito.
2. Ajusta la intensidad, el volumen y los tiempos de descanso al nivel físico y al IMC.
3. Estructura el plan semanal para maximizar el progreso hacia el objetivo indicado.
4. Cada día debe tener entre 4 y 7 ejercicios.
5. Devuelve ÚNICAMENTE un array JSON con exactamente $daysPerWeek elementos.

Formato JSON para cada día:
[{"dayNumber":1,"dayName":"Día 1 — Nombre del enfoque","focus":"Grupo muscular principal",
"exercises":[{"name":"Nombre del ejercicio","sets":3,"reps":"12","rest":"60s",
"notes":"Cómo ejecutarlo correctamente, músculos que trabaja y consejo clave de técnica"}]}]

El campo "notes" es OBLIGATORIO en cada ejercicio.
Responde SOLO con el JSON válido, sin markdown ni texto adicional.''';

      final systemInstruction = isEnglish
          ? 'You are an elite personal trainer and exercise scientist with 15+ years of experience. '
              'You design evidence-based training programmes adapted to each user\'s biometrics, '
              'fitness level, available equipment and specific goal. '
              'You generate ONLY valid JSON arrays, with no additional text or markdown blocks.'
          : 'Eres un entrenador personal de élite y científico del ejercicio con más de 15 años '
              'de experiencia. Diseñas programas de entrenamiento basados en evidencia, adaptados '
              'a la biometría, nivel físico, equipamiento disponible y objetivo específico de cada '
              'usuario. Generas ÚNICAMENTE arrays JSON válidos, sin texto adicional ni bloques markdown.';

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'X-goog-api-key': _apiKey,
            },
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {'text': systemInstruction}
                ]
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {'maxOutputTokens': 5000},
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidate = data['candidates'][0] as Map<String, dynamic>;

        // Detectar truncado por límite de tokens
        final finishReason = candidate['finishReason'] as String? ?? '';
        if (finishReason == 'MAX_TOKENS') {
          debugPrint('[RoutineGeneratorService] Respuesta truncada (MAX_TOKENS), usando fallback local');
          return generateRoutine(
            goal: goal, fitnessLevel: fitnessLevel,
            daysPerWeek: daysPerWeek, gender: gender,
            trainingLocation: trainingLocation,
          );
        }

        String text = candidate['content']['parts'][0]['text'] as String;

        // Limpiar bloques markdown si los incluye
        text = text.trim();
        if (text.startsWith('```')) {
          text = text.replaceAll(RegExp(r'```json\n?|```\n?'), '').trim();
        }

        final List<dynamic> rawDays = jsonDecode(text);
        final days = rawDays
            .map((d) => WorkoutDayEntity.fromMap(d as Map<String, dynamic>))
            .toList();
        debugPrint('[RoutineGeneratorService] Rutina generada con Gemini ✓');
        return days;
      }

      debugPrint(
          '[RoutineGeneratorService] Gemini error ${response.statusCode}, usando fallback local');
      return generateRoutine(
        goal: goal,
        fitnessLevel: fitnessLevel,
        daysPerWeek: daysPerWeek,
        gender: gender,
        trainingLocation: trainingLocation,
      );
    } catch (e) {
      debugPrint(
          '[RoutineGeneratorService] Error con Gemini: $e, usando fallback local');
      return generateRoutine(
        goal: goal,
        fitnessLevel: fitnessLevel,
        daysPerWeek: daysPerWeek,
        gender: gender,
        trainingLocation: trainingLocation,
      );
    }
  }

  // ── Descripciones de equipamiento por ubicación ─────────────────────────
  static String _equipmentDescriptionEs(String location) {
    switch (location) {
      case 'Gimnasio':
        return 'Gimnasio completo: barras olímpicas, mancuernas, máquina de poleas, '
            'jalón, press de piernas, banco plano/inclinado/declinado, rack de '
            'sentadillas, cinta de correr, bicicleta estática, máquinas guiadas '
            'de pecho, hombros, espalda y piernas.';
      case 'Casa':
        return 'Entrenamiento en casa sin equipamiento específico: '
            'sillas y mesas (para fondos, step-ups y rows invertidos), '
            'mochilas o garrafas de agua como peso adicional, espacio en el suelo '
            'para ejercicios de suelo, paredes para handstands y piques isométricos. '
            'Usa SOLO ejercicios con peso corporal o con estos objetos domésticos.';
      case 'Aire libre con equipamiento':
        return 'Entrenamiento en exterior con equipamiento básico: '
            'juego de mancuernas ajustables, comba, bandas elásticas de resistencia, '
            'esterilla, suficiente espacio para moverse. '
            'Incluye ejercicios con mancuernas, trabajo de cardio con comba y '
            'ejercicios con bandas.';
      case 'Aire libre sin equipamiento':
        return 'Entrenamiento en exterior sin ningún equipamiento: '
            'solo el peso corporal y el entorno urbano (bancos de parque para fondos '
            'o step-ups, barras de parque para dominadas si hay, suelo, escaleras). '
            'Usa ÚNICAMENTE ejercicios de calistenia y peso corporal.';
      default:
        return location;
    }
  }

  static String _equipmentDescriptionEn(String location) {
    switch (location) {
      case 'Gimnasio':
        return 'Full gym: Olympic barbells, dumbbells, cable machines, lat pulldown, '
            'leg press, flat/incline/decline bench, squat rack, treadmill, stationary '
            'bike, guided machines for chest, shoulders, back and legs.';
      case 'Casa':
        return 'Home workout with no specific equipment: chairs and tables (for dips, '
            'step-ups and inverted rows), backpacks or water jugs as added weight, '
            'floor space for ground exercises, walls for handstand practice. '
            'Use ONLY bodyweight exercises or these household objects.';
      case 'Aire libre con equipamiento':
        return 'Outdoor training with basic equipment: adjustable dumbbell set, '
            'jump rope, resistance bands, mat, enough open space to move. '
            'Include dumbbell exercises, jump rope cardio and band work.';
      case 'Aire libre sin equipamiento':
        return 'Outdoor training with no equipment: bodyweight only and urban environment '
            '(park benches for dips or step-ups, pull-up bars if available, ground, stairs). '
            'Use ONLY calisthenics and bodyweight exercises.';
      default:
        return location;
    }
  }

  /// Genera una rutina completa según el perfil del usuario (local, sin IA)
  static List<WorkoutDayEntity> generateRoutine({
    required String goal,
    required String fitnessLevel,
    required int daysPerWeek,
    required String gender,
    String trainingLocation = 'Gimnasio',
  }) {
    final bool noEquipment = trainingLocation == 'Casa' ||
        trainingLocation == 'Aire libre sin equipamiento';
    List<WorkoutDayEntity> days;
    switch (goal) {
      case 'Bajar peso':
        days = _weightLossRoutine(fitnessLevel, daysPerWeek);
        break;
      case 'Ganar músculo':
        days = _muscleGainRoutine(fitnessLevel, daysPerWeek);
        break;
      case 'Resistencia':
        days = _enduranceRoutine(fitnessLevel, daysPerWeek);
        break;
      case 'Rehabilitación':
        days = _rehabilitationRoutine(fitnessLevel, daysPerWeek);
        break;
      default:
        days = _weightLossRoutine(fitnessLevel, daysPerWeek);
    }
    return noEquipment ? _substituteEquipment(days) : days;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BAJAR PESO
  // ══════════════════════════════════════════════════════════════════════════

  static List<WorkoutDayEntity> _weightLossRoutine(
      String level, int days) {
    if (level == 'Principiante') return _wlBeginner(days);
    if (level == 'Intermedio') return _wlIntermediate(days);
    return _wlAdvanced(days);
  }

  static List<WorkoutDayEntity> _wlBeginner(int days) {
    final allDays = [
      WorkoutDayEntity(
        dayNumber: 1,
        dayName: 'Día 1 — Cuerpo Completo A',
        focus: 'Fuerza general',
        exercises: [
          const ExerciseEntity(name: 'Sentadilla con peso corporal', sets: 3, reps: '15', rest: '60s'),
          const ExerciseEntity(name: 'Flexiones de brazos', sets: 3, reps: '10', rest: '60s', notes: 'Modificadas si es necesario'),
          const ExerciseEntity(name: 'Remo con mancuerna', sets: 3, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Puente de glúteos', sets: 3, reps: '15', rest: '45s'),
          const ExerciseEntity(name: 'Plancha abdominal', sets: 3, reps: '30s', rest: '45s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 2,
        dayName: 'Día 2 — Cardio HIIT',
        focus: 'Quema de grasa',
        exercises: [
          const ExerciseEntity(name: 'Jumping Jacks', sets: 3, reps: '45s', rest: '15s'),
          const ExerciseEntity(name: 'Rodillas al pecho (High Knees)', sets: 3, reps: '30s', rest: '30s'),
          const ExerciseEntity(name: 'Burpees', sets: 3, reps: '8', rest: '60s'),
          const ExerciseEntity(name: 'Mountain Climbers', sets: 3, reps: '30s', rest: '30s'),
          const ExerciseEntity(name: 'Saltos de tijera', sets: 3, reps: '45s', rest: '15s'),
          const ExerciseEntity(name: 'Saltar la cuerda (simulado)', sets: 3, reps: '1 min', rest: '60s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 3,
        dayName: 'Día 3 — Cuerpo Completo B',
        focus: 'Circuito funcional',
        exercises: [
          const ExerciseEntity(name: 'Zancadas alternas', sets: 3, reps: '12 c/pierna', rest: '60s'),
          const ExerciseEntity(name: 'Press de pecho con mancuernas', sets: 3, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Jalón al pecho (polea)', sets: 3, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Curl de bíceps', sets: 3, reps: '12', rest: '45s'),
          const ExerciseEntity(name: 'Extensión de tríceps', sets: 3, reps: '12', rest: '45s'),
          const ExerciseEntity(name: 'Crunches abdominales', sets: 3, reps: '20', rest: '30s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 4,
        dayName: 'Día 4 — Cardio Moderado + Core',
        focus: 'Resistencia y abdomen',
        exercises: [
          const ExerciseEntity(name: 'Caminata rápida / Bici estática', sets: 1, reps: '30 min', rest: '—', notes: 'Zona 2, ritmo moderado'),
          const ExerciseEntity(name: 'Plancha lateral', sets: 3, reps: '30s c/lado', rest: '30s'),
          const ExerciseEntity(name: 'Bicicleta abdominal', sets: 3, reps: '20', rest: '30s'),
          const ExerciseEntity(name: 'Elevación de piernas', sets: 3, reps: '15', rest: '30s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 5,
        dayName: 'Día 5 — Tren Inferior + HIIT',
        focus: 'Piernas y cardio',
        exercises: [
          const ExerciseEntity(name: 'Sentadilla goblet', sets: 3, reps: '15', rest: '60s'),
          const ExerciseEntity(name: 'Peso muerto rumano', sets: 3, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Hip Thrust', sets: 3, reps: '15', rest: '60s'),
          const ExerciseEntity(name: 'Saltos al cajón', sets: 3, reps: '10', rest: '60s'),
          const ExerciseEntity(name: 'Sprint intervalado', sets: 6, reps: '20s sprint / 40s caminar', rest: '—'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 6,
        dayName: 'Día 6 — Cardio + Movilidad',
        focus: 'Actividad activa de recuperación',
        exercises: [
          const ExerciseEntity(name: 'Trote suave', sets: 1, reps: '20 min', rest: '—'),
          const ExerciseEntity(name: 'Estiramiento de cuádriceps', sets: 2, reps: '30s c/lado', rest: '10s'),
          const ExerciseEntity(name: 'Estiramiento de isquiotibiales', sets: 2, reps: '30s c/lado', rest: '10s'),
          const ExerciseEntity(name: 'Estiramiento de pecho', sets: 2, reps: '30s', rest: '10s'),
          const ExerciseEntity(name: 'Cat-Cow (movilidad lumbar)', sets: 2, reps: '10', rest: '20s'),
          const ExerciseEntity(name: 'Rotaciones de cadera', sets: 2, reps: '10 c/lado', rest: '10s'),
        ],
      ),
    ];
    return allDays.take(days).toList();
  }

  static List<WorkoutDayEntity> _wlIntermediate(int days) {
    final allDays = [
      WorkoutDayEntity(
        dayNumber: 1,
        dayName: 'Día 1 — Tren Superior (Empuje)',
        focus: 'Pecho · Hombro · Tríceps',
        exercises: [
          const ExerciseEntity(name: 'Press de banca con barra', sets: 4, reps: '12', rest: '75s'),
          const ExerciseEntity(name: 'Press de hombro con mancuernas', sets: 3, reps: '12', rest: '75s'),
          const ExerciseEntity(name: 'Aperturas en polea', sets: 3, reps: '15', rest: '60s'),
          const ExerciseEntity(name: 'Elevaciones laterales', sets: 3, reps: '15', rest: '45s'),
          const ExerciseEntity(name: 'Fondos en paralelas', sets: 3, reps: '12', rest: '60s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 2,
        dayName: 'Día 2 — HIIT + Core',
        focus: 'Cardio intenso',
        exercises: [
          const ExerciseEntity(name: 'Calentamiento: trote suave', sets: 1, reps: '5 min', rest: '—'),
          const ExerciseEntity(name: 'Burpees', sets: 4, reps: '10', rest: '60s'),
          const ExerciseEntity(name: 'Box Jumps', sets: 4, reps: '10', rest: '60s'),
          const ExerciseEntity(name: 'Thruster con mancuernas', sets: 4, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Plancha con remo alternado', sets: 3, reps: '10 c/lado', rest: '45s'),
          const ExerciseEntity(name: 'Russian Twist', sets: 3, reps: '20', rest: '30s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 3,
        dayName: 'Día 3 — Tren Inferior',
        focus: 'Cuádriceps · Isquios · Glúteos',
        exercises: [
          const ExerciseEntity(name: 'Sentadilla con barra', sets: 4, reps: '10', rest: '90s'),
          const ExerciseEntity(name: 'Peso muerto rumano', sets: 4, reps: '12', rest: '90s'),
          const ExerciseEntity(name: 'Prensa de piernas', sets: 3, reps: '15', rest: '75s'),
          const ExerciseEntity(name: 'Curl femoral tumbado', sets: 3, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Elevación de gemelos de pie', sets: 4, reps: '20', rest: '45s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 4,
        dayName: 'Día 4 — Tren Superior (Tirón)',
        focus: 'Espalda · Bíceps',
        exercises: [
          const ExerciseEntity(name: 'Dominadas (o jalón al pecho)', sets: 4, reps: '8-10', rest: '90s'),
          const ExerciseEntity(name: 'Remo con barra', sets: 4, reps: '10', rest: '75s'),
          const ExerciseEntity(name: 'Remo en polea sentado', sets: 3, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Curl de bíceps con barra', sets: 3, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Curl martillo', sets: 3, reps: '12', rest: '45s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 5,
        dayName: 'Día 5 — Cardio Zona 2 + Abdomen',
        focus: 'Quema de grasa sostenida',
        exercises: [
          const ExerciseEntity(name: 'Carrera continua o bicicleta', sets: 1, reps: '35–45 min', rest: '—', notes: 'FC: 60–70% máximo'),
          const ExerciseEntity(name: 'Plancha abdominal', sets: 4, reps: '45s', rest: '30s'),
          const ExerciseEntity(name: 'Tijeras abdominales', sets: 3, reps: '15', rest: '30s'),
          const ExerciseEntity(name: 'Elevación de piernas colgado', sets: 3, reps: '12', rest: '45s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 6,
        dayName: 'Día 6 — Full Body Circuito',
        focus: 'Quema metabólica',
        exercises: [
          const ExerciseEntity(name: 'Sentadilla + press (thrusters)', sets: 4, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Peso muerto + remo', sets: 4, reps: '10', rest: '60s'),
          const ExerciseEntity(name: 'Escaladores (Mountain Climbers)', sets: 4, reps: '30s', rest: '30s'),
          const ExerciseEntity(name: 'Press de banca con mancuernas', sets: 3, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Saltos al cajón', sets: 3, reps: '10', rest: '60s'),
        ],
      ),
    ];
    return allDays.take(days).toList();
  }

  static List<WorkoutDayEntity> _wlAdvanced(int days) {
    final base = _wlIntermediate(days);
    // En nivel avanzado se incrementan series y se añade más intensidad
    return base.map((day) {
      final upgraded = day.exercises.map((ex) {
        if (ex.sets < 5) {
          return ExerciseEntity(
            name: ex.name,
            sets: ex.sets + 1,
            reps: ex.reps,
            rest: ex.rest,
            notes: ex.notes,
          );
        }
        return ex;
      }).toList();
      return WorkoutDayEntity(
        dayNumber: day.dayNumber,
        dayName: day.dayName,
        focus: day.focus,
        exercises: upgraded,
      );
    }).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GANAR MÚSCULO
  // ══════════════════════════════════════════════════════════════════════════

  static List<WorkoutDayEntity> _muscleGainRoutine(String level, int days) {
    if (level == 'Principiante') return _mgBeginner(days);
    if (level == 'Intermedio') return _mgIntermediate(days);
    return _mgAdvanced(days);
  }

  static List<WorkoutDayEntity> _mgBeginner(int days) {
    final allDays = [
      WorkoutDayEntity(
        dayNumber: 1,
        dayName: 'Día 1 — Cuerpo Completo A',
        focus: 'Fuerza base',
        exercises: [
          const ExerciseEntity(name: 'Sentadilla con barra (o goblet)', sets: 3, reps: '10', rest: '90s'),
          const ExerciseEntity(name: 'Press de banca', sets: 3, reps: '10', rest: '90s'),
          const ExerciseEntity(name: 'Remo pendlay', sets: 3, reps: '10', rest: '90s'),
          const ExerciseEntity(name: 'Press de hombro', sets: 3, reps: '10', rest: '75s'),
          const ExerciseEntity(name: 'Curl de bíceps', sets: 2, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Extensión de tríceps', sets: 2, reps: '12', rest: '60s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 2,
        dayName: 'Día 2 — Cuerpo Completo B',
        focus: 'Fuerza e hipertrofia',
        exercises: [
          const ExerciseEntity(name: 'Peso muerto', sets: 3, reps: '8', rest: '120s'),
          const ExerciseEntity(name: 'Press de banca inclinado', sets: 3, reps: '10', rest: '90s'),
          const ExerciseEntity(name: 'Jalón al pecho', sets: 3, reps: '10', rest: '90s'),
          const ExerciseEntity(name: 'Zancadas con mancuernas', sets: 3, reps: '10 c/pierna', rest: '75s'),
          const ExerciseEntity(name: 'Elevaciones laterales', sets: 3, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Plancha abdominal', sets: 3, reps: '30s', rest: '30s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 3,
        dayName: 'Día 3 — Cuerpo Completo C',
        focus: 'Potencia',
        exercises: [
          const ExerciseEntity(name: 'Sentadilla frontal', sets: 4, reps: '8', rest: '120s'),
          const ExerciseEntity(name: 'Dominadas con agarre supino', sets: 3, reps: 'Máx', rest: '90s'),
          const ExerciseEntity(name: 'Press militar con barra', sets: 3, reps: '8', rest: '90s'),
          const ExerciseEntity(name: 'Hip Thrust', sets: 3, reps: '12', rest: '75s'),
          const ExerciseEntity(name: 'Curl concentrado', sets: 3, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Fondos en paralelas', sets: 3, reps: '10', rest: '75s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 4,
        dayName: 'Día 4 — Tren Inferior',
        focus: 'Piernas completas',
        exercises: [
          const ExerciseEntity(name: 'Sentadilla búlgara', sets: 4, reps: '10 c/pierna', rest: '90s'),
          const ExerciseEntity(name: 'Prensa de piernas', sets: 4, reps: '12', rest: '90s'),
          const ExerciseEntity(name: 'Extensión de cuádriceps', sets: 3, reps: '15', rest: '60s'),
          const ExerciseEntity(name: 'Curl femoral', sets: 3, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Gemelos en prensa', sets: 4, reps: '20', rest: '45s'),
        ],
      ),
    ];
    return allDays.take(days).toList();
  }

  static List<WorkoutDayEntity> _mgIntermediate(int days) {
    final allDays = [
      WorkoutDayEntity(
        dayNumber: 1,
        dayName: 'Día 1 — Pecho y Tríceps',
        focus: 'Empuje superior',
        exercises: [
          const ExerciseEntity(name: 'Press de banca con barra', sets: 4, reps: '8-10', rest: '120s'),
          const ExerciseEntity(name: 'Press inclinado con mancuernas', sets: 4, reps: '10', rest: '90s'),
          const ExerciseEntity(name: 'Aperturas en banco plano', sets: 3, reps: '12', rest: '75s'),
          const ExerciseEntity(name: 'Press de pecho en polea', sets: 3, reps: '15', rest: '60s'),
          const ExerciseEntity(name: 'Fondos con lastre', sets: 3, reps: '10', rest: '90s'),
          const ExerciseEntity(name: 'Extensión de tríceps en polea', sets: 3, reps: '15', rest: '60s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 2,
        dayName: 'Día 2 — Espalda y Bíceps',
        focus: 'Tirón superior',
        exercises: [
          const ExerciseEntity(name: 'Peso muerto convencional', sets: 4, reps: '6', rest: '150s'),
          const ExerciseEntity(name: 'Dominadas lastradas', sets: 4, reps: '8', rest: '120s'),
          const ExerciseEntity(name: 'Remo con barra (Pendlay)', sets: 3, reps: '8', rest: '90s'),
          const ExerciseEntity(name: 'Remo en polea baja', sets: 3, reps: '12', rest: '75s'),
          const ExerciseEntity(name: 'Curl de bíceps con barra EZ', sets: 3, reps: '10', rest: '75s'),
          const ExerciseEntity(name: 'Curl inclinado con mancuernas', sets: 3, reps: '12', rest: '60s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 3,
        dayName: 'Día 3 — Piernas',
        focus: 'Cuádriceps · Isquios · Glúteos',
        exercises: [
          const ExerciseEntity(name: 'Sentadilla trasera', sets: 5, reps: '5', rest: '180s'),
          const ExerciseEntity(name: 'Sentadilla búlgara', sets: 3, reps: '10 c/pierna', rest: '90s'),
          const ExerciseEntity(name: 'Extensión de cuádriceps', sets: 3, reps: '15', rest: '60s'),
          const ExerciseEntity(name: 'Curl femoral tumbado', sets: 3, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Hip Thrust con barra', sets: 4, reps: '10', rest: '90s'),
          const ExerciseEntity(name: 'Gemelos de pie en multipower', sets: 4, reps: '18', rest: '45s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 4,
        dayName: 'Día 4 — Hombro y Abdomen',
        focus: 'Deltoides · Core',
        exercises: [
          const ExerciseEntity(name: 'Press militar con barra', sets: 4, reps: '8', rest: '120s'),
          const ExerciseEntity(name: 'Press Arnold', sets: 3, reps: '12', rest: '90s'),
          const ExerciseEntity(name: 'Elevaciones laterales', sets: 4, reps: '15', rest: '60s'),
          const ExerciseEntity(name: 'Pájaro (Bent-over lateral raise)', sets: 3, reps: '15', rest: '60s'),
          const ExerciseEntity(name: 'Encogimientos con barra', sets: 3, reps: '15', rest: '60s'),
          const ExerciseEntity(name: 'Plancha abdominal', sets: 3, reps: '60s', rest: '30s'),
          const ExerciseEntity(name: 'Ab wheel (rueda abdominal)', sets: 3, reps: '10', rest: '60s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 5,
        dayName: 'Día 5 — Full Body Potencia',
        focus: 'Fuerza funcional',
        exercises: [
          const ExerciseEntity(name: 'Clean and press', sets: 4, reps: '6', rest: '150s'),
          const ExerciseEntity(name: 'Sentadilla pausa', sets: 4, reps: '5', rest: '150s'),
          const ExerciseEntity(name: 'Remo pendlay explosivo', sets: 3, reps: '6', rest: '120s'),
          const ExerciseEntity(name: 'Press de banca con pausa', sets: 3, reps: '6', rest: '120s'),
          const ExerciseEntity(name: 'Farmer Walks', sets: 3, reps: '30m', rest: '90s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 6,
        dayName: 'Día 6 — Brazos + Core',
        focus: 'Bíceps · Tríceps · Abdomen',
        exercises: [
          const ExerciseEntity(name: 'Curl araña', sets: 4, reps: '10', rest: '75s'),
          const ExerciseEntity(name: 'Curl de bíceps en polea baja', sets: 3, reps: '15', rest: '60s'),
          const ExerciseEntity(name: 'Press francés', sets: 4, reps: '10', rest: '75s'),
          const ExerciseEntity(name: 'Diamond push-ups', sets: 3, reps: '12', rest: '60s'),
          const ExerciseEntity(name: 'Dragon flag (progresión)', sets: 3, reps: '6', rest: '90s'),
          const ExerciseEntity(name: 'Elevación de piernas colgado', sets: 3, reps: '12', rest: '60s'),
        ],
      ),
    ];
    return allDays.take(days).toList();
  }

  static List<WorkoutDayEntity> _mgAdvanced(int days) {
    // Avanzado añade técnicas de intensidad: dropsets, superseries
    final base = _mgIntermediate(days);
    return base.map((day) {
      return WorkoutDayEntity(
        dayNumber: day.dayNumber,
        dayName: day.dayName,
        focus: '${day.focus} (Avanzado)',
        exercises: day.exercises.map((ex) {
          return ExerciseEntity(
            name: ex.name,
            sets: ex.sets,
            reps: ex.reps,
            rest: ex.rest,
            notes: ex.notes.isEmpty
                ? 'Técnica avanzada: aplica dropset en última serie'
                : ex.notes,
          );
        }).toList(),
      );
    }).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RESISTENCIA
  // ══════════════════════════════════════════════════════════════════════════

  static List<WorkoutDayEntity> _enduranceRoutine(String level, int days) {
    final multiplier = level == 'Principiante'
        ? 1.0
        : level == 'Intermedio'
            ? 1.3
            : 1.6; // Factor para ajustar duración
    final durationMin = (30 * multiplier).round();

    final allDays = [
      WorkoutDayEntity(
        dayNumber: 1,
        dayName: 'Día 1 — Carrera de Base',
        focus: 'Zona aeróbica 2',
        exercises: [
          ExerciseEntity(name: 'Calentamiento: caminata', sets: 1, reps: '5 min', rest: '—'),
          ExerciseEntity(name: 'Carrera continua', sets: 1, reps: '$durationMin min', rest: '—', notes: 'Ritmo conversacional (FC 65–75%)'),
          const ExerciseEntity(name: 'Estiramiento de cuádriceps', sets: 2, reps: '30s c/lado', rest: '10s'),
          const ExerciseEntity(name: 'Estiramiento de pantorrilla', sets: 2, reps: '30s c/lado', rest: '10s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 2,
        dayName: 'Día 2 — Fuerza Funcional',
        focus: 'Soporte muscular',
        exercises: [
          const ExerciseEntity(name: 'Sentadilla con peso corporal', sets: 3, reps: '20', rest: '60s'),
          const ExerciseEntity(name: 'Zancadas caminando', sets: 3, reps: '15 c/pierna', rest: '60s'),
          const ExerciseEntity(name: 'Flexiones de brazos', sets: 3, reps: '15', rest: '60s'),
          const ExerciseEntity(name: 'Remo TRX / mancuerna', sets: 3, reps: '15', rest: '60s'),
          const ExerciseEntity(name: 'Plancha abdominal', sets: 3, reps: '45s', rest: '30s'),
          const ExerciseEntity(name: 'Superman / extensiones de espalda', sets: 3, reps: '12', rest: '45s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 3,
        dayName: 'Día 3 — Intervalos Aeróbicos',
        focus: 'Umbral láctico',
        exercises: [
          const ExerciseEntity(name: 'Calentamiento: trote suave', sets: 1, reps: '10 min', rest: '—'),
          const ExerciseEntity(name: 'Intervalos (1 min rápido / 2 min suave)', sets: 6, reps: '3 min c/u', rest: 'incluido'),
          const ExerciseEntity(name: 'Vuelta a la calma: trote', sets: 1, reps: '5 min', rest: '—'),
          const ExerciseEntity(name: 'Estiramiento completo', sets: 1, reps: '10 min', rest: '—'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 4,
        dayName: 'Día 4 — Bicicleta / Elíptica',
        focus: 'Cardio cruzado',
        exercises: [
          ExerciseEntity(name: 'Bicicleta estática o elíptica', sets: 1, reps: '${(durationMin + 10)} min', rest: '—', notes: 'Baja impacto, alta cadencia'),
          const ExerciseEntity(name: 'Core: plancha lateral', sets: 3, reps: '30s c/lado', rest: '20s'),
          const ExerciseEntity(name: 'Glúteo en cuadrupedia', sets: 3, reps: '15 c/lado', rest: '30s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 5,
        dayName: 'Día 5 — Carrera Larga',
        focus: 'Resistencia aeróbica prolongada',
        exercises: [
          const ExerciseEntity(name: 'Calentamiento: caminata rápida', sets: 1, reps: '5 min', rest: '—'),
          ExerciseEntity(name: 'Carrera larga continua', sets: 1, reps: '${(durationMin * 1.5).round()} min', rest: '—', notes: 'Ritmo suave y constante'),
          const ExerciseEntity(name: 'Enfriamiento y estiramiento', sets: 1, reps: '10 min', rest: '—'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 6,
        dayName: 'Día 6 — Recuperación Activa',
        focus: 'Movilidad y flexibilidad',
        exercises: [
          const ExerciseEntity(name: 'Yoga / estiramiento dinámico', sets: 1, reps: '20 min', rest: '—'),
          const ExerciseEntity(name: 'Espuma (foam rolling)', sets: 1, reps: '10 min', rest: '—'),
          const ExerciseEntity(name: 'Respiración diafragmática', sets: 3, reps: '5 min', rest: '—'),
        ],
      ),
    ];
    return allDays.take(days).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REHABILITACIÓN
  // ══════════════════════════════════════════════════════════════════════════

  static List<WorkoutDayEntity> _rehabilitationRoutine(
      String level, int days) {
    final allDays = [
      WorkoutDayEntity(
        dayNumber: 1,
        dayName: 'Día 1 — Movilidad y Flexibilidad',
        focus: 'Rango de movimiento',
        exercises: [
          const ExerciseEntity(name: 'Rotaciones de cuello suaves', sets: 2, reps: '10 c/lado', rest: '30s', notes: 'Movimientos lentos y controlados'),
          const ExerciseEntity(name: 'Círculos de hombros', sets: 2, reps: '10 adelante/atrás', rest: '20s'),
          const ExerciseEntity(name: 'Estiramiento de pecho (pared)', sets: 3, reps: '30s c/lado', rest: '15s'),
          const ExerciseEntity(name: 'Cat-Cow (movilidad lumbar)', sets: 3, reps: '10', rest: '30s'),
          const ExerciseEntity(name: 'Estiramiento de cadera en mariposa', sets: 3, reps: '45s', rest: '15s'),
          const ExerciseEntity(name: 'Estiramiento de isquiotibiales en suelo', sets: 3, reps: '30s c/lado', rest: '15s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 2,
        dayName: 'Día 2 — Estabilidad de Core',
        focus: 'Musculatura profunda',
        exercises: [
          const ExerciseEntity(name: 'Activación transverso abdominal', sets: 3, reps: '10 respiraciones', rest: '30s', notes: 'Contrae el abdomen sin mover la columna'),
          const ExerciseEntity(name: 'Plancha abdominal (progresión)', sets: 3, reps: '15-30s', rest: '45s'),
          const ExerciseEntity(name: 'Perro-pájaro (Bird-Dog)', sets: 3, reps: '8 c/lado', rest: '30s'),
          const ExerciseEntity(name: 'Puente de glúteos', sets: 3, reps: '15', rest: '45s'),
          const ExerciseEntity(name: 'Clamshell con banda', sets: 3, reps: '15 c/lado', rest: '30s'),
          const ExerciseEntity(name: 'Superman en suelo', sets: 3, reps: '10', rest: '30s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 3,
        dayName: 'Día 3 — Fortalecimiento Suave (Tren Inferior)',
        focus: 'Piernas de bajo impacto',
        exercises: [
          const ExerciseEntity(name: 'Sentadilla asistida (silla)', sets: 3, reps: '10', rest: '60s', notes: 'Usa apoyo si es necesario'),
          const ExerciseEntity(name: 'Elevación de talones sentado', sets: 3, reps: '20', rest: '30s'),
          const ExerciseEntity(name: 'Abducción de cadera tumbado', sets: 3, reps: '15 c/lado', rest: '30s'),
          const ExerciseEntity(name: 'Extensión de rodilla sentado (banda)', sets: 3, reps: '15', rest: '45s'),
          const ExerciseEntity(name: 'Marcha en el sitio', sets: 3, reps: '1 min', rest: '30s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 4,
        dayName: 'Día 4 — Fortalecimiento Suave (Tren Superior)',
        focus: 'Hombros y espalda baja',
        exercises: [
          const ExerciseEntity(name: 'Retracción escapular', sets: 3, reps: '15', rest: '30s', notes: 'Promueve la postura correcta'),
          const ExerciseEntity(name: 'Press de hombros con banda (sentado)', sets: 3, reps: '12', rest: '45s'),
          const ExerciseEntity(name: 'Remo con banda elástica', sets: 3, reps: '15', rest: '45s'),
          const ExerciseEntity(name: 'Rotación externa de hombro (banda)', sets: 3, reps: '15 c/lado', rest: '30s'),
          const ExerciseEntity(name: 'Face pull con banda', sets: 3, reps: '15', rest: '30s'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 5,
        dayName: 'Día 5 — Cardio de Bajo Impacto',
        focus: 'Actividad cardiovascular suave',
        exercises: [
          const ExerciseEntity(name: 'Caminata a paso ligero', sets: 1, reps: '25-30 min', rest: '—', notes: 'Ritmo cómodo, sin dolor'),
          const ExerciseEntity(name: 'Bicicleta estática (nivel bajo)', sets: 1, reps: '15 min', rest: '—'),
          const ExerciseEntity(name: 'Estiramiento post-cardio', sets: 1, reps: '10 min', rest: '—'),
        ],
      ),
      WorkoutDayEntity(
        dayNumber: 6,
        dayName: 'Día 6 — Yoga Terapéutico',
        focus: 'Recuperación integral',
        exercises: [
          const ExerciseEntity(name: 'Postura del niño (Child\'s pose)', sets: 3, reps: '1 min', rest: '20s'),
          const ExerciseEntity(name: 'Giro espinal sentado', sets: 2, reps: '30s c/lado', rest: '20s'),
          const ExerciseEntity(name: 'Estiramiento de piriforme (figura 4)', sets: 2, reps: '45s c/lado', rest: '15s'),
          const ExerciseEntity(name: 'Postura del cadáver (Savasana)', sets: 1, reps: '5 min', rest: '—', notes: 'Relajación total'),
          const ExerciseEntity(name: 'Respiración 4-7-8', sets: 5, reps: '1 ciclo', rest: '—'),
        ],
      ),
    ];
    return allDays.take(days).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUSTITUCIÓN SIN EQUIPO (Casa / Aire libre sin equipamiento)
  // ══════════════════════════════════════════════════════════════════════════

  /// Mapa: nombre exacto del ejercicio con equipo → alternativa sin equipo
  static const Map<String, String> _gymToBodyweight = {
    // ── Mancuernas ──────────────────────────────────────────────────────────
    'Remo con mancuerna': 'Remo invertido (debajo de mesa)',
    'Press de pecho con mancuernas': 'Flexiones de brazos',
    'Press de hombro con mancuernas': 'Pike push-ups',
    'Press de banca con mancuernas': 'Flexiones de brazos',
    'Press inclinado con mancuernas': 'Flexiones con pies elevados',
    'Zancadas con mancuernas': 'Zancadas alternas',
    'Thruster con mancuernas': 'Sentadilla + salto explosivo',
    'Aperturas en banco plano': 'Aperturas en posicion de plancha',
    'Curl inclinado con mancuernas': 'Curl isometrico con toalla',
    'Press Arnold': 'Pike push-ups',
    'Sentadilla goblet': 'Sentadilla con peso corporal',
    'Elevaciones laterales': 'Elevaciones laterales lentas sin peso',
    // ── Barra ────────────────────────────────────────────────────────────────
    'Press de banca con barra': 'Flexiones de brazos',
    'Press de banca inclinado': 'Flexiones con pies elevados',
    'Press de banca con pausa': 'Flexiones con pausa',
    'Sentadilla con barra': 'Sentadilla con peso corporal',
    'Sentadilla con barra (o goblet)': 'Sentadilla con peso corporal',
    'Sentadilla trasera': 'Sentadilla con peso corporal',
    'Sentadilla frontal': 'Sentadilla con peso corporal',
    'Sentadilla pausa': 'Sentadilla con peso corporal (pausa)',
    'Peso muerto convencional': 'Buenos dias con peso corporal',
    'Peso muerto rumano': 'Buenos dias con peso corporal',
    'Peso muerto + remo': 'Buenos dias + remo invertido en suelo',
    'Remo pendlay': 'Remo invertido (debajo de mesa)',
    'Remo con barra (Pendlay)': 'Remo invertido (debajo de mesa)',
    'Remo con barra': 'Remo invertido (debajo de mesa)',
    'Remo pendlay explosivo': 'Remo invertido explosivo',
    'Press militar con barra': 'Pike push-ups',
    'Encogimientos con barra': 'Encogimientos de hombros sin peso',
    'Curl de bíceps con barra EZ': 'Flexiones con agarre supino',
    'Curl de bíceps con barra': 'Flexiones con agarre supino',
    'Curl de bíceps': 'Curl isometrico con toalla',
    'Curl martillo': 'Flexiones diamante',
    'Curl araña': 'Flexiones concentradas agarre supino',
    'Hip Thrust con barra': 'Puente de gluteos',
    'Hip Thrust': 'Puente de gluteos',
    'Clean and press': 'Burpee con salto explosivo',
    'Farmer Walks': 'Caminata en puntillas (isometrico de hombros)',
    // ── Poleas y maquinas ────────────────────────────────────────────────────
    'Jalón al pecho (polea)': 'Dominadas (o remo invertido)',
    'Aperturas en polea': 'Aperturas en posicion de plancha',
    'Press de pecho en polea': 'Flexiones de brazos',
    'Remo en polea sentado': 'Remo invertido (debajo de mesa)',
    'Remo en polea baja': 'Remo invertido (debajo de mesa)',
    'Extensión de tríceps en polea': 'Flexiones diamante',
    'Curl de bíceps en polea baja': 'Curl isometrico con toalla',
    'Prensa de piernas': 'Sentadilla bulgara sin peso',
    'Extensión de cuádriceps': 'Sentadilla isometrica en pared',
    'Curl femoral tumbado': 'Curl femoral nordico (con silla como apoyo)',
    'Curl femoral': 'Curl femoral nordico (con silla como apoyo)',
    'Gemelos de pie en multipower': 'Elevacion de gemelos de pie',
    'Gemelos en prensa': 'Elevacion de gemelos de pie',
    'Ab wheel (rueda abdominal)': 'Plancha deslizante en suelo',
    'Dragon flag (progresión)': 'Plancha con elevacion de piernas',
    'Elevación de piernas colgado': 'Elevacion de piernas en suelo',
    'Box Jumps': 'Saltos al lugar',
    'Saltos al cajón': 'Saltos al lugar',
    'Fondos con lastre': 'Fondos entre sillas',
    'Fondos en paralelas': 'Fondos entre sillas',
    'Dominadas lastradas': 'Dominadas',
    // ── Combinados / cardio maquina ──────────────────────────────────────────
    'Sentadilla + press (thrusters)': 'Sentadilla + salto explosivo',
    'Plancha con remo alternado': 'Plancha con toque de hombro',
    'Caminata rápida / Bici estática': 'Caminata rapida o marcha en el sitio',
    'Bicicleta estática o elíptica': 'Saltos de tijera (ritmo moderado)',
    'Carrera continua o bicicleta': 'Carrera continua o caminata rapida',
    'Remo TRX / mancuerna': 'Remo invertido (debajo de mesa)',
    // ── Bandas (rehabilitacion) ──────────────────────────────────────────────
    'Clamshell con banda': 'Clamshell sin banda',
    'Press de hombros con banda (sentado)': 'Pike push-ups modificados',
    'Remo con banda elástica': 'Remo invertido (debajo de mesa)',
    'Rotación externa de hombro (banda)': 'Rotacion de hombro isometrica',
    'Face pull con banda': 'YTW en prono (suelo)',
    'Extensión de rodilla sentado (banda)': 'Extension de rodilla sentado sin banda',
  };

  /// Palabras clave que delatan equipo de gimnasio (red de seguridad)
  static const List<String> _gymKeywords = [
    'mancuerna', 'barra', 'banca', 'polea', 'prensa',
    'multipower', 'jalón', 'máquina', 'lastre', 'TRX',
    'banda elástica',
  ];

  /// Reemplaza los ejercicios que requieren equipamiento por alternativas
  /// de peso corporal en toda la lista de días.
  static List<WorkoutDayEntity> _substituteEquipment(
      List<WorkoutDayEntity> days) {
    return days.map((day) {
      return WorkoutDayEntity(
        dayNumber: day.dayNumber,
        dayName: day.dayName,
        focus: day.focus,
        exercises: day.exercises.map((ex) {
          // 1. Coincidencia exacta en el mapa principal
          final exact = _gymToBodyweight[ex.name];
          if (exact != null) {
            return ExerciseEntity(
              name: exact,
              sets: ex.sets,
              reps: ex.reps,
              rest: ex.rest,
              notes: ex.notes,
            );
          }
          // 2. Red de seguridad: si el nombre contiene keyword de equipo
          final lower = ex.name.toLowerCase();
          final hasGym = _gymKeywords.any((k) => lower.contains(k));
          if (hasGym) {
            return ExerciseEntity(
              name: ex.name,
              sets: ex.sets,
              reps: ex.reps,
              rest: ex.rest,
              notes: 'Adaptar a version con peso corporal',
            );
          }
          return ex;
        }).toList(),
      );
    }).toList();
  }
}
