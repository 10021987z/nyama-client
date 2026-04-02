import 'package:intl/intl.dart';

class FcfaFormatter {
  FcfaFormatter._();

  static final _formatter = NumberFormat('#,##0', 'fr_FR');

  /// Formate un montant en FCFA : 2500 → "2 500 FCFA"
  static String format(int amount) {
    return '${_formatter.format(amount).replaceAll(',', '\u202F')} FCFA';
  }

  /// Formate sans le suffixe : 2500 → "2 500"
  static String formatNoSuffix(int amount) {
    return _formatter.format(amount).replaceAll(',', '\u202F');
  }

  /// Formate avec signe + pour les crédits : "+500 FCFA"
  static String formatCredit(int amount) {
    return '+${format(amount)}';
  }

  /// Parse une chaîne FCFA vers int : "2 500 FCFA" → 2500
  static int parse(String fcfaString) {
    final cleaned = fcfaString
        .replaceAll('FCFA', '')
        .replaceAll('\u202F', '')
        .replaceAll(' ', '')
        .trim();
    return int.tryParse(cleaned) ?? 0;
  }
}

/// Extension pour formater directement depuis un int
extension FcfaInt on int {
  String toFcfa() => FcfaFormatter.format(this);
  String toFcfaNoSuffix() => FcfaFormatter.formatNoSuffix(this);
}

/// Extension pour formater depuis un double (prix avec centimes)
extension FcfaDouble on double {
  String toFcfa() => FcfaFormatter.format(round());
}
