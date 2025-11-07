import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

/// Instagram/X-style visual mood picker with Apple-style icons
class MoodPicker extends StatefulWidget {
  final String selectedMood;
  final ValueChanged<String> onMoodChanged;

  const MoodPicker({
    super.key,
    required this.selectedMood,
    required this.onMoodChanged,
  });

  @override
  State<MoodPicker> createState() => _MoodPickerState();
}

class _MoodPickerState extends State<MoodPicker> {
  final List<Map<String, dynamic>> _moods = [
    {
      'name': 'Peaceful',
      'icon': Icons.spa_rounded, // Apple-style rounded
      'iconFilled': Icons.spa, // Filled variant
      'color': AppTheme.peacefulGreen,
      'emoji': '😌',
    },
    {
      'name': 'Joyful',
      'icon': Icons.emoji_emotions_rounded, // Apple-style rounded
      'iconFilled': Icons.emoji_emotions,
      'color': AppTheme.joyfulGold,
      'emoji': '😊',
    },
    {
      'name': 'Disturbing',
      'icon': Icons.sentiment_very_dissatisfied_rounded, // Apple-style rounded
      'iconFilled': Icons.sentiment_very_dissatisfied,
      'color': AppTheme.disturbingRed,
      'emoji': '😰',
    },
    {
      'name': 'Anxious',
      'icon': Icons.psychology_rounded, // Apple-style rounded
      'iconFilled': Icons.psychology,
      'color': AppTheme.anxiousOrange,
      'emoji': '😟',
    },
    {
      'name': 'Surreal',
      'icon': Icons.auto_awesome_rounded, // Apple-style rounded
      'iconFilled': Icons.auto_awesome,
      'color': AppTheme.surrealCyan,
      'emoji': '🌀',
    },
    {
      'name': 'Custom',
      'icon': Icons.edit_rounded, // Apple-style rounded
      'iconFilled': Icons.edit,
      'color': AppTheme.mysticalPink,
      'emoji': '✏️',
    },
  ];

  final TextEditingController _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final moodNames = _moods.map((m) => m['name'] as String).toList();
    if (!moodNames.contains(widget.selectedMood)) {
      _customController.text = widget.selectedMood;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTheme.glassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Apple-style icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.peacefulGreen.withOpacity(0.2),
                      AppTheme.joyfulAmber.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.peacefulGreen.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.peacefulGreen.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded, // Apple-style rounded
                  color: AppTheme.peacefulGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mood',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.starLight,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Instagram/X-style horizontal scrollable cards with better responsiveness
          SizedBox(
            height: 130, // Slightly taller for better touch targets
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(), // iOS-style bounce
              itemCount: _moods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final mood = _moods[index];
                final name = mood['name'] as String;
                final iconFilled = mood['iconFilled'] as IconData;
                final color = mood['color'] as Color;
                final emoji = mood['emoji'] as String;
                final isSelected = widget.selectedMood.toLowerCase() == name.toLowerCase() ||
                    (name == 'Custom' &&
                        !_moods.map((m) => (m['name'] as String).toLowerCase())
                            .contains(widget.selectedMood.toLowerCase()));

                return ClipRRect(
                  borderRadius: BorderRadius.circular(24), // More rounded
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Stronger liquid glass blur
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick(); // Apple-style haptic
                        if (name == 'Custom') {
                          widget.onMoodChanged(
                            _customController.text.isEmpty ? 'Custom' : _customController.text,
                          );
                        } else {
                          widget.onMoodChanged(name);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: 110, // Slightly wider for better touch
                        constraints: const BoxConstraints(minHeight: 48),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    color.withOpacity(0.2),
                                    color.withOpacity(0.1),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : AppTheme.glassOverlay,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? color.withOpacity(0.3)
                                : AppTheme.glassBorder,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.2),
                                    blurRadius: 18,
                                    spreadRadius: -3,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 3),
                                    spreadRadius: -2,
                                  ),
                                ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Emoji + Icon combination (Apple-style)
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Emoji background
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        color.withOpacity(isSelected ? 0.15 : 0.08),
                                        color.withOpacity(isSelected ? 0.08 : 0.04),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.2),
                                              blurRadius: 12,
                                              spreadRadius: -2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ),
                                // Icon overlay (Apple-style filled when selected)
                                if (isSelected)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.glassOverlay,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withOpacity(0.3),
                                            blurRadius: 6,
                                            spreadRadius: -1,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        iconFilled, // Filled icon when selected
                                        color: AppTheme.starLight,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Mood name
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? AppTheme.starLight : AppTheme.moonGlow,
                                letterSpacing: -0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Custom mood input
          if (widget.selectedMood == 'Custom' ||
              !_moods.map((m) => m['name'] as String).contains(widget.selectedMood)) ...[
            const SizedBox(height: 20),
            AppTheme.glassCard(
              borderRadius: 16,
              blurSigma: 30.0, // Stronger liquid glass blur
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _customController,
                decoration: const InputDecoration(
                  hintText: 'Enter custom mood...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppTheme.cosmicGray),
                  contentPadding: EdgeInsets.symmetric(vertical: 16), // Better touch target
                ),
                style: const TextStyle(color: AppTheme.starLight),
                onChanged: (value) {
                  widget.onMoodChanged(value.isEmpty ? 'Custom' : value);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
