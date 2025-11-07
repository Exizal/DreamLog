import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

/// Reusable Glass Components
/// Following Apple iOS 26 liquid glass design patterns

/// Glass Background Layer - Full-screen animated gradient
class GlassBackground extends StatelessWidget {
  final Widget child;
  final bool animated;

  const GlassBackground({
    super.key,
    required this.child,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppTheme.backgroundLayer(child: child);
  }
}

/// Glass Surface - Reusable glass panel
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final double blurSigma;
  final bool elevated;
  final VoidCallback? onTap;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppTheme.radiusM,
    this.backgroundColor,
    this.blurSigma = AppTheme.blurL,
    this.elevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTheme.glassCard(
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      blurSigma: blurSigma,
      elevated: elevated,
      onTap: onTap,
      child: child,
    );
  }
}

/// Glass Card - Content card with glass effect
class GlassCard extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final EdgeInsets? padding;
  final double borderRadius;
  final bool elevated;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    this.borderRadius = AppTheme.radiusM,
    this.elevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: borderRadius,
      elevated: elevated,
      onTap: onTap,
      padding: padding ?? EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: AppTheme.spacingM),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) title!,
                if (subtitle != null) ...[
                  SizedBox(height: AppTheme.spacingXS),
                  subtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: AppTheme.spacingM),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Glass Button - Primary call-to-action
class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final Color? accentColor;
  final double borderRadius;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final IconData? icon;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.accentColor,
    this.borderRadius = AppTheme.radiusPill,
    this.padding,
    this.textStyle,
    this.icon,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled) {
      _controller.forward();
      AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AppTheme.glassButton(
          text: widget.text,
          onPressed: widget.enabled ? widget.onPressed : () {},
          enabled: widget.enabled,
          accentColor: widget.accentColor,
          borderRadius: widget.borderRadius,
          padding: widget.padding,
          textStyle: widget.textStyle,
        ),
      ),
    );
  }
}

/// Glass Tab Bar - Floating bottom tab bar
class GlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassTabItem> items;

  const GlassTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        child: GlassSurface(
          borderRadius: AppTheme.radiusPill,
          elevated: true,
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;
              
              return Expanded(
                child: _GlassTabItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () {
                    AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                    onTap(index);
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class GlassTabItem {
  final IconData icon;
  final String? label;
  final Color? selectedColor;

  const GlassTabItem({
    required this.icon,
    this.label,
    this.selectedColor,
  });
}

class _GlassTabItem extends StatelessWidget {
  final GlassTabItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _GlassTabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? (item.selectedColor ?? AppTheme.accentPrimary)
        : AppTheme.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(
                  item.icon,
                  color: color,
                  size: isSelected ? 24 : 22,
                ),
              ),
              if (item.label != null) ...[
                SizedBox(height: AppTheme.spacingXS),
                Text(
                  item.label!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass Input Field - Text input with glass styling
class GlassInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final int? maxLines;
  final bool expands;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool autofocus;

  const GlassInputField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.maxLines = 1,
    this.expands = false,
    this.style,
    this.hintStyle,
    this.onChanged,
    this.focusNode,
    this.keyboardType,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppTheme.blurM, sigmaY: AppTheme.blurM),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          expands: expands,
          onChanged: onChanged,
          focusNode: focusNode,
          keyboardType: keyboardType,
          autofocus: autofocus,
          style: style ?? AppTheme.body(context),
          decoration: InputDecoration(
            hintText: hintText,
            labelText: labelText,
            hintStyle: hintStyle ?? TextStyle(
              color: AppTheme.textMuted.withOpacity(0.5),
              fontSize: 17,
            ),
            labelStyle: AppTheme.subheadline(context),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(
                color: AppTheme.glassBorder.withOpacity(0.15),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(
                color: AppTheme.accentPrimary.withOpacity(0.25),
                width: 1,
              ),
            ),
            contentPadding: EdgeInsets.all(AppTheme.spacingM),
          ),
        ),
      ),
    );
  }
}

