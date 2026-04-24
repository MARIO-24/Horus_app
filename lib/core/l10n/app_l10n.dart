import 'package:flutter/material.dart';
import 'package:horus_app/presentation/providers/locale_provider.dart';
import 'package:provider/provider.dart';

/// Localizaciones completas de la aplicación HorusAPP (ES / EN).
/// Uso: `final l10n = AppL10n.of(context);` dentro de un método build.
class AppL10n {
  final bool _en;
  const AppL10n._(this._en);

  static AppL10n of(BuildContext context) =>
      AppL10n._(context.watch<LocaleProvider>().locale.languageCode == 'en');

  /// Variante para usar fuera de build (callbacks, async methods).
  /// No registra dependencia de reconstrucción.
  static AppL10n readFrom(BuildContext context) =>
      AppL10n._(context.read<LocaleProvider>().locale.languageCode == 'en');

  /// Expone el flag de idioma (true = inglés) para pasarlo a servicios.
  bool get isEnglish => _en;

  // ── Drawer / Navegación ───────────────────────────────────────────────────
  String get navRoutine     => _en ? 'Routine'       : 'Rutina';
  String get navAccount     => _en ? 'Account'       : 'Cuenta';
  String get navChatBot     => 'ChatBot';
  String get navSettings    => _en ? 'Settings'      : 'Opciones';
  String get defaultUser    => _en ? 'User'          : 'Usuario';
  String get changePhoto    => _en ? 'Change photo'  : 'Cambiar foto';
  String get deletePhoto    => _en ? 'Delete photo'  : 'Eliminar foto';
  String get cancel         => _en ? 'Cancel'        : 'Cancelar';

  // ── Home screen ───────────────────────────────────────────────────────────
  String get appTitle           => 'HorusAPP';
  String get newRoutineTooltip  => _en ? 'New routine'               : 'Nueva rutina';
  String greeting(String name)  => _en ? 'Hello, $name! 👋'          : '¡Hola, $name! 👋';
  String greetingReady(String name) => _en ? 'Hello, $name! 💪'      : '¡Hola, $name! 💪';
  String get noRoutineBody      => _en
      ? 'You don\'t have a personalised routine yet.\nLet\'s create one made just for you.'
      : 'Aún no tienes una rutina personalizada.\nVamos a crear una hecha justo para ti.';
  String get generateRoutine    => _en ? 'Generate my routine'       : 'Generar mi rutina';
  String get talkWithBot        => _en ? 'Talk with the bot'         : 'Hablar con el bot';
  String get routineReady       => _en ? 'Your routine is ready'     : 'Tu rutina está lista';
  String get goalLabel          => _en ? 'Goal'                      : 'Objetivo';
  String get levelLabel         => _en ? 'Level'                     : 'Nivel';
  String get daysWeekLabel      => _en ? 'Days/week'                 : 'Días/semana';
  String get viewFullRoutine    => _en ? 'View full routine'         : 'Ver rutina completa';
  String get generateNewRoutine => _en ? 'Generate new routine'      : 'Generar nueva rutina';
  String get trainingDays       => _en ? 'Training days'             : 'Días de entrenamiento';
  String exercisesCount(int n)  => _en ? '$n exercises'              : '$n ejercicios';

