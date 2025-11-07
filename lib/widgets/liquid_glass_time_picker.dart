import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

/// iOS 26 Liquid Glass Time Picker
/// Beautiful, skeuomorphic time picker with liquid glass design
class LiquidGlassTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final VoidCallback? onAccept;

  const LiquidGlassTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
    this.onAccept,
  });

  @override
  State<LiquidGlassTimePicker> createState() => _LiquidGlassTimePickerState();
}

class _LiquidGlassTimePickerState extends State<LiquidGlassTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;
  bool _isAM = true;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    if (_selectedHour >= 12) {
      _isAM = false;
      if (_selectedHour > 12) {
        _selectedHour -= 12;
      }
    } else if (_selectedHour == 0) {
      _selectedHour = 12;
    }
  }

  void _updateTime() {
    int hour24 = _selectedHour;
    if (!_isAM && _selectedHour != 12) {
      hour24 = _selectedHour + 12;
    } else if (_isAM && _selectedHour == 12) {
      hour24 = 0;
    }
    widget.onTimeChanged(TimeOfDay(hour: hour24, minute: _selectedMinute));
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.all(AppTheme.spacingM + 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Digital Time Display
              _buildDigitalTimeDisplay(),
              SizedBox(height: AppTheme.spacingL),
              // Accept Button
              _buildAcceptButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalTimeDisplay() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.responsiveHorizontalPadding(context).horizontal,
        vertical: AppTheme.spacingL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Time Display Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hour
              _buildTimeDigit(_selectedHour.toString().padLeft(2, '0'), true),
              const SizedBox(width: 12),
              // Colon
              const Text(
                ':',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.textPrimary,
                  letterSpacing: -2,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              // Minute
              _buildTimeDigit(_selectedMinute.toString().padLeft(2, '0'), false),
            ],
          ),
          SizedBox(height: AppTheme.spacingM),
          // AM/PM Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAMPMButton('AM', true),
              const SizedBox(width: 8),
              _buildAMPMButton('PM', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDigit(String digit, bool isHour) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Increment button
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isHour) {
                _selectedHour = (_selectedHour % 12) + 1;
                if (_selectedHour > 12) _selectedHour = 1;
              } else {
                _selectedMinute = (_selectedMinute + 1) % 60;
              }
              _updateTime();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.glassOverlay.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_drop_up_rounded,
              color: AppTheme.textPrimary.withOpacity(0.7),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Time digit display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundTertiary.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.glassBorder.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -1.0,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Decrement button
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isHour) {
                _selectedHour = (_selectedHour - 1);
                if (_selectedHour < 1) _selectedHour = 12;
              } else {
                _selectedMinute = (_selectedMinute - 1);
                if (_selectedMinute < 0) _selectedMinute = 59;
              }
              _updateTime();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.glassOverlay.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_drop_down_rounded,
              color: AppTheme.textPrimary.withOpacity(0.7),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAMPMButton(String label, bool isAM) {
    final isSelected = _isAM == isAM;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAM = isAM;
          _updateTime();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.accentPrimary.withOpacity(0.25),
                    AppTheme.accentSecondary.withOpacity(0.18),
                  ],
                )
              : null,
          color: isSelected ? null : AppTheme.glassOverlay.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentPrimary.withOpacity(0.3)
                : AppTheme.glassBorder.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildAcceptButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentPrimary.withOpacity(0.25),
                AppTheme.accentSecondary.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.accentPrimary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                _updateTime();
                if (widget.onAccept != null) {
                  widget.onAccept!();
                } else {
                  Navigator.of(context).pop(TimeOfDay(
                    hour: _selectedHour == 12 && _isAM
                        ? 0
                        : (!_isAM && _selectedHour != 12 ? _selectedHour + 12 : _selectedHour),
                    minute: _selectedMinute,
                  ));
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text(
                    'Accept',
                    style: TextStyle(
                      color: AppTheme.starLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
