import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double full = 9999;
}

class AppElevation {
  static const List<BoxShadow> level0 = [];

  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

class AppIconSize {
  static const double xs = 14;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double display = 48;
}

class AppAnimation {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeOutCubic;
}

class AppBorder {
  static const BorderSide thin = BorderSide(
    color: AppTheme.outlineVariant,
    width: 1,
  );
  static const BorderSide medium = BorderSide(
    color: AppTheme.outline,
    width: 1.5,
  );
  static const BorderSide thick = BorderSide(
    color: AppTheme.outline,
    width: 2,
  );
}

extension ResponsiveExt on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isCompactWidth => screenWidth < 360;
  bool get isTablet => screenWidth >= 600;
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;

  double responsive(double mobile, {double? tablet, double? desktop}) {
    if (isTablet) return tablet ?? mobile * 1.2;
    return mobile;
  }

  EdgeInsets responsivePadding({
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    if (isTablet) return tablet ?? mobile ?? EdgeInsets.zero;
    return mobile ?? EdgeInsets.zero;
  }
}

class AppSemantics {
  static const String loading = 'Cargando...';
  static const String error = 'Error al cargar';
  static const String empty = 'No hay datos';
  static const String retry = 'Reintentar';
  static const String close = 'Cerrar';
  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String delete = 'Eliminar';
  static const String edit = 'Editar';
}