  // ── Login ─────────────────────────────────────────────────────────────────
  String get loginTitle         => _en ? 'Sign In'                   : 'Iniciar Sesión';
  String get emailLabel         => 'Email';
  String get emailHint          => _en ? 'your@email.com'            : 'tu@email.com';
  String get passwordLabel      => _en ? 'Password'                  : 'Contraseña';
  String get forgotPassword     => _en ? 'Forgot your password?'     : '¿Olvidaste tu contraseña?';
  String get keepSession        => _en ? 'Keep session active'       : 'Mantener sesión iniciada';
  String get loginButton        => _en ? 'Sign In'                   : 'Entrar';
  String get noAccount          => _en ? 'Don\'t have an account?'   : '¿No tienes cuenta?';
  String get registerLink       => _en ? 'Sign up'                   : 'Regístrate';
  String get resetPasswordTitle => _en ? 'Reset password'            : 'Restablecer contraseña';
  String get resetPasswordBody  => _en
      ? 'Enter your email and we\'ll send you a link to reset your password.'
      : 'Introduce tu email y te enviaremos un enlace para restablecer tu contraseña.';
  String get sendLink           => _en ? 'Send link'                 : 'Enviar enlace';
  String resetLinkSent(String email) => _en
      ? 'Link sent to $email. Check your inbox.'
      : 'Enlace enviado a $email. Revisa tu bandeja de entrada.';

  // ── Validators / errores de formulario ───────────────────────────────────
  String get fieldRequired      => _en ? 'This field is required'    : 'Este campo es obligatorio';
  String get emailRequired      => _en ? 'Email is required'         : 'El email es obligatorio';
  String get emailInvalid       => _en ? 'Invalid email'             : 'Email no válido';
  String get passwordRequired   => _en ? 'Password is required'      : 'La contraseña es obligatoria';
  String get loginError         => _en ? 'Error signing in'          : 'Error al iniciar sesión';

  // ── Register ──────────────────────────────────────────────────────────────
  String get registerTitle      => _en ? 'Create account'            : 'Crear cuenta';
  String get joinTitle          => _en ? 'Join HorusAPP'             : 'Únete a HorusAPP';
  String get joinSubtitle       => _en
      ? 'Fill in the details to create your account'
      : 'Completa los datos para crear tu cuenta';
  String get nameLabel          => _en ? 'Name'                      : 'Nombre';
  String get nameHint           => _en ? 'Your name'                 : 'Tu nombre';
  String get confirmPassword    => _en ? 'Confirm password'          : 'Confirmar contraseña';
  String get registerButton     => _en ? 'Create account'            : 'Crear cuenta';
  String get alreadyAccount     => _en ? 'Already have an account?'  : '¿Ya tienes cuenta?';
  String get loginLink          => _en ? 'Sign in'                   : 'Inicia sesión';
  String get registerError      => _en ? 'Error creating account'    : 'Error al registrarse';
  String get termsAccept        => _en ? 'I accept the '             : 'Acepto los ';
  String get termsLink          => _en ? 'Terms and Conditions'      : 'Términos y Condiciones';
  String get termsRequired      => _en
      ? 'You must accept the Terms and Conditions to register'
      : 'Debes aceptar los Términos y Condiciones para registrarte';
  String get termsTitle         => _en ? 'Terms and Conditions'      : 'Términos y Condiciones';
  String get termsContent       => _en
      ? '''Welcome to HorusAPP.

By creating an account you agree to the following terms:

1. USE OF THE APP
HorusAPP is an AI-powered fitness app for educational and personal use. The routines and advice generated do not replace professional medical or sports guidance.

2. PERSONAL DATA
We collect your name, email, and training data to personalise your experience. Data is stored securely in Firebase and is never shared with third parties.

3. HEALTH RESPONSIBILITY
Consult a health professional before starting any training programme. HorusAPP is not responsible for injuries resulting from improper use of the routines.

4. ACCOUNT
You are responsible for keeping your credentials confidential. Notify us immediately of any unauthorised use.

5. MODIFICATIONS
We may update these terms at any time. Continued use of the app implies acceptance of the updated terms.

Thank you for trusting HorusAPP. Train smart, train safe.'''
      : '''Bienvenido a HorusAPP.

Al crear una cuenta aceptas los siguientes términos:

1. USO DE LA APLICACIÓN
HorusAPP es una app de fitness asistida por IA de uso educativo y personal. Las rutinas y consejos generados no sustituyen la orientación médica o deportiva profesional.

2. DATOS PERSONALES
Recogemos tu nombre, email y datos de entrenamiento para personalizar tu experiencia. Los datos se almacenan de forma segura en Firebase y nunca se comparten con terceros.

3. RESPONSABILIDAD DE SALUD
Consulta a un profesional de la salud antes de comenzar cualquier programa de entrenamiento. HorusAPP no se hace responsable de lesiones derivadas del uso inadecuado de las rutinas.

4. CUENTA
Eres responsable de mantener tus credenciales confidenciales. Notifícanos de inmediato cualquier uso no autorizado.

5. MODIFICACIONES
Podemos actualizar estos términos en cualquier momento. El uso continuado de la app implica la aceptación de los términos actualizados.

Gracias por confiar en HorusAPP. Entrena inteligente, entrena seguro.''';
  String get termsClose         => _en ? 'Close'                     : 'Cerrar';

