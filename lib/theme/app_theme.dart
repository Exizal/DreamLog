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
  
  // Glass Overlay - Translucent panels (more subtle for Liquid Glass)
  static const Color glassOverlay = Color(0x08FFFFFF); // 3% white - ultra transparent
  static const Color glassOverlayElevated = Color(0x0FFFFFFF); // 6% white - slightly more visible
  static const Color glassBorder = Color(0x15FFFFFF); // 8% white - subtle border
  static const Color glassBorderHighlight = Color(0x20FFFFFF); // 12% white - edge highlight
  static const Color glassInnerGlow = Color(0x05FFFFFF); // 2% white - inner thickness
  
  // Accents - Restrained, muted colors (no vibrant lights)
  static const Color accentPrimary = Color(0xFF4A9EFF); // Soft blue
  static const Color accentSecondary = Color(0xFF8B6FC7); // Muted purple
  static const Color accentTertiary = Color(0xFFC97BC0); // Soft magenta
  
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
  
  // Large Title - 28pt (reduced from 34pt for mobile), Bold
  static TextStyle largeTitle(BuildContext context) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.1,
      color: textPrimary,
    );
  }
  
  // Title - 22pt (reduced from 28pt for mobile), Bold
  static TextStyle title(BuildContext context) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.2,
      color: textPrimary,
    );
  }
  
  // Title 2 - 18pt (reduced from 22pt for mobile), Bold
  static TextStyle title2(BuildContext context) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.2,
      color: textPrimary,
    );
  }
  
  // Title 3 - 17pt (reduced from 20pt for mobile), Semibold
  static TextStyle title3(BuildContext context) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.2,
      color: textPrimary,
    );
  }
  
  // Headline - 15pt (reduced from 17pt for mobile), Semibold
  static TextStyle headline(BuildContext context) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
      color: textPrimary,
    );
  }
  
  // Body - 15pt (reduced from 17pt for mobile), Regular
  static TextStyle body(BuildContext context) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
      height: 1.5,
      color: textPrimary,
    );
  }
  
  // Callout - 14pt (reduced from 16pt for mobile), Regular
  static TextStyle callout(BuildContext context) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.1,
      height: 1.4,
      color: textPrimary,
    );
  }
  
  // Subheadline - 13pt (reduced from 15pt for mobile), Regular
  static TextStyle subheadline(BuildContext context) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.4,
      color: textSecondary,
    );
  }
  
  // Footnote - 12pt (reduced from 13pt for mobile), Regular
  static TextStyle footnote(BuildContext context) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.4,
      color: textMuted,
    );
  }
  
  // Caption - 11pt (reduced from 12pt for mobile), Regular
  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      height: 1.3,
      color: textMuted,
    );
  }
  
  // ============================================================================
  // LAYOUT TOKENS - Spacing, Radii, Blur, Shadows
  // ============================================================================
  
  // Spacing Scale (8pt grid system) - Optimized for mobile finger use
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0; // Minimum touch target spacing
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Minimum touch target size (iOS HIG: 44x44 points)
  static const double minTouchTarget = 44.0;
  
  // ============================================================================
  // RESPONSIVE UTILITIES
  // ============================================================================
  
  /// Get responsive width based on screen size
  static double responsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }
  
  /// Get responsive height based on screen size
  static double responsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }
  
  /// Get responsive font size that scales with screen size
  static double responsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 375.0; // Base on iPhone standard width
    return baseSize * scaleFactor.clamp(0.8, 1.2); // Limit scaling between 80% and 120%
  }
  
  /// Get responsive padding that adapts to screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      // Small phones
      return EdgeInsets.all(spacingS);
    } else if (screenWidth < 414) {
      // Standard phones
      return EdgeInsets.all(spacingM);
    } else {
      // Large phones
      return EdgeInsets.all(spacingL);
    }
  }
  
  /// Get responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return EdgeInsets.symmetric(horizontal: spacingS);
    } else if (screenWidth < 414) {
      return EdgeInsets.symmetric(horizontal: spacingM);
    } else {
      return EdgeInsets.symmetric(horizontal: spacingL);
    }
  }
  
  /// Check if device is small screen
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }
  
  /// Check if device is large screen
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 414;
  }
  
  /// Get responsive icon size
  static double responsiveIconSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 375.0;
    return baseSize * scaleFactor.clamp(0.9, 1.1);
  }
  
  // Corner Radii - Continuous, rounded corners (more rounded for iOS 26)
  static const double radiusXS = 10.0;
  static const double radiusS = 14.0;
  static const double radiusM = 18.0;
  static const double radiusL = 22.0;
  static const double radiusXL = 26.0;
  static const double radiusXXL = 30.0;
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
  
  // Opacity Levels - More subtle for Liquid Glass
  static const double opacityGlass = 0.03;
  static const double opacityGlassElevated = 0.06;
  static const double opacityBorder = 0.08;
  static const double opacityBorderHighlight = 0.12;
  static const double opacityInnerGlow = 0.02;
  static const double opacityDisabled = 0.4;
  
  // ============================================================================
  // GLASS DECORATION METHODS
  // ============================================================================
  
  /// Glass Surface Effect - Reusable glass panel decoration
  /// True transparent glass - NO white fading, pure transparency
  static BoxDecoration glassSurface({
    double borderRadius = radiusM,
    Color? backgroundColor,
    Color? borderColor,
    double blurIntensity = blurL,
    bool elevated = false,
  }) {
    return BoxDecoration(
      // Pure transparent glass - NO white color
      color: backgroundColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withOpacity(0.15),
        width: 1.0,
      ),
      boxShadow: [
        // Outer shadow - depth only
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
        // Soft glow shadow
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 30,
          offset: Offset.zero,
          spreadRadius: 0,
        ),
        // Additional depth for elevated surfaces
        if (elevated)
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
      ],
    );
  }
  
  /// Glass Card Widget - Composable glass panel
  /// True liquid glass with transparency, blur, and strategic reflections
  static Widget glassCard({
    required Widget child,
    EdgeInsets? padding,
    double borderRadius = radiusM,
    Color? backgroundColor,
    double blurSigma = 20.0, // Increased blur for true glass effect
    bool elevated = false,
    VoidCallback? onTap,
  }) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          // Backdrop blur layer - increased blur for true glass effect
          BackdropFilter(
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
          // No light reflections - pure glass transparency
        ],
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
  /// Liquid Glass effect with proper backdrop blur and shine
  static Widget glassButton({
    required String text,
    required VoidCallback onPressed,
    bool enabled = true,
    Color? accentColor,
    double borderRadius = radiusPill,
    EdgeInsets? padding,
    TextStyle? textStyle,
  }) {
    final isEnabled = enabled;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Backdrop blur layer (matching example: backdrop-filter: blur(3px))
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
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
                      // Semi-transparent white background (25% opacity)
                      color: isEnabled
                          ? Colors.white.withOpacity(0.25)
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(
                        color: isEnabled
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white.withOpacity(0.2),
                        width: 1.0,
                      ),
                      boxShadow: [
                        // Outer shadow (matching example: 0 6px 6px rgb(0 0 0 / 20%))
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 6),
                          spreadRadius: 0,
                        ),
                        // Soft glow (matching example: 0 0 20px rgb(0 0 0 / 10%))
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset.zero,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        text,
                        style: textStyle ?? TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isEnabled ? textPrimary : textDisabled,
                          letterSpacing: -0.2,
                          // Text shadow (matching example: 0 2px 4px rgb(0 0 0 / 10%))
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Shine overlay - simulates inset box-shadow shine
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.15), // Top-left shine
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.1), // Bottom-right shine
                      ],
                      stops: const [0.0, 0.2, 0.3, 0.7, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Background Layer - Full-screen animated gradient with depth
  static Widget backgroundLayer({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            // Multi-layered gradient for depth and glass pop
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundPrimary,
                backgroundSecondary,
                Color(0xFF1A1F2E), // Dark indigo
                Color(0xFF0F1525), // Deep blue-gray
                backgroundTertiary,
                Color(0xFF151A28), // Slightly lighter
                backgroundPrimary,
              ],
              stops: const [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Additional radial gradients for depth
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentPrimary.withOpacity(0.08),
                        accentSecondary.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                right: -150,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentSecondary.withOpacity(0.06),
                        accentTertiary.withOpacity(0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: constraints.maxHeight * 0.3,
                right: -200,
                child: Container(
                  width: 600,
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentTertiary.withOpacity(0.05),
                        accentPrimary.withOpacity(0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Main content
              child,
            ],
          ),
        );
      },
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
      fontFamily: fontFamily, // Apply SF Pro to all text
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
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: fontFamily, color: textPrimary, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(fontFamily: fontFamily, color: textPrimary, fontWeight: FontWeight.w600),
        displaySmall: TextStyle(fontFamily: fontFamily, color: textPrimary, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontFamily: fontFamily, color: textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontFamily: fontFamily, color: textPrimary, fontWeight: FontWeight.w500),
        titleLarge: TextStyle(fontFamily: fontFamily, color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: fontFamily, color: textPrimary, height: 1.5),
        bodyMedium: TextStyle(fontFamily: fontFamily, color: textSecondary, height: 1.4),
        labelLarge: TextStyle(fontFamily: fontFamily, color: textPrimary, fontWeight: FontWeight.w500),
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
