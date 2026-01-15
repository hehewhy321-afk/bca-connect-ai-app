import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.gradient,
    this.color,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        color: color ?? (gradient == null ? Theme.of(context).cardColor : null),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: elevation != null
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: elevation!,
                  offset: Offset(0, elevation! / 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

    return widget.animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}
