import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

class RatingPicker extends StatefulWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const RatingPicker({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  static const List<String> emojis = ['😴', '😐', '😊', '😄', '🌟'];

  @override
  State<RatingPicker> createState() => _RatingPickerState();
}

class _RatingPickerState extends State<RatingPicker> {
  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return AppTheme.disturbingRed;
      case 2:
        return AppTheme.anxiousOrange;
      case 3:
        return AppTheme.accentSecondary;
      case 4:
        return AppTheme.joyfulAmber;
      case 5:
        return AppTheme.accentPrimary;
      default:
        return AppTheme.accentSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingColor = _getRatingColor(widget.rating);
    return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Stronger liquid glass blur
          child: Container(
            padding: EdgeInsets.all(AppTheme.spacingM + 4),
            decoration: AppTheme.glassContainer(borderRadius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ratingColor.withOpacity(0.18),
                          ratingColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ratingColor.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.star_rounded, // Apple-style rounded
                      color: ratingColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Rating',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.starLight,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  final isSelected = widget.rating == index + 1;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick(); // Apple-style haptic
                      widget.onRatingChanged(index + 1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      padding: const EdgeInsets.all(16), // Larger touch target (48x48)
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  ratingColor.withOpacity(0.2),
                                  ratingColor.withOpacity(0.1),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? ratingColor.withOpacity(0.3)
                              : AppTheme.glassBorder,
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: ratingColor.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: -2,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        RatingPicker.emojis[index],
                        style: TextStyle(
                          fontSize: isSelected ? 36 : 32,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
