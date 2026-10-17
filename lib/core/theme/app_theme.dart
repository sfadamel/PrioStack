import 'package:flutter/material.dart';

/// Palette et Design System "Neumorphism / Soft UI" supportant le Mode Sombre et le Mode Clair
class AppTheme {
  static bool _isDark = true;
  static bool get isDark => _isDark;

  static void setDarkMode(bool value) {
    _isDark = value;
  }

  // --- Palette Sombre (Dark Neumorphism) ---
  static const Color _darkBgDeep = Color(0xFF0F1015);
  static const Color _darkBgMain = Color(0xFF13141B);
  static const Color _darkSurfaceCard = Color(0xFF1A1B23);
  static const Color _darkSurfaceElevated = Color(0xFF222430);
  static const Color _darkSurfaceInput = Color(0xFF171820);
  static const Color _darkBorderSubtle = Color(0xFF2A2D3D);
  static const Color _darkBorderHighlight = Color(0xFF34384B);
  static const Color _darkTextPrimary = Color(0xFFF3F4F6);
  static const Color _darkTextSecondary = Color(0xFF9CA3AF);
  static const Color _darkTextMuted = Color(0xFF6B7280);

  // --- Palette Claire (Light Neumorphism / Soft UI) ---
  static const Color _lightBgDeep = Color(0xFFE6EBF2);
  static const Color _lightBgMain = Color(0xFFEEF2F7);
  static const Color _lightSurfaceCard = Color(0xFFF7F9FC);
  static const Color _lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color _lightSurfaceInput = Color(0xFFE3E8F0);
  static const Color _lightBorderSubtle = Color(0xFFD5DCE6);
  static const Color _lightBorderHighlight = Color(0xFFBFC9D9);
  static const Color _lightTextPrimary = Color(0xFF111827);
  static const Color _lightTextSecondary = Color(0xFF4B5563);
  static const Color _lightTextMuted = Color(0xFF6B7280);

  // --- Getters dynamiques réactifs au thème actif ---
  static Color get bgDeep => _isDark ? _darkBgDeep : _lightBgDeep;
  static Color get bgMain => _isDark ? _darkBgMain : _lightBgMain;
  static Color get surfaceCard => _isDark ? _darkSurfaceCard : _lightSurfaceCard;
  static Color get surfaceElevated =>
      _isDark ? _darkSurfaceElevated : _lightSurfaceElevated;
  static Color get surfaceInput =>
      _isDark ? _darkSurfaceInput : _lightSurfaceInput;
  static Color get borderSubtle =>
      _isDark ? _darkBorderSubtle : _lightBorderSubtle;
  static Color get borderHighlight =>
      _isDark ? _darkBorderHighlight : _lightBorderHighlight;
  static Color get textPrimary => _isDark ? _darkTextPrimary : _lightTextPrimary;
  static Color get textSecondary =>
      _isDark ? _darkTextSecondary : _lightTextSecondary;
  static Color get textMuted => _isDark ? _darkTextMuted : _lightTextMuted;

  // --- Accents constants (Bleu électrique / Indigo & Néons sémantiques) ---
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color neonPink = Color(0xFFEC4899);   // Urgence / Critique
  static const Color neonGreen = Color(0xFF10B981);  // Validé / En ligne / Déblocage Dev
  static const Color neonAmber = Color(0xFFF59E0B);  // Tâche de fond / Focus
  static const Color neonPurple = Color(0xFFA855F7); // Délégué / Suivi

  /// Dégradé principal des boutons et éléments actifs (Bleu électrique -> Indigo)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F8FF7), Color(0xFF3B82F6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé d'alerte pour le PUSH d'urgence
  static const LinearGradient urgencyGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Décoration de carte "Neumorphism / Soft UI" adaptée au Mode Sombre et au Mode Clair
  static BoxDecoration neumorphicCard({
    Color? color,
    double radius = 20,
    Color? glowColor,
    bool isElevated = true,
  }) {
    final effectiveColor = color ?? surfaceCard;
    return BoxDecoration(
      color: effectiveColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glowColor != null
            ? glowColor.withValues(alpha: 0.45)
            : borderSubtle.withValues(alpha: 0.85),
        width: 1.1,
      ),
      boxShadow: isElevated
          ? [
              // Ombre portée (sombre en dark mode, gris-bleuté doux en light mode)
              BoxShadow(
                color: _isDark
                    ? Colors.black.withValues(alpha: 0.55)
                    : const Color(0xFFAEC0D8).withValues(alpha: 0.48),
                offset: const Offset(6, 8),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              // Reflet supérieur (haut-gauche)
              BoxShadow(
                color: _isDark
                    ? Colors.white.withValues(alpha: 0.025)
                    : Colors.white.withValues(alpha: 0.9),
                offset: const Offset(-3, -3),
                blurRadius: 10,
              ),
              if (glowColor != null)
                BoxShadow(
                  color: glowColor.withValues(alpha: _isDark ? 0.18 : 0.14),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
            ]
          : [],
    );
  }

  /// Décoration en creux ("Inset / Pressed") adaptée au Mode Sombre et au Mode Clair
  static BoxDecoration neumorphicInset({
    Color? color,
    double radius = 14,
  }) {
    final effectiveColor = color ?? surfaceInput;
    return BoxDecoration(
      color: effectiveColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: _isDark ? const Color(0xFF0A0B0E) : const Color(0xFFCBD4E1),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: _isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.white.withValues(alpha: 0.7),
          offset: const Offset(0, 1),
          blurRadius: 1,
        ),
      ],
    );
  }

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDarkTheme = brightness == Brightness.dark;
    final primaryText = isDarkTheme ? _darkTextPrimary : _lightTextPrimary;
    final secondaryText = isDarkTheme ? _darkTextSecondary : _lightTextSecondary;
    final mutedText = isDarkTheme ? _darkTextMuted : _lightTextMuted;
    final cardCol = isDarkTheme ? _darkSurfaceCard : _lightSurfaceCard;
    final elevCol = isDarkTheme ? _darkSurfaceElevated : _lightSurfaceElevated;
    final borderSub = isDarkTheme ? _darkBorderSubtle : _lightBorderSubtle;
    final borderHigh = isDarkTheme ? _darkBorderHighlight : _lightBorderHighlight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDarkTheme ? _darkBgDeep : _lightBgDeep,
      primaryColor: accentBlue,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accentBlue,
        onPrimary: Colors.white,
        secondary: accentIndigo,
        onSecondary: Colors.white,
        error: neonPink,
        onError: Colors.white,
        surface: cardCol,
        onSurface: primaryText,
      ),
      fontFamily: 'Segoe UI',
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: primaryText,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          color: primaryText,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: primaryText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: secondaryText,
          fontSize: 13,
        ),
        bodySmall: TextStyle(
          color: mutedText,
          fontSize: 11.5,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardCol,
      ),
      dividerColor: borderSub,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: elevCol,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderHigh),
        ),
        textStyle: TextStyle(color: primaryText, fontSize: 12),
      ),
    );
  }
}