  // ── Routine form ──────────────────────────────────────────────────────────
  String get routineFormTitle   => _en ? 'Generate Routine'          : 'Generar Rutina';
  String get routineFormSubtitle => _en
      ? 'Fill in your profile and we\'ll generate a personalised AI routine'
      : 'Completa tu perfil y generaremos una rutina personalizada con IA';
  String get personalData       => _en ? 'Personal data'             : 'Datos personales';
  String get birthDate          => _en ? 'Date of birth'             : 'Fecha de nacimiento';
  String get birthDateHint      => _en ? 'Select your date'          : 'Selecciona tu fecha';
  String get weightLabel        => _en ? 'Weight (kg)'               : 'Peso (kg)';
  String get weightHint         => _en ? 'e.g. 75'                   : 'Ej: 75';
  String get heightLabel        => _en ? 'Height (cm)'               : 'Altura (cm)';
  String get heightHint         => _en ? 'e.g. 175'                  : 'Ej: 175';
  String get genderLabel        => _en ? 'Gender'                    : 'Género';
  String get fitnessLevelLabel  => _en ? 'Fitness level'             : 'Nivel físico';
  String get goalLabel2         => _en ? 'Training goal'             : 'Objetivo de entrenamiento';
  String daysPerWeekLabel(int d) => _en
      ? 'Training days per week: $d'
      : 'Días de entrenamiento por semana: $d';
  String get trainingLocationLabel => _en ? 'Where do you train?'    : '¿Dónde entrenas?';
  String get generatingLabel    => _en ? 'Generating...'             : 'Generando...';
  String get routineSuccess     => _en ? 'Routine generated! 💪'     : '¡Rutina generada con éxito! 💪';
  String get routineError       => _en ? 'Error generating routine'  : 'Error al generar la rutina';

  // ── Opciones formulario ───────────────────────────────────────────────────
  List<String> get genderOptions => _en
      ? ['Male', 'Female', 'Other']
      : ['Masculino', 'Femenino', 'Otro'];
  List<String> get fitnessOptions => _en
      ? ['Beginner', 'Intermediate', 'Advanced']
      : ['Principiante', 'Intermedio', 'Avanzado'];
  List<String> get goalOptions => _en
      ? ['Lose weight', 'Build muscle', 'Endurance', 'Rehabilitation']
      : ['Bajar peso', 'Ganar músculo', 'Resistencia', 'Rehabilitación'];
  List<String> get locationOptions => _en
      ? ['Gym', 'Home', 'Outdoors with equipment', 'Outdoors without equipment']
      : ['Gimnasio', 'Casa', 'Aire libre con equipamiento', 'Aire libre sin equipamiento'];

  // ── Routine screen ────────────────────────────────────────────────────────
  String get routine            => _en ? 'My Routine'                : 'Mi Rutina';
  String get noRoutineYet       => _en ? 'You don\'t have a routine yet' : 'No tienes ninguna rutina aún';
  String get createRoutine      => _en ? 'Create routine'            : 'Crear rutina';

