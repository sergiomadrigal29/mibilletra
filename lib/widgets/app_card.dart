import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? elevation;
  final Color? color;
  final Border? border;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevation,
    this.color,
    this.border,
    this.onTap,
    this.width,
    this.height,
  });

  factory AppCard.flat({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadiusGeometry? borderRadius,
    Color? color,
    VoidCallback? onTap,
  }) {
    return AppCard(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      elevation: AppElevation.level0,
      color: color,
      onTap: onTap,
      child: child,
    );
  }

  factory AppCard.elevated({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadiusGeometry? borderRadius,
    Color? color,
    Border? border,
    VoidCallback? onTap,
  }) {
    return AppCard(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      elevation: AppElevation.level1,
      color: color,
      border: border,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
        boxShadow: elevation ?? AppElevation.level1,
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      final radius = borderRadius?.resolve(Directionality.of(context)) ??
          BorderRadius.circular(AppRadius.lg);
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return content;
  }
}
