import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

/// Instagram/X-style visual category picker with swipeable cards
class CategoryDropdown extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const CategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  static final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Lucid',
      'icon': Icons.visibility_rounded, // Apple-style rounded
      'iconFilled': Icons.visibility, // Filled variant
      'color': AppTheme.cosmicBlue,
      'description': 'Aware & conscious',
      'emoji': '👁️',
    },
    {
      'name': 'Nightmare',
      'icon': Icons.nightlight_round, // Apple-style rounded
      'iconFilled': Icons.nightlight_round,
      'color': AppTheme.disturbingRed,
      'description': 'Frightening dream',
      'emoji': '😱',
    },
    {
      'name': 'Symbolic',
      'icon': Icons.auto_awesome_rounded, // Apple-style rounded
      'iconFilled': Icons.auto_awesome,
      'color': AppTheme.dreamPurple,
      'description': 'Meaningful symbols',
      'emoji': '✨',
    },
    {
      'name': 'Abstract',
      'icon': Icons.blur_on_rounded, // Apple-style rounded
      'iconFilled': Icons.blur_on,
      'color': AppTheme.nebulaPink,
      'description': 'Unclear imagery',
      'emoji': '🌀',
    },
    {
      'name': 'Recurring',
      'icon': Icons.repeat_rounded, // Apple-style rounded
      'iconFilled': Icons.repeat,
      'color': AppTheme.peacefulGreen,
      'description': 'Repeating dream',
      'emoji': '🔁',
    },
    {
      'name': 'Other',
      'icon': Icons.category_rounded, // Apple-se rounded
      'iconFilled': Icons.category,
      'color': AppTheme.cosmicGray,
      'description': 'Different type',
      'emoji': '📝',
    },
  ];

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
                      AppTheme.cosmicBlue.withOpacity(0.2),
                      AppTheme.dreamPurple.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.cosmicBlue.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cosmicBlue.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.category_rounded, // Apple-style rounded
                  color: AppTheme.cosmicBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Category',
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
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final name = category['name'] as String;
                final iconFilled = category['iconFilled'] as IconData;
                final color = category['color'] as Color;
                final description = category['description'] as String;
                final emoji = category['emoji'] as String;
                final isSelected = widget.selectedCategory == name;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(24), // More rounded
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Stronger liquid glass blur
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick(); // Apple-style haptic
                        widget.onCategoryChanged(name);
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
                                    color.withOpacity(0.3),
                                    color.withOpacity(0.15),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : AppTheme.glassOverlay,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? color.withOpacity(0.6)
                                : AppTheme.glassBorder,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 25,
                                    spreadRadius: -4,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
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
                                        color.withOpacity(isSelected ? 0.25 : 0.1),
                                        color.withOpacity(isSelected ? 0.1 : 0.05),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.4),
                                              blurRadius: 16,
                                              spreadRadius: -2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 28),
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
                                        color: color.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.glassOverlay,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withOpacity(0.5),
                                            blurRadius: 8,
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
                            // Category name
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
                            const SizedBox(height: 4),
                            // Description
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.cosmicGray.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }
}
