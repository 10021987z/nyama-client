import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Prix FCFA — Space Mono 700, couleur orange #F57C20.
class PriceTag extends StatelessWidget {
  final num amount;
  final double fontSize;
  final String currency;

  const PriceTag({
    super.key,
    required this.amount,
    this.fontSize = 16,
    this.currency = 'FCFA',
  });

  String _format(num v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_format(amount)} $currency',
      style: TextStyle(
        fontFamily: 'SpaceMono',
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        color: AppColors.primary,
        height: 1.1,
      ),
    );
  }
}
