import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final Color? positiveColor;
  final Color? negativeColor;
  final Color? neutralColor;
  final bool showCurrency;
  final bool showSign;
  final int decimalDigits;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const AmountText({
    super.key,
    required this.amount,
    this.style,
    this.positiveColor = const Color(0xFF2E7D32),
    this.negativeColor = const Color(0xFFC62828),
    this.neutralColor,
    this.showCurrency = true,
    this.showSign = false,
    this.decimalDigits = 2,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  Color get _color {
    if (neutralColor != null) return neutralColor!;
    if (amount > 0) return positiveColor!;
    if (amount < 0) return negativeColor!;
    return neutralColor ?? const Color(0xFF2E7D32);
  }

  String get _prefix {
    if (!showSign) return '';
    if (amount > 0) return '+';
    if (amount < 0) return '-';
    return '';
  }

  String get _formatted {
    final abs = amount.abs();
    final formatted = NumberFormat('#,##0.${'0' * decimalDigits}').format(abs);
    return '${showCurrency ? 'C\$' : ''}$formatted';
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: _color,
      fontWeight: FontWeight.w600,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: textAlign?.toAlignment() ?? Alignment.centerLeft,
      child: Text(
        '$_prefix$_formatted',
        style: style ?? defaultStyle,
        textAlign: textAlign,
        overflow: overflow ?? TextOverflow.ellipsis,
        maxLines: maxLines ?? 1,
      ),
    );
  }
}

extension on TextAlign {
  AlignmentGeometry toAlignment() {
    return switch (this) {
      TextAlign.center => Alignment.center,
      TextAlign.right => Alignment.centerRight,
      TextAlign.left => Alignment.centerLeft,
      TextAlign.start => Alignment.centerLeft,
      TextAlign.end => Alignment.centerRight,
      TextAlign.justify => Alignment.center,
    };
  }
}
