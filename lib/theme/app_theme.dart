import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

/// Liquid Glass Design System
/// iOS 26-inspired design following Apple Human Interface Guidelines
/// Production-quality, accessible, modular UI system
class AppTheme {
  // ============================================================================
  // COLOR SYSTEM - Deep Graphite/Indigo/Midnight with Restrained Accents
  // ============================================================================
  
  // Background - Deep, rich, dark tones
  static const Color backgroundPrimary = Color(0xFF0A0E1A); // Deep midnight
  static const Color backgroundSecondary = Color(0xFF121620); // Slightly lighter
  static const Color backgroundTertiary = Color(0xFF1A1F2E); // Surface layer
  
  // Glass Overlay - Translucent panels
  static const Color glassOverlay = Color(0x0AFFFFFF); // 4% white - ultra transparent
  static const Color glassOverlayElevated = Color(0x12FFFFFF); // 7% white - slightly more visible
  static const Color glassBorder = Color(0x1AFFFFFF); // 10% white - subtle border
  static const Color glassBorderHighlight = Color(0x26FFFFFF); // 15% white - edge highlight
  static const Color glassInnerGlow = Color(0x08FFFFFF); // 3% white - inner thickness
  
  // Accents - Restrained neon-like colors
  static const Color accentPrimary = Color(0xFF22D3EE); // Cyan
  static const Color accentSecondary = Color(0xFF7C3AED); // Purple
  static const Color accentTertiary = Color(0xFFF472B6); // Magenta
  
  // Text - Vibrant and readable on glass
  static const Color textPrimary = Color(0xFFF1F5F9); // Primary white
  static const Color textSecondary = Color(0xFFCBD5E1); // Secondary gray
  static const Color textMuted = Color(0xFF94A3B8); // Muted gray
  static const Color textDisabled = Color(0xFF64748B); // Disabled gray
  
  // Semantic Colors
  static const Color error = Color(0xFFF87171); // Soft red
  static const Color success = Color(0xFF34D399); // Emerald
  static const Color warning = Color(0xFFFBBF24); // Amber
  
  // Mood Colors - Dreamy pastels
  static const Color moodPeaceful = Color(0xFF34D399);
  static const Color moodJoyful = Color(0xFFFBBF24);
  static const Color moodDisturbing = Color(0xFFF87171);
  static const Color moodAnxious = Color(0xFFA78BFA);
  static const Color moodSurreal = Color(0xFF22D3EE);
  static const Color moodMystical = Color(0xFFF472B6);
  
  // ============================================================================
  // TYPOGRAPHY SYSTEM - SF Pro-inspired with Dynamic Type Support
  // ============================================================================
  
  static const String fontFamily = 'SF Pro Display'; // Will fallback to system font
  