  // ── Account screen ────────────────────────────────────────────────────────
  String get account            => _en ? 'My Account'                : 'Mi Cuenta';
  String get athlete            => _en ? 'Athlete'                   : 'Atleta';
  String get editProfile        => _en ? 'Edit profile'              : 'Editar perfil';
  String get saveChanges        => _en ? 'Save changes'              : 'Guardar cambios';
  String get editName           => _en ? 'Edit name'                 : 'Editar nombre';
  String get save               => _en ? 'Save'                      : 'Guardar';
  String get nameUpdated        => _en ? 'Name updated'              : 'Nombre actualizado';
  String get nameUpdateError    => _en ? 'Error saving name'         : 'Error al guardar el nombre';
  String get activeRoutine      => _en ? 'Active routine'            : 'Rutina activa';
  String get weight             => _en ? 'Weight'                    : 'Peso';
  String get height             => _en ? 'Height'                    : 'Altura';
  String get whereYouTrain      => _en ? 'Training location'         : 'Dónde entrenas';
  String get actions            => _en ? 'Actions'                   : 'Acciones';
  String memberSince(String date) => _en ? 'Member since $date'      : 'Miembro desde $date';

  // ── ChatBot ───────────────────────────────────────────────────────────────
  String get virtualTrainer     => _en ? 'Virtual trainer'           : 'Entrenador virtual';
  String get typing             => _en ? 'Typing...'                 : 'Escribiendo...';
  String get clearChat          => _en ? 'Clear chat'                : 'Limpiar chat';
  String get clearChatTitle     => _en ? 'Clear chat'                : 'Limpiar chat';
  String get clearChatBody      => _en
      ? 'Are you sure you want to delete all messages?'
      : '¿Seguro que quieres eliminar todos los mensajes?';
  String get clearChatConfirm   => _en ? 'Delete'                    : 'Limpiar';
  String get messagePlaceholder => _en ? 'Write a message...'        : 'Escribe un mensaje...';
  String get sendTooltip        => _en ? 'Send'                      : 'Enviar';

  // ── Settings / Opciones ───────────────────────────────────────────────────
  String get settings           => _en ? 'Settings'                  : 'Opciones';
  String get appearance         => _en ? 'Appearance'                : 'Apariencia';
  String get themeLight         => _en ? 'Light'                     : 'Claro';
  String get themeDark          => _en ? 'Dark'                      : 'Oscuro';
  String get themeSystem        => _en ? 'System (default)'          : 'Sistema (por defecto)';
  String get language           => _en ? 'Language'                  : 'Idioma';
  String get spanish            => _en ? 'Spanish'                   : 'Español';
  String get english            => 'English';
  String get routineSection     => _en ? 'Routine'                   : 'Rutina';
  String get deleteRoutine      => _en ? 'Delete current routine'    : 'Eliminar rutina actual';
  String get deleteRoutineSubtitle => _en
      ? 'You can generate a new routine anytime'
      : 'Podrás generar una nueva rutina cuando quieras';
  String get deleteRoutineTitle => _en ? 'Delete routine'            : 'Eliminar rutina';
  String get deleteRoutineBody  => _en
      ? 'Are you sure you want to delete your current routine? You can create a new one anytime.'
      : '¿Seguro que quieres eliminar tu rutina actual? Podrás crear una nueva cuando quieras.';
  String get noActiveRoutine    => _en ? 'No active routine'         : 'No tienes ninguna rutina activa';
  String get routineDeleted     => _en ? 'Routine deleted'           : 'Rutina eliminada';
  String get accountSection     => _en ? 'Account'                   : 'Cuenta';
  String get logout             => _en ? 'Log out'                   : 'Cerrar sesión';
  String get logoutTitle        => _en ? 'Log out'                   : 'Cerrar sesión';
  String get logoutBody         => _en ? 'Are you sure you want to log out?' : '¿Seguro que quieres cerrar sesión?';
  String get logoutConfirm      => _en ? 'Log out'                   : 'Cerrar sesión';
  String get deleteAccount      => _en ? 'Delete account'            : 'Eliminar cuenta';
  String get deleteAccountSubtitle => _en
      ? 'This action is permanent and irreversible'
      : 'Esta acción es permanente e irreversible';
  String get deleteAccountTitle => _en ? 'Delete account'            : 'Eliminar cuenta';
  String get deleteAccountWarning => _en
      ? '⚠️ This action is permanent. Your account and all data will be deleted.'
      : '⚠️ Esta acción es permanente. Se eliminarán tu cuenta y todos tus datos.';
  String get enterPasswordConfirm => _en
      ? 'Enter your password to confirm:'
      : 'Introduce tu contraseña para confirmar:';
  String get passwordHint       => _en ? 'Password'                  : 'Contraseña';
  String get deleteConfirm      => _en ? 'Delete'                    : 'Eliminar';
  String get wrongPassword      => _en ? 'Incorrect password'        : 'Contraseña incorrecta';
  String deleteAccountError(String msg) => _en
      ? 'Error deleting account: $msg'
      : 'Error al eliminar la cuenta: $msg';
  String unexpectedError(String e) => _en
      ? 'Unexpected error: $e'
      : 'Error inesperado: $e';

