import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';

/// Custom animated switch with smooth transitions and spring physics
class AnimatedSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final Duration duration;
  final bool enabled;

  const AnimatedSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.duration = const Duration(milliseconds: 200),
    this.enabled = true,
  });

  @override
  State<AnimatedSwitch> createState() => _AnimatedSwitchState();
}

class _AnimatedSwitchState extends State<AnimatedSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thumbAnimation;
  late Animation<Color?> _trackColorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Thumb position animation with spring curve
    _thumbAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Track color animation
    _trackColorAnimation = ColorTween(
      begin: widget.inactiveColor ?? AppTheme.cosmicGray.withOpacity(0.3),
      end: widget.activeColor ?? AppTheme.accentPrimary,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Set initial state
    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) {
      debugPrint('AnimatedSwitch: Widget is disabled');
      return;
    }
    
    if (widget.onChanged == null) {
      debugPrint('AnimatedSwitch: onChanged callback is null');
      return;
    }

    debugPrint('AnimatedSwitch: Tapped, current value: ${widget.value}, new value: ${!widget.value}');
    HapticFeedback.selectionClick();
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final trackWidth = 50.0;
    final trackHeight = 30.0;
    final thumbSize = 24.0;
    final thumbPadding = 3.0;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final thumbPosition = _thumbAnimation.value;
          final trackColor = _trackColorAnimation.value ?? Colors.transparent;
          final scale = widget.enabled ? 1.0 : 0.95;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: trackWidth,
              height: trackHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(trackHeight / 2),
                color: trackColor,
                boxShadow: [
                  BoxShadow(
                    color: trackColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Thumb
                  AnimatedPositioned(
                    duration: widget.duration,
                    curve: Curves.easeInOut,
                    left: thumbPadding +
                        (thumbPosition * (trackWidth - thumbSize - thumbPadding * 2)),
                    top: thumbPadding,
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.starLight,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

