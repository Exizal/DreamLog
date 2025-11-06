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
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Stronger liquid glass blur
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassContainer(borderRadius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.dreamPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.star_rounded, // Apple-style rounded
                      color: AppTheme.joyfulAmber,
                      size: 22,
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
              const SizedBox(height: 20),
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
                                  AppTheme.joyfulAmber.withOpacity(0.3),
                                  AppTheme.dreamPurple.withOpacity(0.2),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.joyfulAmber.withOpacity(0.5)
                              : AppTheme.glassBorder,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.joyfulAmber.withOpacity(0.4),
                                  blurRadius: 20,
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
