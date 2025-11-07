import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../theme/app_theme.dart';

/// Analog Clock Face - Redesigned modern clock for time picker with smooth animations
class AnalogClock extends StatefulWidget {
  final int hour;
  final int minute;
  final bool is24Hour;
  final ValueChanged<int>? onHourChanged;
  final ValueChanged<int>? onMinuteChanged;
  final double size;

  const AnalogClock({
    super.key,
    required this.hour,
    required this.minute,
    this.is24Hour = false,
    this.onHourChanged,
    this.onMinuteChanged,
    this.size = 300,
  });

  @override
  State<AnalogClock> createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  bool _isDraggingHour = false;
  late AnimationController _handAnimationController;
  late Animation<double> _handAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _handAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _handAnimation = CurvedAnimation(
      parent: _handAnimationController,
      curve: Curves.easeOutCubic,
    );
    
    _handAnimationController.forward();
  }
  
  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hour != widget.hour || oldWidget.minute != widget.minute) {
      _handAnimationController.reset();
      _handAnimationController.forward();
    }
  }
  
  @override
  void dispose() {
    _handAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Convert to 12-hour format for display
    final displayHour = widget.is24Hour ? (widget.hour % 12 == 0 ? 12 : widget.hour % 12) : (widget.hour % 12 == 0 ? 12 : widget.hour % 12);
    final isPM = widget.hour >= 12;

    // Calculate angles
    final hourAngle = (displayHour * 30 + widget.minute * 0.5 - 90) * math.pi / 180;
    final minuteAngle = (widget.minute * 6 - 90) * math.pi / 180;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Solid background - no glass effect
        color: AppTheme.backgroundTertiary,
        border: Border.all(
          color: AppTheme.glassBorder.withOpacity(0.3),
          width: 2.0,
        ),
        boxShadow: [
          // Outer shadow - depth
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
          // Soft glow
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _handAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // Clock face
              CustomPaint(
                painter: ClockPainter(
                  hour: displayHour,
                  minute: widget.minute,
                  hourAngle: hourAngle,
                  minuteAngle: minuteAngle,
                  animationValue: _handAnimation.value,
                ),
              ),
              // Drag gesture detector
              GestureDetector(
                onPanStart: (details) {
                  final localPosition = details.localPosition;
                  final center = Offset(widget.size / 2, widget.size / 2);
                  final offset = localPosition - center;
                  final distance = math.sqrt(offset.dx * offset.dx + offset.dy * offset.dy);
                  final radius = widget.size / 2;

                  _isDragging = true;
                  _isDraggingHour = distance < radius * 0.65;
                },
                onPanUpdate: (details) {
                  if (!_isDragging) return;

                  final localPosition = details.localPosition;
                  final center = Offset(widget.size / 2, widget.size / 2);
                  final offset = localPosition - center;
                  final distance = math.sqrt(offset.dx * offset.dx + offset.dy * offset.dy);
                  final radius = widget.size / 2;

                  if (_isDraggingHour && distance < radius * 0.65) {
                    // Hour dragging
                    final angle = math.atan2(offset.dy, offset.dx) * 180 / math.pi;
                    var newHour = ((angle + 90) / 30).round() % 12;
                    if (newHour <= 0) newHour = 12;
                    if (widget.onHourChanged != null) {
                      widget.onHourChanged!(widget.is24Hour ? (isPM && newHour != 12 ? newHour + 12 : (newHour == 12 && !isPM ? 0 : newHour)) : newHour);
                    }
                  } else if (!_isDraggingHour && distance < radius * 0.9) {
                    // Minute dragging
                    final angle = math.atan2(offset.dy, offset.dx) * 180 / math.pi;
                    var newMinute = ((angle + 90) / 6).round() % 60;
                    if (newMinute < 0) newMinute += 60;
                    if (widget.onMinuteChanged != null) {
                      widget.onMinuteChanged!(newMinute);
                    }
                  }
                },
                onPanEnd: (details) {
                  _isDragging = false;
                  _isDraggingHour = false;
                  HapticFeedback.selectionClick();
                },
                onTapDown: (details) {
                  final localPosition = details.localPosition;
                  final center = Offset(widget.size / 2, widget.size / 2);
                  final offset = localPosition - center;
                  final distance = math.sqrt(offset.dx * offset.dx + offset.dy * offset.dy);
                  final radius = widget.size / 2;

                  if (distance < radius * 0.65) {
                    // Inner circle - hour selection
                    final angle = math.atan2(offset.dy, offset.dx) * 180 / math.pi;
                    var newHour = ((angle + 90) / 30).round() % 12;
                    if (newHour <= 0) newHour = 12;
                    if (widget.onHourChanged != null) {
                      HapticFeedback.selectionClick();
                      widget.onHourChanged!(widget.is24Hour ? (isPM && newHour != 12 ? newHour + 12 : (newHour == 12 && !isPM ? 0 : newHour)) : newHour);
                    }
                  } else if (distance < radius * 0.9) {
                    // Outer circle - minute selection
                    final angle = math.atan2(offset.dy, offset.dx) * 180 / math.pi;
                    var newMinute = ((angle + 90) / 6).round() % 60;
                    if (newMinute < 0) newMinute += 60;
                    if (widget.onMinuteChanged != null) {
                      HapticFeedback.selectionClick();
                      widget.onMinuteChanged!(newMinute);
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  final double hourAngle;
  final double minuteAngle;
  final double animationValue;

  ClockPainter({
    required this.hour,
    required this.minute,
    required this.hourAngle,
    required this.minuteAngle,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw hour markers - larger, more visible
    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final markerRadius = radius - 25;
      final x = center.dx + markerRadius * math.cos(angle);
      final y = center.dy + markerRadius * math.sin(angle);

      // Draw hour marker dot
      final markerPaint = Paint()
        ..color = AppTheme.textPrimary.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), 4, markerPaint);

      // Draw hour number
      final textPainter = TextPainter(
        text: TextSpan(
          text: i.toString(),
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Position number slightly further out
      final textRadius = radius - 35;
      final textX = center.dx + textRadius * math.cos(angle);
      final textY = center.dy + textRadius * math.sin(angle);
      
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    // Draw minute markers - subtle dots
    final minutePaint = Paint()
      ..color = AppTheme.textSecondary.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 60; i++) {
      if (i % 5 != 0) {
        final angle = (i * 6 - 90) * math.pi / 180;
        final markerRadius = radius - 12;
        final x = center.dx + markerRadius * math.cos(angle);
        final y = center.dy + markerRadius * math.sin(angle);

        canvas.drawCircle(Offset(x, y), 1.5, minutePaint);
      }
    }

    // Draw hour hand shadow for depth
    final hourHandShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final hourHandLength = radius * 0.45;
    final hourHandEndX = center.dx + hourHandLength * math.cos(hourAngle);
    final hourHandEndY = center.dy + hourHandLength * math.sin(hourAngle);
    
    // Animated hour hand position
    final animatedHourEndX = center.dx + (hourHandEndX - center.dx) * animationValue;
    final animatedHourEndY = center.dy + (hourHandEndY - center.dy) * animationValue;

    // Draw shadow
    canvas.drawLine(center, Offset(animatedHourEndX + 1, animatedHourEndY + 1), hourHandShadowPaint);
    
    // Draw hour hand - thicker, more visible with gradient
    final hourHandPaint = Paint()
      ..color = AppTheme.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(animatedHourEndX, animatedHourEndY), hourHandPaint);

    // Draw minute hand shadow for depth
    final minuteHandShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final minuteHandLength = radius * 0.65;
    final minuteHandEndX = center.dx + minuteHandLength * math.cos(minuteAngle);
    final minuteHandEndY = center.dy + minuteHandLength * math.sin(minuteAngle);
    
    // Animated minute hand position
    final animatedMinuteEndX = center.dx + (minuteHandEndX - center.dx) * animationValue;
    final animatedMinuteEndY = center.dy + (minuteHandEndY - center.dy) * animationValue;

    // Draw shadow
    canvas.drawLine(center, Offset(animatedMinuteEndX + 1, animatedMinuteEndY + 1), minuteHandShadowPaint);
    
    // Draw minute hand - longer, more visible
    final minuteHandPaint = Paint()
      ..color = AppTheme.accentPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(animatedMinuteEndX, animatedMinuteEndY), minuteHandPaint);

    // Draw center dot - larger, more visible
    final centerOuterPaint = Paint()
      ..color = AppTheme.textPrimary
      ..style = PaintingStyle.fill;

    final centerInnerPaint = Paint()
      ..color = AppTheme.accentPrimary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, centerOuterPaint);
    canvas.drawCircle(center, 4, centerInnerPaint);
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) {
    return oldDelegate.hour != hour || 
           oldDelegate.minute != minute || 
           oldDelegate.animationValue != animationValue;
  }
}
