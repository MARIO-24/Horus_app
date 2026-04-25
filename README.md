<div align="center">

# 🏛️ HorusAPP

**Tu entrenador personal inteligente — Trabajo de Fin de Grado**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini AI](https://img.shields.io/badge/Gemini_AI-8E75B2?logo=google&logoColor=white)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

</div>

---

## 📱 Descripción

**HorusAPP** es una aplicación móvil de fitness desarrollada con Flutter como Trabajo de Fin de Grado. Combina inteligencia artificial (Google Gemini 2.5 Flash Lite) con Firebase para ofrecer a cada usuario una experiencia de entrenamiento completamente personalizada: rutinas generadas por IA adaptadas a su perfil, un chatbot entrenador personal disponible 24/7 y seguimiento completo del progreso.

---

## ✨ Funcionalidades principales

| Módulo | Descripción |
|--------|-------------|
| 🔐 **Autenticación** | Registro e inicio de sesión con Firebase Auth (email/contraseña) + aceptación de Términos y Condiciones |
| 👤 **Perfil de usuario** | Datos personales, foto de perfil con caché, edición de nombre |
| 🤖 **Chatbot IA** | Coach profesional de élite con Google Gemini: responde sobre cualquier ejercicio, nutrición deportiva, suplementación y composición corporal. Fallback local por palabras clave |
| 🏋️ **Rutinas IA** | Generación personalizada con Gemini: considera edad, peso, altura, IMC, nivel físico, objetivo y equipamiento disponible según ubicación |
| 📊 **Historial de chat** | Conversaciones persistidas por usuario en Firestore |
| 🌗 **Tema claro/oscuro** | Soporte completo de tema dinámico con Material 3 |
| 🗑️ **Gestión de cuenta** | Eliminación de cuenta con borrado completo de datos (Firestore + Storage) |
| 🌍 **Bilingüe ES / EN** | Toda la UI, prompts de IA y sugerencias del chatbot en español e inglés |
| 🔔 **Notificaciones** | Recordatorio diario de entrenamiento configurable (hora personalizable) con toggle en Ajustes |

---

## 🏗️ Arquitectura

El proyecto sigue **Clean Architecture** con separación estricta en capas:

```
lib/
├── core/               # Constantes, tema, utilidades
├── data/
│   ├── datasources/    # Firebase Auth, Firestore, Storage
│   ├── models/         # Modelos de datos (UserModel, etc.)
│   └── repositories/   # Implementaciones de repositorios
├── domain/
│   ├── entities/       # Entidades de negocio (UserEntity, RoutineEntity...)
│   ├── repositories/   # Contratos/interfaces
│   └── usecases/       # Casos de uso
├── presentation/
│   ├── providers/      # Estado con ChangeNotifier (Provider)
│   ├── screens/        # Pantallas (Login, Home, Rutina, Chatbot, Cuenta...)
│   └── widgets/        # Componentes reutilizables
├── routes/             # Navegación con GoRouter
└── services/           # ChatbotService, RoutineGeneratorService (Gemini API)
```

---

## 🤖 Integración con IA

### Chatbot — Horus (Coach de élite)
- Motor principal: **Gemini 2.5 Flash Lite** via REST API
- System prompt de coach profesional con conocimiento en: biomecánica, periodización, RPE/RIR, HIIT/LISS, macros/TDEE, suplementación basada en evidencia, composición corporal, recuperación y psicología del deporte
- Responde sobre **cualquier ejercicio específico** (sentadilla, peso muerto, hip thrust, etc.) con técnica, músculos, errores comunes y progresiones
- Historial de conversación: últimos 6 mensajes como contexto
- Límite de tokens: 600 por respuesta, timeout 20s
- Fallback automático: sistema local de palabras clave si la API no está disponible
- Persistencia: historial guardado en Firestore por `uid` de usuario
- **Bilingüe**: prompts del sistema y sugerencias rápidas en ES 🇪🇸 / EN 🇬🇧

### Generador de rutinas (IA avanzada)
- Motor principal: **Gemini 2.5 Flash Lite** — genera JSON estructurado con ejercicios
- **Perfil biométrico completo**: edad, peso, altura e **IMC calculado automáticamente** (bajo peso / normal / sobrepeso / obesidad)
- **Equipamiento adaptado al lugar de entrenamiento**:
  - 🏋️ **Gimnasio**: barras olímpicas, poleas, máquinas guiadas, rack de sentadillas
  - 🏠 **Casa**: sillas/mesas para fondos y rows, garrafas como peso, objetos domésticos
  - 🌳 **Aire libre con equipamiento**: mancuernas, comba, bandas elásticas
  - 🌿 **Aire libre sin equipamiento**: calistenia pura, entorno urbano (bancos, escaleras)
- Cada ejercicio incluye: nombre, series, repeticiones, descanso y **descripción de ejecución**
- Fallback automático: banco de rutinas pre-diseñadas por objetivo y nivel
- Límite de tokens: 5000, timeout 45s
- **Bilingüe**: rutinas generadas en el idioma seleccionado por el usuario

---

## 🛠️ Stack tecnológico

| Tecnología | Uso |
|-----------|-----|
| **Flutter 3** | Framework principal (Android/iOS) |
| **Dart 3** | Lenguaje de programación |
| **Firebase Auth** | Autenticación de usuarios |
| **Cloud Firestore** | Base de datos en tiempo real |
| **Firebase Storage** | Almacenamiento de fotos de perfil |
| **Google Gemini 2.5 Flash Lite** | Motor de IA para chatbot y rutinas |
| **Provider** | Gestión de estado (ChangeNotifier) |
| **GoRouter** | Navegación declarativa |
| **CachedNetworkImage** | Caché de imágenes en disco |
| **HTTP** | Llamadas REST a la API de Gemini |
| **flutter_local_notifications** | Notificaciones locales programadas (alarma exacta diaria) |
| **permission_handler** | Gestión de permisos en tiempo de ejecución (POST_NOTIFICATIONS) |
| **timezone** | Programación de notificaciones con zona horaria local |

---

## 🚀 Instalación y ejecución

### Requisitos previos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.2.0
- [Dart SDK](https://dart.dev/get-dart) ≥ 3.0.0
- Android Studio o VS Code con extensión Flutter
- Cuenta de Firebase con proyecto configurado
- API Key de Google Gemini

### 1. Clonar el repositorio
```bash
git clone https://github.com/MARIO-24/Horus_app.git
cd Horus_app
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Configurar Firebase
- Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
- Activa: Authentication (email/password), Firestore, Storage
- Descarga `google-services.json` y colócalo en `android/app/`
- Ejecuta `flutterfire configure` para generar `lib/firebase_options.dart`

### 4. Configurar Reglas de Firestore
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /routines/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /chats/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5. Configurar API Key de Gemini
Copia el archivo de ejemplo y añade tu clave:
```bash
cp lib/core/config/secrets.example.dart lib/core/config/secrets.dart
```
Edita `lib/core/config/secrets.dart`:
```dart
class AppSecrets {
  static const geminiApiKey = 'TU_API_KEY_AQUI';
}
```
> ⚠️ `secrets.dart` está en `.gitignore` — nunca se sube al repositorio.  
Obtén tu clave gratuita en [Google AI Studio](https://aistudio.google.com/app/apikey).

### 6. Ejecutar la app
```bash
flutter run
```

---

## 📂 Estructura de Firestore

```
users/{uid}
  ├── name: String
  ├── email: String
  ├── avatarUrl: String?
  ├── weight: double
  ├── height: double
  ├── birthDate: Timestamp
  └── ...

routines/{uid}
  ├── goal: String
  ├── fitnessLevel: String
  ├── daysPerWeek: int
  ├── days: Array<WorkoutDay>
  └── createdAt: Timestamp

chats/{uid}
  └── messages: Array<{text, isUser, timestamp}>
```

---

## 📸 Capturas de pantalla

> *Próximamente*

---

## 📦 Distribución del APK (Android)

### Generar APK de release
```bash
flutter build apk --release
```
El APK se genera en:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Compartir con otros dispositivos Android
1. **Google Drive / WhatsApp / email**: sube o envía el archivo `app-release.apk`
2. El receptor debe activar **"Instalar apps de fuentes desconocidas"** en su dispositivo:
   - Ajustes → Seguridad → Instalar apps desconocidas (varía según fabricante)
3. Abre el APK en el dispositivo → toca **Instalar**

> ⚠️ Los dispositivos receptores necesitan Android 7.0+ para compatibilidad total.

---

## 📋 Historial de cambios (Changelog)

### v1.1.0 — Correcciones y mejoras de UX

| Tipo | Descripción |
|------|-------------|
| fix | **Notificaciones en release**: se usaba `exactAllowWhileIdle` que requiere un permiso especial del sistema en Android 12+ (`SCHEDULE_EXACT_ALARM`) y fallaba silenciosamente. Cambiado a `inexactAllowWhileIdle` (sin permisos adicionales); añadido `try-catch` en el provider para evitar cuelgues del toggle |
| fix | **Teclado tapa pantalla en Login/Registro**: el teclado software ocultaba los campos del formulario. Cambiado a `resizeToAvoidBottomInset: false` + padding dinámico con `MediaQuery.viewInsetsOf(context).bottom` en el `SingleChildScrollView`; añadido `keyboardDismissBehavior: onDrag` para cerrar teclado al desplazar |
| feat | **Persistencia de datos personales en formulario de rutina**: fecha de nacimiento, peso, altura y género se guardan en `SharedPreferences` al generar la rutina y se precargan automáticamente en la siguiente apertura del formulario |

### v1.0.0 — Release inicial

| Hash | Tipo | Descripción |
|------|------|-------------|
| `05e07fb` | fix | `uiLocalNotificationDateInterpretation` + core library desugaring para `flutter_local_notifications` |
| `5272125` | feat | Notificaciones diarias de recordatorio de entrenamiento con toggle y selector de hora en Ajustes |
| `c9bf872` | feat | Mejorar IA de rutinas (IMC, biometría, equipamiento por ubicación) y chatbot (coach élite) |
| `b71d169` | feat | Añadir aceptación de Términos y Condiciones en el registro |
| `bda61da` | fix | Restaurar encoding UTF-8 y centralizar API key en `AppSecrets` (`secrets.dart`) |
| `3c6012a` | fix | Capturar providers antes del primer await en registro (widget unmounted) |
| `9afa2b6` | security | Eliminar API key expuesta de Gemini, usar `String.fromEnvironment` + `.env` |
| `e323364` | docs | README actualizado — bilingüe, distribución APK, DAM |
| `b338bdb` | fix | Legibilidad modo claro/oscuro: iconos colores fijos, chips ejercicios, avatar chatbot opaco |
| `e0aff07` | feat | Chatbot y rutinas bilingües EN/ES con Gemini, l10n pantalla cuenta y splash |
| `f9b6192` | feat | Bandera UK 🇬🇧, locale `en-GB`, sugerencias rápidas del chatbot bilingües |
| `d262a0d` | feat | L10n completa ES/EN, frase motivacional splash, drawer oscuro, proyecto DAM, icono negro |
| `9b09b75` | feat | 7 mejoras UI: l10n, iconos, tema, splash, tamaño logos |
| `c9da3ca` | feat | UI polish: iconos, splash, login, tema, launcher, idioma |
| `d9b8c83` | feat | Tema dorado + iconos personalizados Horus, rama `feature/ui-icons` |
| `3c62745` | feat | Commit inicial — HorusAPP TFG (arquitectura limpia, Firebase, Gemini, GoRouter) |

---

## �👨‍💻 Autor

Rufito -- **Mario Sánchez Rufino** — Trabajo de Fin de Grado  
Grado Superior en Desarrollo de Aplicaciones Multiplataforma (DAM)

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.

Para obtener ayuda para comenzar con el desarrollo en Flutter, consulta la
[documentacón online](https://docs.flutter.dev/), que ofrece tutoriales,
ejemplos, orientación sobre desarrollo móvil y una referencia completa de la API.
