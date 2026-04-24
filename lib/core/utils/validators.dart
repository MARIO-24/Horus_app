import 'package:horus_app/core/constants/app_constants.dart';

/// Validadores de formulario reutilizables
class Validators {
  Validators._();

  /// Valida el nombre: mínimo 3 caracteres, solo letras y espacios
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.trim().length < AppConstants.minNameLength) {
      return 'El nombre debe tener al menos ${AppConstants.minNameLength} caracteres';
    }
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return 'El nombre solo puede contener letras y espacios';
    }
    return null;
  }

  /// Valida el email con formato estándar
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es obligatorio';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  /// Valida la contraseña: mínimo 8 caracteres, letras + número o símbolo
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Mínimo ${AppConstants.minPasswordLength} caracteres';
    }
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasDigitOrSymbol =
        RegExp(r'[0-9!@#\$%^&*()_+=\-\[\]{};:,.<>?/\\|`~]').hasMatch(value);
    if (!hasLetter || !hasDigitOrSymbol) {
      return 'Debe contener letras y al menos un número o símbolo';
    }
    return null;
  }

  /// Valida que la confirmación coincida con la contraseña
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  /// Valida el peso (30–300 kg)
  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El peso es obligatorio';
    }
    final weight = double.tryParse(value.trim().replaceAll(',', '.'));
    if (weight == null) {
      return 'Ingresa un número válido';
    }
    if (weight < AppConstants.minWeight || weight > AppConstants.maxWeight) {
      return 'El peso debe estar entre ${AppConstants.minWeight.toInt()} y ${AppConstants.maxWeight.toInt()} kg';
    }
    return null;
  }

  /// Valida la altura (120–300 cm)
  static String? validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La altura es obligatoria';
    }
    final height = double.tryParse(value.trim().replaceAll(',', '.'));
    if (height == null) {
      return 'Ingresa un número válido';
    }
    if (height < AppConstants.minHeight || height > AppConstants.maxHeight) {
      return 'La altura debe estar entre ${AppConstants.minHeight.toInt()} y ${AppConstants.maxHeight.toInt()} cm';
    }
    return null;
  }

  /// Valida la fecha de nacimiento (edad entre 16 y 100 años)
  static String? validateBirthDate(DateTime? value) {
    if (value == null) {
      return 'La fecha de nacimiento es obligatoria';
    }
    final now = DateTime.now();
    final age = now.year -
        value.year -
        ((now.month < value.month ||
                (now.month == value.month && now.day < value.day))
            ? 1
            : 0);
    if (age < AppConstants.minAge) {
      return 'Debes tener al menos ${AppConstants.minAge} años';
    }
    if (age > AppConstants.maxAge) {
      return 'La edad no puede superar ${AppConstants.maxAge} años';
    }
    return null;
  }
}
