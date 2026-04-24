import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:horus_app/core/config/secrets.dart';
import 'package:http/http.dart' as http;

/// Servicio de chatbot de HorusAPP.
/// Usa Gemini (gemini-2.0-flash) como motor principal con fallback local basado
/// en palabras clave para cuando no haya conexión o la API falle.
class ChatbotService {
  ChatbotService._();

  static final Random _random = Random();

  // ── Gemini API ────────────────────────────────────────────────────────────
  static const _apiKey = AppSecrets.geminiApiKey;
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';

  static String _buildSystemPrompt(bool isEnglish) => isEnglish
      ? 'You are Horus, the virtual personal trainer of HorusAPP. '
          'Your specialty is fitness, sports nutrition, weight training, '
          'cardio, muscle recovery and health in general. '
          'ALWAYS respond in English, with a friendly, motivating and direct tone. '
          'Be concise (maximum 3-4 short paragraphs). You can use emojis in moderation. '
          'If asked about something unrelated to sports, nutrition or health, politely explain '
          'you can only help with fitness topics and redirect the conversation.'
      : 'Eres Horus, el entrenador personal virtual de HorusAPP. '
          'Tu especialidad es el fitness, la nutrición deportiva, el entrenamiento con pesas, '
          'el cardio, la recuperación muscular y la salud en general. '
          'Responde SIEMPRE en español, con un tono cercano, motivador y directo. '
          'Sé conciso (máximo 3-4 párrafos cortos). Puedes usar emojis con moderación. '
          'Si te preguntan algo ajeno al deporte, la nutrición o la salud, responde '
          'amablemente que solo puedes ayudar con temas fitness y redirige la conversación.';

