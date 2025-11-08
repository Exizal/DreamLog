import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

/// Animated dialog wrapper with scale and fade animations
class AnimatedDialog extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final EdgeInsets? padding;
  final double borderRadius;

  const AnimatedDialog({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOutBack,
    this.padding,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: padding ?? AppTheme.responsiveHorizontalPadding(context),
      child: TweenAnimationBuilder<double>(
        duration: duration,
        curve: curve,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          // Clamp value to ensure it's between 0.0 and 1.0
          final clampedValue = value.clamp(0.0, 1.0);
          return Transform.scale(
            scale: 0.9 + (clampedValue * 0.1), // Scale from 0.9 to 1.0
            child: Opacity(
              opacity: clampedValue,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassContainer(borderRadius: borderRadius),
                    child: this.child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Show animated dialog helper
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    Duration? duration,
    Curve? curve,
    EdgeInsets? padding,
    double? borderRadius,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.7),
      builder: (context) => AnimatedDialog(
        duration: duration ?? const Duration(milliseconds: 250),
        curve: curve ?? Curves.easeOutBack,
        padding: padding,
        borderRadius: borderRadius ?? 24,
        child: child,
      ),
    );
  }
}