  // Large Title - 34pt, Bold
  static TextStyle largeTitle(BuildContext context) {
    return TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.1,
      color: textPrimary,
    );
  }
  
  // Title - 28pt, Bold
  static TextStyle title(BuildContext context) {
    return TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.2,
      color: textPrimary,
    );
  }
  
  // Title 2 - 22pt, Bold
  static TextStyle title2(BuildContext context) {
    return TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.2,
      color: textPrimary,
    );
  }
  
  // Title 3 - 20pt, Semibold
  static TextStyle title3(BuildContext context) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.2,
      color: textPrimary,
    );
  }
  
  // Headline - 17pt, Semibold
  static TextStyle headline(BuildContext context) {
    return TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
      color: textPrimary,
    );
  }
  
  // Body - 17pt, Regular
  static TextStyle body(BuildContext context) {
    return TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
      height: 1.5,
      color: textPrimary,
    );
  }
  
  // Callout - 16pt, Regular
  static TextStyle callout(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.1,
      height: 1.4,
      color: textPrimary,
    );
  }
  
  // Subheadline - 15pt, Regular
  static TextStyle subheadline(BuildContext context) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.4,
      color: textSecondary,
    );
  }
  
  // Footnote - 13pt, Regular
  static TextStyle footnote(BuildContext context) {
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.4,
      color: textMuted,
    );
  }
  
  // Caption - 12pt, Regular
  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      height: 1.3,
      color: textMuted,
    );
  }
  
  // ============================================================================
  // LAYOUT TOKENS - Spacing, Radii, Blur, Shadows
  // ============================================================================
  
  // Spacing Scale (8pt grid system)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Corner Radii - Continuous, rounded corners
  static const double radiusXS = 8.0;
  static const double radiusS = 12.0;
  static const double radiusM = 16.0;
  static const double radiusL = 20.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 28.0;
  static const double radiusPill = 999.0; // For pill-shaped elements
  
  // Blur Radii - For glass effects
  static const double blurS = 10.0;
  static const double blurM = 20.0;
  static const double blurL = 30.0;
  static const double blurXL = 40.0;
  
  // Shadow Presets
  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
  ];
  
  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
  ];
  
  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: -3,
    ),
  ];
  
  static List<BoxShadow> shadowElevated = [
    BoxShadow(
      color: Colors.black.withOpacity(0.6),
      blurRadius: 40,
      offset: const Offset(0, 12),
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 20,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];
  
  // Opacity Levels
  static const double opacityGlass = 0.04;
  static const double opacityGlassElevated = 0.07;
  static const double opacityBorder = 0.10;
  static const double opacityBorderHighlight = 0.15;
  static const double opacityInnerGlow = 0.03;
  static const double opacityDisabled = 0.4;
  
  // ============================================================================
  // GLASS DECORATION METHODS
  // ============================================================================
  
  /// Glass Surface Effect - Reusable glass panel decoration
  static BoxDecoration glassSurface({
    double borderRadius = radiusM,
    Color? backgroundColor,
    Color? borderColor,
    double blurIntensity = blurL,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? (elevated ? glassOverlayElevated : glassOverlay),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? glassBorder,
        width: 1.0,
      ),
      boxShadow: [
        // Inner glow - simulates glass thickness
        BoxShadow(
          color: Colors.white.withOpacity(opacityInnerGlow),
          blurRadius: blurIntensity * 0.3,
          spreadRadius: -blurIntensity * 0.2,
        ),
        // Outer shadow - depth
        if (elevated) ...shadowElevated else ...shadowLarge,
      ],
    );
  }
  
  /// Glass Card Widget - Composable glass panel
  static Widget glassCard({
    required Widget child,
    EdgeInsets? padding,
    double borderRadius = radiusM,
    Color? backgroundColor,
    double blurSigma = blurL,
    bool elevated = false,
    VoidCallback? onTap,
  }) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding ?? EdgeInsets.all(spacingM),
          decoration: glassSurface(
            borderRadius: borderRadius,
            backgroundColor: backgroundColor,
            blurIntensity: blurSigma,
            elevated: elevated,
          ),
          child: child,
        ),
      ),
    );
    
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }
    
    return card;
  }
  
  /// Glass Button - Primary call-to-action
  static Widget glassButton({
    required String text,
    required VoidCallback onPressed,
    bool enabled = true,
    Color? accentColor,
    double borderRadius = radiusPill,
    EdgeInsets? padding,
    TextStyle? textStyle,
  }) {
    final color = accentColor ?? accentPrimary;
    final isEnabled = enabled;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurM, sigmaY: blurM),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled ? onPressed : null,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding ?? EdgeInsets.symmetric(
                  horizontal: spacingXL,
                  vertical: spacingM,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEnabled
                        ? [
                            color.withOpacity(0.3),
                            color.withOpacity(0.2),
                          ]
                        : [
                            glassOverlay.withOpacity(0.5),
                            glassOverlay.withOpacity(0.3),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isEnabled
                        ? color.withOpacity(0.4)
                        : glassBorder.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: isEnabled ? shadowMedium : shadowSmall,
                ),
                child: Center(
                  child: Text(
                    text,
                    style: textStyle ?? TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? textPrimary : textDisabled,
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
  
  /// Background Layer - Full-screen animated gradient
  static Widget backgroundLayer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundPrimary,
            backgroundSecondary,
            backgroundTertiary,
            backgroundPrimary,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  static Color getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'peaceful':
        return moodPeaceful;
      case 'joyful':
        return moodJoyful;
      case 'disturbing':
        return moodDisturbing;
      case 'anxious':
        return moodAnxious;
      case 'surreal':
        return moodSurreal;
      default:
        return moodMystical;
    }
  }
  
  /// Apple-style haptic feedback
  static void hapticFeedback([HapticFeedbackType type = HapticFeedbackType.lightImpact]) {
    switch (type) {
      case HapticFeedbackType.lightImpact:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.mediumImpact:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavyImpact:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selectionClick:
        HapticFeedback.selectionClick();
        break;
    }
  }
  
  // Legacy aliases for compatibility
  static const Color deepViolet = accentSecondary;
  static const Color dreamPurple = accentSecondary;
  static const Color cosmicBlue = accentPrimary;
  static const Color nebulaPink = accentTertiary;
  static const Color nebulaPurple = backgroundTertiary;
  static const Color midnightNavy = backgroundPrimary;
  static const Color starLight = textPrimary;
  static const Color moonGlow = textSecondary;
  static const Color cosmicGray = textMuted;
  static const Color offWhite = textPrimary;
  static const Color darkSurface = backgroundTertiary;
  static const Color darkSurfaceVariant = backgroundSecondary;
  static const Color darkBackground = backgroundPrimary;
  static const Color textPrimaryColor = textPrimary;
  static const Color textSecondaryColor = textSecondary;
  static const Color accentColor = accentPrimary;
  static const Color darkViolet = accentSecondary;
  static const Color peacefulGreen = moodPeaceful;
  static const Color peacefulColor = moodPeaceful;
  static const Color joyfulAmber = moodJoyful;
  static const Color joyfulGold = moodJoyful;
  static const Color joyfulColor = moodJoyful;
  static const Color disturbingRed = moodDisturbing;
  static const Color anxiousLavender = moodAnxious;
  static const Color anxiousOrange = moodAnxious;
  static const Color anxiousColor = moodAnxious;
  static const Color surrealCyan = moodSurreal;
  static const Color surrealColor = moodSurreal;
  static const Color mysticalPink = moodMystical;
  static const Color mysticalPurple = moodMystical;
  static const Color customMoodColor = moodMystical;
  
  // Legacy methods for compatibility
  static BoxDecoration glassContainer({
    double borderRadius = 20,
    Color? backgroundColor,
    Color? borderColor,
    double blurIntensity = 30.0,
  }) {
    return glassSurface(
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      blurIntensity: blurIntensity,
    );
  }
  
  static BoxDecoration glassInput({
    double borderRadius = 16,
    Color? borderColor,
  }) {
    return glassSurface(
      borderRadius: borderRadius,
      borderColor: borderColor,
    );
  }
  
  static Widget dreamBackground({required Widget child}) {
    return backgroundLayer(child: child);
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        tertiary: accentTertiary,
        surface: backgroundTertiary,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        error: error,
      ),
      scaffoldBackgroundColor: backgroundPrimary,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: glassOverlay,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassOverlay,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textMuted.withOpacity(0.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingM),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: glassBorder.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: accentPrimary, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentPrimary,
        foregroundColor: textPrimary,
        elevation: 12,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        displaySmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, height: 1.5),
        bodyMedium: TextStyle(color: textSecondary, height: 1.4),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
      ),
    );
  }
}

enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
}
