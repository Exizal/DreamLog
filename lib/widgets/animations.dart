import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Animation Utilities
/// Spring animations with reduced motion support following Apple HIG

/// Check if reduced motion is enabled
bool isReducedMotion(BuildContext? context) {
  if (context == null) return false;
  return MediaQuery.of(context).disableAnimations;
}

/// Spring animation curve - Apple-style spring physics
const Curve springCurve = Curves.easeOutCubic;

/// Spring animation duration
const Duration springDuration = Duration(milliseconds: 400);

/// Quick spring animation duration
const Duration quickSpringDuration = Duration(milliseconds: 250);

/// Fade and slide animation for cards appearing
class FadeSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = springDuration,
    this.offset = const Offset(0, 0.05),
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: springCurve,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: springCurve,
      ),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final context = this.context;
        if (isReducedMotion(context)) {
          _controller.duration = const Duration(milliseconds: 100);
        }
        Future.delayed(widget.delay, () {
          if (mounted) {
            _controller.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Transform instead of SlideTransition to avoid viewport conflicts
    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          // Use a fixed offset multiplier instead of screen height
          return Transform.translate(
            offset: Offset(
              0,
              _slideAnimation.value.dy * 50, // Fixed offset in logical pixels
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Scale animation for button presses
class ScaleAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;

  const ScaleAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.duration = quickSpringDuration,
  });

  @override
  State<ScaleAnimation> createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: springCurve,
      ),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final context = this.context;
        if (isReducedMotion(context)) {
          _controller.duration = const Duration(milliseconds: 50);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}