  // ── Acerca de ─────────────────────────────────────────────────────────────
  String get about              => _en ? 'About'                     : 'Acerca de';
  String get appNameLabel       => _en ? 'Application'               : 'Aplicación';
  String get developer          => _en ? 'Developer'                 : 'Desarrollador';
  String get project            => _en ? 'Project'                   : 'Proyecto';
  String get technologies       => _en ? 'Technologies'              : 'Tecnologías';
  String get architecture       => _en ? 'Architecture'              : 'Arquitectura';
  String get sourceCode         => _en ? 'Source code'               : 'Código fuente';

  // ── Sugerencias rápidas del chatbot ──────────────────────────────────────
  List<String> get quickSuggestions => _en
      ? [
          'What should I eat before training?',
          'Give me motivation 💪',
          'How long to rest between sets?',
          'Tips to lose fat',
          'What is creatine used for?',
          'Abdominal exercises',
        ]
      : [
          '¿Qué debo comer antes de entrenar?',
          'Dame motivación 💪',
          '¿Cuánto descanso entre series?',
          'Consejos para perder grasa',
          '¿Para qué sirve la creatina?',
          'Ejercicio para abdominales',
        ];

  // ── Frases motivadoras bilingues ──────────────────────────────────────────
  List<String> get motivationalPhrases => _en
      ? [
          'Today\'s pain is tomorrow\'s strength.',
          'Your only limit is yourself.',
          'The body achieves what the mind believes.',
          'Don\'t give up, the beginning is always hard.',
          'One day at a time, one rep at a time.',
          'Sweat now, shine later.',
          'Discipline is the bridge between goals and achievements.',
          'Make your future self proud.',
          'Success is the sum of small efforts repeated every day.',
          'Don\'t seek perfection, seek progress.',
          'Champions don\'t quit when they\'re tired; they quit when they\'ve won.',
          'Every workout brings you one step closer to your best self.',
        ]
      : [
          'El dolor de hoy es la fuerza de mañana.',
          'Tu único límite eres tú mismo.',
          'El cuerpo logra lo que la mente cree.',
          'No te rindas, el principio siempre es duro.',
          'Un día a la vez, una rep a la vez.',
          'Suda ahora, brilla después.',
          'La disciplina es el puente entre las metas y los logros.',
          'Haz que tu yo del futuro esté orgulloso.',
          'El éxito es la suma de pequeños esfuerzos repetidos cada día.',
          'No busques la perfección, busca el progreso.',
          'Los campeones no se rinden cuando están cansados; se rinden cuando han ganado.',
          'Cada entrenamiento te acerca un paso más a tu mejor versión.',
        ];
}
