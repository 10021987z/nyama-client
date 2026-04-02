class Validators {
  Validators._();

  /// Valide un numéro de téléphone camerounais
  /// Formats acceptés : 6XXXXXXXX, +2376XXXXXXXX, 00237 6XXXXXXXX
  static String? validateCameroonPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Formats valides :
    // 6XXXXXXXX (9 chiffres, commence par 6)
    // +2376XXXXXXXX ou 002376XXXXXXXX
    final localRegex = RegExp(r'^6[5-9]\d{7}$');
    final intlRegex = RegExp(r'^(?:\+237|00237)6[5-9]\d{7}$');

    if (!localRegex.hasMatch(cleaned) && !intlRegex.hasMatch(cleaned)) {
      return 'Numéro invalide (ex: 6XX XXX XXX)';
    }

    return null;
  }

  /// Normalise un numéro camerounais vers le format international
  /// "699000000" → "+237699000000"
  static String normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+237')) return cleaned;
    if (cleaned.startsWith('00237')) return '+${cleaned.substring(2)}';
    if (cleaned.startsWith('6')) return '+237$cleaned';
    return cleaned;
  }

  /// Valide le code OTP (4 à 6 chiffres)
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le code OTP est requis';
    }
    if (!RegExp(r'^\d{4,6}$').hasMatch(value)) {
      return 'Code invalide';
    }
    return null;
  }

  /// Valide un nom (non vide, 2 à 50 caractères)
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    }
    if (value.trim().length < 2) {
      return 'Minimum 2 caractères';
    }
    if (value.trim().length > 50) {
      return 'Maximum 50 caractères';
    }
    return null;
  }

  /// Vérifie si un opérateur mobile money est Orange Money
  static bool isOrangeMoney(String phone) {
    final normalized = normalizePhone(phone);
    // Orange Cameroun : 655, 656, 657, 658, 659, 693, 694, 695, 696, 697, 698, 699
    final orangePrefixes = ['655', '656', '657', '658', '659', '693', '694', '695', '696', '697', '698', '699'];
    final local = normalized.replaceFirst('+237', '');
    return orangePrefixes.any((p) => local.startsWith(p));
  }

  /// Vérifie si un opérateur mobile money est MTN MoMo
  static bool isMtnMomo(String phone) {
    final normalized = normalizePhone(phone);
    // MTN Cameroun : 650-654, 670-689
    final local = normalized.replaceFirst('+237', '');
    final prefix3 = local.length >= 3 ? int.tryParse(local.substring(0, 3)) ?? 0 : 0;
    return (prefix3 >= 650 && prefix3 <= 654) || (prefix3 >= 670 && prefix3 <= 689);
  }
}