  /// Genera una respuesta usando Gemini. Recibe el mensaje actual y el historial
  /// de la conversación. Si la llamada falla, usa el sistema local de palabras
  /// clave como fallback.
  static Future<String> generateResponse(
    String userMessage,
    List<Map<String, String>> history, {
    bool isEnglish = false,
  }) async {
    final systemPrompt = _buildSystemPrompt(isEnglish);
    try {
      final contents = <Map<String, dynamic>>[];
      for (final msg in history) {
        contents.add({
          'role': msg['role'],
          'parts': [
            {'text': msg['text']}
          ],
        });
      }
      contents.add({
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ],
      });

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
                  {'text': systemPrompt}
                ]
              },
              'contents': contents,
              'generationConfig': {'maxOutputTokens': 350},
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        return text.trim();
      }

      // Reintento automático si el servidor está sobrecargado
      if (response.statusCode == 503) {
        await Future.delayed(const Duration(seconds: 1));
        final retry = await http
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Content-Type': 'application/json',
                'X-goog-api-key': _apiKey,
              },
              body: jsonEncode({
                'system_instruction': {
                  'parts': [
                    {'text': systemPrompt}
                  ]
                },
                'contents': contents,
                'generationConfig': {'maxOutputTokens': 350},
              }),
            )
            .timeout(const Duration(seconds: 15));
        if (retry.statusCode == 200) {
          final data = jsonDecode(retry.body) as Map<String, dynamic>;
          final text =
              data['candidates'][0]['content']['parts'][0]['text'] as String;
          return text.trim();
        }
      }

      debugPrint(
          '[ChatbotService] Gemini error ${response.statusCode}: ${response.body}');
      return _localResponse(userMessage);
    } catch (e) {
      debugPrint('[ChatbotService] Error llamando a Gemini: $e');
      return _localResponse(userMessage);
    }
  }

  // ── Saludos ───────────────────────────────────────────────────────────────
  static const List<String> _greetings = [
    'Hola! Soy Horus, tu entrenador personal de confianza. Cuéntame, en que puedo ayudarte hoy? Ya sea nutrición, técnica, rutinas... estoy aquí para ti! 💪',
    'Buenas! Me alegra que hayas pasado por aquí. Dime, qué dudas fitness tienes hoy? 😊',
    'Ey, qué tal! Listo para dar lo mejor de ti? Pregúntame lo que necesites sobre entrenamiento, dieta o cualquier duda que tengas 🔥',
    'Hola! Aquí Horus, siempre dispuesto a ayudarte a ser tu mejor versión. Qué te trae por aquí? 💬',
  ];

  // ── Motivación ────────────────────────────────────────────────────────────
  static const List<String> _motivation = [
    'Oye, que los días difíciles existen para todos, pero precisamente ahí es donde se forja el carácter. El dolor de hoy es la fuerza de mañana. Tú puedes con esto y más! 💪',
    'Mira, no importa el ritmo, lo que importa es no parar. Cada pequeño paso cuenta más de lo que crees. Sigue adelante! 🚀',
    'Escucha: tu cuerpo puede con casi todo. Es la mente la que hay que convencer, y tú ya vas ganando esa batalla solo con estar aquí. Campeón! 🏆',
    'Cada vez que entrenas, aunque sea poco, estás invirtiendo en tu mejor versión. Eso merece reconocimiento. Orgullo! 🎯',
    'Los malos días también forman parte del proceso. Mañana será mejor, te lo prometo. No te rindas ahora! 💙',
  ];

  // ── Dieta ─────────────────────────────────────────────────────────────────
  static const List<String> _dietAdvice = [
    'Para perder grasa de forma inteligente: busca un déficit calórico del 15-20% y asegúrate de comer suficiente proteína (1.6-2g por kg de peso). Así pierdes grasa, no músculo! 🥗',
    'Las proteínas son tus mejores aliadas. Pollo, pavo, huevos, atún, legumbres... intenta repartirlas en 4-5 comidas al día para mantener el músculo activo. 🍗',
    'Antes de entrenar, dale a tu cuerpo algo de energía: un puñado de avena, un plátano o arroz unos 30-45 minutos antes. Notarás la diferencia! 🍌',
    'Post-entreno: tienes una ventana de oro de 30-60 minutos. Combina proteína + carbohidratos (batido con plátano, pollo con arroz...). Tu músculo te lo agradecerá. 🥛',
    'El agua es más importante de lo que parece. Intenta beber 2.5-3L al día y un extra de 500ml por cada hora de ejercicio intenso. 💧',
    'Las grasas saludables NO son el enemigo! Aguacate, frutos secos, aceite de oliva... son esenciales. Que representen el 20-30% de tus calorías diarias. 🥑',
  ];

  // ── Entrenamiento general ─────────────────────────────────────────────────
  static const List<String> _trainingAdvice = [
    'La clave del crecimiento es la progresión. Intenta subir el peso o las repeticiones cada semana. Sin ese estímulo nuevo, el cuerpo no tiene motivo para adaptarse. 🏋️',
    'El descanso entre series importa más de lo que crees: para hipertrofia 60-90s, para fuerza máxima 2-3 min, para resistencia menos de 60s. Ajusta según tu objetivo! ⏱️',
    'Cada 8-12 semanas cambia algún elemento de tu rutina (ejercicios, orden, rangos de rep). Tu cuerpo es muy listo y se adapta rápido. ¡Sorpréndelo! 🔄',
    'No subestimes el descanso. Es cuando duermes cuando tu cuerpo crece y se repara. Sin 7-9 horas de sueño, estás dejando resultados en la cama. 😴',
    'La técnica perfecta siempre va antes que el peso máximo. Un movimiento limpio con menos carga es mil veces mejor que uno chapucero con más. Tu cuerpo (y tus articulaciones) te lo agradecerán. 📏',
    'Los días de recuperación activa son tan importantes como los de entreno. Un paseo, algo de movilidad o yoga le dan a tus músculos el respiro que necesitan. 🧘',
  ];

  // ── Descanso ──────────────────────────────────────────────────────────────
  static const List<String> _restAdvice = [
    'Si tu cuerpo pide descanso, escúchalo! Un día extra de recuperación no arruina nada, al contrario, te hará rendir mejor al día siguiente. 😴',
    'El sobreentrenamiento es más común de lo que se cree. Si notas que tu rendimiento baja, estás irritable o no duermes bien... baja el ritmo 1-2 días. Tu cuerpo te lo pide. 💆',
    'Para recuperarte más rápido: prueba las duchas de contraste (30s frío, 30s calor), foam rolling en zonas tensas y asegúrate de dormir bien. Pequeños gestos, gran diferencia! 🧊',
  ];

  // ── Suplementos ───────────────────────────────────────────────────────────
  static const List<String> _supplementAdvice = [
    'Los suplementos son exactamente eso: complementos. La dieta y el entreno son el 95%. Con evidencia real solo destacan: proteína de suero, creatina, cafeína y omega-3. 💊',
    'La creatina monohidratada es el suplemento más estudiado y seguro que existe. 3-5g al día y ya está. No necesitas cargas ni ciclos. Muy efectiva para fuerza y músculo. ⚡',
    'La proteína en polvo no es mágica, es simplemente cómoda. Si con tu alimentación ya llegas a tu objetivo proteico diario, ni la necesitas. Pero si te cuesta, viene genial! 🫐',
  ];

  // ── Hombros ───────────────────────────────────────────────────────────────
  static const List<String> _shoulderAdvice = [
    'Los hombros se trabajan en 3 partes y hay que atacar todas! Una rutina que funciona muy bien:\n• Press de hombros con barra: 4×8\n• Elevaciones laterales: 3×12\n• Face pull en polea: 3×15\n• Pájaro con mancuernas: 3×12\n\nNo olvides el deltoides posterior, es el más descuidado y el más importante para la postura! 🔝',
    'El error más típico en hombros es ignorar el deltoides posterior. Incluye face pull y pájaros en TODAS las sesiones. Son clave para la salud del manguito rotador y para una espalda sana. 💡',
    'Para proteger los hombros a largo plazo, calienta siempre el manguito rotador con rotaciones externas con banda elástica (2×15). Y evita el press tras la nuca, es una bomba de tiempo para las articulaciones. ⚠️',
  ];

  // ── Piernas ───────────────────────────────────────────────────────────────
  static const List<String> _legAdvice = [
    'El día de piernas es el más duro, pero también el más rentable! Una sesión completa:\n• Sentadilla: 4×8\n• Peso muerto rumano: 3×10\n• Extensiones de cuádriceps: 3×12\n• Curl femoral: 3×12\n• Elevación de gemelos: 4×15\n\nNo te saltes las piernas, son el motor del cuerpo! 🦵',
    'La sentadilla es el ejercicio rey. Baja hasta que los muslos queden paralelos al suelo (o más). Rodillas alineadas con los pies, espalda recta, core apretado. Técnica limpia y el peso ya vendrá! 💡',
    'Mira, el día de piernas libera más testosterona y hormona de crecimiento que cualquier otro. Muy útil si quieres ganar masa en todo el cuerpo. Sé que es duro, pero vale la pena! ⚡',
  ];

  // ── Glúteos ───────────────────────────────────────────────────────────────
  static const List<String> _gluteAdvice = [
    'Para glúteos que se noten, aquí tienes lo que mejor funciona:\n• Hip thrust con barra: 4×10\n• Sentadilla sumo: 3×12\n• Patada trasera en polea: 3×15/lado\n• Abducción de cadera en máquina: 3×15\n\nConcentra siempre la contracción arriba, que es donde más se activa! 🍑',
    'El hip thrust es el ejercicio #1 para glúteos, hay estudios que lo demuestran. La clave está en hacer una extensión completa de cadera y apretar fuerte arriba. Con barras o en máquina, funciona igual. 💡',
    'Combina siempre compuestos (sentadilla sumo, peso muerto rumano) con aislamiento (abductores, patada en polea). Los primeros dan masa, los segundos dan forma. 📈',
  ];

  // ── Pecho ─────────────────────────────────────────────────────────────────
  static const List<String> _chestAdvice = [
    'Para un pecho completo hay que trabajar las tres zonas. Te propongo esto:\n• Press banca plano: 4×8\n• Press inclinado con mancuernas: 3×10\n• Aperturas en cable o mancuernas: 3×12\n• Fondos en paralelas: 3×fallo\n\nSiente el estiramiento en la bajada, ahí está la magia! 👐',
    'Si quieres más definición en pecho, añade crossover en cable al final. Cruza los brazos al máximo para activar las fibras internas. Notarás el pump! 💡',
    'Si el pecho no responde, revisa esto: escápulas retraídas, pecho arriba, codos a 45-75° del tronco. Siente el músculo trabajar, no solo muevas el peso. 📈',
  ];

  // ── Espalda ───────────────────────────────────────────────────────────────
  static const List<String> _backAdvice = [
    'Para una espalda amplia y gruesa, necesitas atacar desde varios ángulos:\n• Dominadas o jalón al pecho: 4×8\n• Remo con barra: 4×8\n• Remo con mancuerna: 3×10\n• Peso muerto: 3×5\n\nLas dominadas son el mejor ejercicio de espalda que existe, sin duda! 💪',
    'Si las dominadas te cuestan aún, usa la máquina de jalón asistida o elásticos para reducir el peso. Con consistencia, en pocas semanas las harás sin ayuda. Paciencia! 💡',
    'En el peso muerto: lumbar neutra, core muy apretado, barra pegada al cuerpo. Si redondeas la espalda, baja el peso. No hay prisa. La técnica es lo primero siempre. ⚠️',
  ];

  // ── Bíceps ────────────────────────────────────────────────────────────────
  static const List<String> _bicepAdvice = [
    'Para bíceps que destaquen, aquí lo que mejor funciona:\n• Curl con barra: 4×10\n• Curl martillo: 3×12\n• Curl concentrado: 3×12\n• Curl araña en banco inclinado: 3×10\n\nControla siempre la bajada (fase excéntrica), ahí también se construye músculo! 💪',
    'El curl concentrado y el curl araña son tus armas secretas para bíceps. Eliminan el impulso del cuerpo y obligan al músculo a trabajar solo. Úsalos para definir y aislar bien. 💡',
    'Con los bíceps no hace falta pegarse chorreos de peso. 8-15 reps bien hechas, sintiendo el músculo, valen más que tirar de la espalda con el doble. Calidad sobre cantidad! ⏱️',
  ];

  // ── Tríceps ───────────────────────────────────────────────────────────────
  static const List<String> _tricepAdvice = [
    'Que no se te olvide: el tríceps es 2/3 del volumen del brazo! Para trabajarlo bien:\n• Press francés con barra EZ: 3×10\n• Extensión de tríceps en polea: 3×12\n• Fondos en banco: 3×fallo\n• Press cerrado con barra: 4×8\n\nAsegúrate de cubrir las 3 cabezas! 💪',
    'Para las 3 cabezas del tríceps: usa extensiones por encima de la cabeza (overhead) para la cabeza larga, y polea o fondos para la externa y medial. Variedad es la clave. 💡',
    'El press cerrado y los fondos son los ejercicios más efectivos para masa en tríceps al ser compuestos. No los ignores en favor de las poleas! 🔑',
  ];

  // ── Abdominales ───────────────────────────────────────────────────────────
  static const List<String> _absAdvice = [
    'Los abdominales se hacen en la cocina y se construyen en el gym. La combinación que mejor funciona:\n• Plancha frontal: 3×45s\n• Crunch en polea: 3×15\n• Elevación de piernas colgado: 3×12\n• Rueda abdominal: 3×10\n• Plancha lateral: 3×30s/lado\n\nY déficit calórico para que se vean! 🔥',
    'El core no es solo hacer crunches. Para un núcleo de acero necesitas: anti-flexión (plancha), anti-rotación (pallof press) y flexión (crunch, elevación de piernas). Ataca desde todos los ángulos! 💡',
    'La verdad incómoda sobre los abdominales: si no bajas el porcentaje graso, no se verán cosechas tus esfuerzos. Dieta + cardio + trabajo de core = la fórmula real. ⚠️',
  ];

  // ── Cardio ────────────────────────────────────────────────────────────────
  static const List<String> _cardioAdvice = [
    'Para quemar grasa de forma eficiente, el HIIT es imbatible: 20-25 min de trabajo intenso supera a 60 min de cardio tranquilo. Una opción sencilla: 30s sprint / 90s caminata, repite 8-10 veces. 🏃',
    'Si quieres quemar grasa sin sacrificar músculo, haz el cardio DESPUÉS del entreno de fuerza, o en días separados. El orden importa! ⚡',
    'Para quien tiene molestias articulares, la bicicleta o la elíptica son perfectas. Bajo impacto, mucha quema calórica. Una opción muy inteligente! 🚴',
  ];

  // ── Off-topic ─────────────────────────────────────────────────────────────
  static const List<String> _offTopicResponses = [
    'Jaja, me pillas! Eso está un poco fuera de mi especialidad. Yo soy un crack en entrenamiento, nutrición y fitness... pero para eso mejor Google 😄 Si tienes alguna duda sobre tu rutina o dieta, estoy aquí!',
    'Uy, eso no es exactamente mi campo. Soy entrenador, no oráculo 😅 Pero si me preguntas sobre ejercicios, series, descanso o nutrición deportiva, ahí sí que no te fallo!',
    'Hmm, eso se sale un poco de mis competencias como entrenador virtual. No querría darte info equivocada. Lo mío es el fitness! Pregúntame sobre entrenos, dieta o cualquier duda de gym. 💪',
    'Esa pregunta no es de mi territorio, la verdad 😊 Mi especialización es el entrenamiento y la nutrición deportiva. Si tienes algo relacionado con el fitness, estoy a tu disposición!',
  ];

  // ── Defecto ───────────────────────────────────────────────────────────────
  static const List<String> _defaultResponses = [
    'Buena pregunta! En general, la consistencia es lo que más marca la diferencia en el fitness. Sé constante, aunque sea poco a poco, y los resultados llegarán. 💪',
    'Sin más contexto es difícil darte una respuesta precisa, pero lo que siempre vale: paciencia, constancia y escuchar al cuerpo. Puedes darme más detalles?',
    'Cada persona es un mundo en el fitness. Lo que funciona para uno puede no funcionar para otro. Cuéntame más sobre tu objetivo y te doy un consejo más personalizado!',
  ];

  /// Genera una respuesta basada en palabras clave del mensaje del usuario
  // ── Fallback local (palabras clave) ──────────────────────────────────────
  static String _localResponse(String userMessage) {
    final msg = userMessage.toLowerCase();

    if (_containsAny(msg, ['hola', 'hey', 'buenos', 'buenas', 'hi', 'hello', 'saludos', 'ey', 'que tal'])) {
      return _randomFrom(_greetings);
    }
    if (_containsAny(msg, ['motiva', 'animo', 'cansado', 'rendirme', 'dificil', 'no puedo', 'frustrado', 'desanimado', 'tirarlo'])) {
      return _randomFrom(_motivation);
    }
    if (_containsAny(msg, ['descanso', 'dormir', 'sueno', 'fatiga', 'recuperacion', 'sobreentrenamiento', 'lesion'])) {
      return _randomFrom(_restAdvice);
    }
    if (_containsAny(msg, ['suplemento', 'creatina', 'vitamina', 'bcaa', 'cafeina', 'pre-entreno', 'preworkout', 'batido'])) {
      return _randomFrom(_supplementAdvice);
    }
    if (_containsAny(msg, ['dieta', 'comer', 'comida', 'nutricion', 'proteina', 'calorias', 'carbohidrato', 'agua', 'hidratacion', 'desayuno', 'cena', 'macros'])) {
      return _randomFrom(_dietAdvice);
    }
    if (_containsAny(msg, ['hombro', 'deltoid', 'press militar', 'elevacion lateral', 'deltoides', 'face pull'])) {
      return _randomFrom(_shoulderAdvice);
    }
    if (_containsAny(msg, ['gluteo', 'hip thrust', 'sumo', 'abductor'])) {
      return _randomFrom(_gluteAdvice);
    }
    if (_containsAny(msg, ['pierna', 'cuadricep', 'isquio', 'femoral', 'sentadilla', 'squat', 'gemelo', 'pantorrilla'])) {
      return _randomFrom(_legAdvice);
    }
    if (_containsAny(msg, ['pecho', 'chest', 'press banca', 'press plano', 'apertura', 'fondos', 'inclinado'])) {
      return _randomFrom(_chestAdvice);
    }
    if (_containsAny(msg, ['espalda', 'dorsal', 'jalon', 'remo', 'dominada', 'trapecio', 'lumbar'])) {
      return _randomFrom(_backAdvice);
    }
    if (_containsAny(msg, ['bicep', 'curl', 'antebrazo'])) {
      return _randomFrom(_bicepAdvice);
    }
    if (_containsAny(msg, ['tricep', 'press frances', 'press cerrado', 'extension de tricep'])) {
      return _randomFrom(_tricepAdvice);
    }
    if (_containsAny(msg, ['abdomen', 'abdominal', 'abs', 'plancha', 'core', 'crunch', 'oblicuo'])) {
      return _randomFrom(_absAdvice);
    }
    if (_containsAny(msg, ['cardio', 'hiit', 'correr', 'running', 'bicicleta', 'eliptica', 'quemar grasa'])) {
      return _randomFrom(_cardioAdvice);
    }
    if (_containsAny(msg, ['entrenar', 'entrenamiento', 'ejercicio', 'rutina', 'gym', 'gimnasio', 'musculo', 'fuerza', 'repeticiones', 'series', 'pesos', 'brazo'])) {
      return _randomFrom(_trainingAdvice);
    }

    // Detectar si el mensaje es claramente off-topic (no tiene palabras clave fitness)
    // Si el mensaje es suficientemente largo y no matchea nada de fitness, es off-topic
    if (msg.split(' ').length > 2) {
      return _randomFrom(_offTopicResponses);
    }

    return _randomFrom(_defaultResponses);
  }

  static bool _containsAny(String message, List<String> keywords) {
    return keywords.any((k) => message.contains(k));
  }

  static String _randomFrom(List<String> list) {
    return list[_random.nextInt(list.length)];
  }
}

/// Modelo de un mensaje de chat
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
