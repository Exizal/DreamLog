import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated loading indicator with fade-in and optional skeleton
class AnimatedLoadingIndicator extends StatefulWidget {
  final bool showSkeleton;
  final Widget? customIndicator;
  final Duration fadeDuration;

  const AnimatedLoadingIndicator({
    super.key,
    this.showSkeleton = false,
    this.customIndicator,
    this.fadeDuration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedLoadingIndicator> createState() =>
      _AnimatedLoadingIndicatorState();
}

class _AnimatedLoadingIndicatorState extends State<AnimatedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      duration: widget.fadeDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Shimmer animation for skeleton
    if (widget.showSkeleton) {
      _shimmerController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );
      _shimmerAnimation = CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.linear,
      );
      _shimmerController.repeat();
    }

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    if (widget.showSkeleton) {
      _shimmerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showSkeleton) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: _buildSkeleton(),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.customIndicator ??
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary),
            strokeWidth: 3,
          ),
    );
  }

  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _shimmerAnimation.value * 2, 0),
              end: Alignment(1.0 + _shimmerAnimation.value * 2, 0),
              colors: [
                AppTheme.glassOverlay,
                AppTheme.glassOverlay.withOpacity(0.3),
                AppTheme.glassOverlay,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loading widget for list items
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedLoadingIndicator(
      showSkeleton: true,
      customIndicator: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: AppTheme.glassOverlay,
        ),
      ),
    );
  }
}

