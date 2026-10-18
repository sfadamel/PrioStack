import 'package:flutter/material.dart';

/// Palette et Design System "Minimalist Precision UI" (inspiré de Linear, Raycast & Things 3)
/// Supportant le Mode Sombre et le Mode Clair avec un contraste pur et des bordures ultra-fines.
class AppTheme {
  static bool _isDark = true;
  static bool get isDark => _isDark;

  static void setDarkMode(bool value) {
    _isDark = value;
  }

  // --- Palette Sombre (Obsidian & Slate Minimal) ---
  static const Color _darkBgDeep = Color(0xFF0B0C10);
  static const Color _darkBgMain = Color(0xFF111319);
  static const Color _darkSurfaceCard = Color(0xFF171921);
  static const Color _darkSurfaceElevated = Color(0xFF1E212B);
  static const Color _darkSurfaceInput = Color(0xFF13151C);
  static const Color _darkBorderSubtle = Color(0xFF232734);
  static const Color _darkBorderHighlight = Color(0xFF2E3344);
  static const Color _darkTextPrimary = Color(0xFFF3F4F6);
  static const Color _darkTextSecondary = Color(0xFF9CA3AF);
  static const Color _darkTextMuted = Color(0xFF64748B);

  // --- Palette Claire (Pure Alabaster & Crisp Slate) ---
  static const Color _lightBgDeep = Color(0xFFF3F5F8);
  static const Color _lightBgMain = Color(0xFFF8FAFC);
  static const Color _lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color _lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color _lightSurfaceInput = Color(0xFFF1F5F9);
  static const Color _lightBorderSubtle = Color(0xFFE2E8F0);
  static const Color _lightBorderHighlight = Color(0xFFCBD5E1);
  static const Color _lightTextPrimary = Color(0xFF0F172A);
  static const Color _lightTextSecondary = Color(0xFF475569);
  static const Color _lightTextMuted = Color(0xFF94A3B8);

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

  // --- Accents sémantiques sobres et précis ---
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color neonPink = Color(0xFFF43F5E);   // Urgence / Critique
  static const Color neonGreen = Color(0xFF10B981);  // Validé / En ligne / Déblocage Dev
  static const Color neonAmber = Color(0xFFF59E0B);  // Tâche de fond / Focus
  static const Color neonPurple = Color(0xFFA855F7); // Délégué / Suivi

  /// Dégradé principal des boutons et éléments actifs
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé d'alerte pour le PUSH d'urgence
  static const LinearGradient urgencyGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Décoration de carte épurée (bordure hairline 1px + ombre douce légère)
  static BoxDecoration neumorphicCard({
    Color? color,
    double radius = 16,
    Color? glowColor,
    bool isElevated = true,
  }) {
    final effectiveColor = color ?? surfaceCard;
    return BoxDecoration(
      color: effectiveColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glowColor != null
            ? glowColor.withValues(alpha: 0.38)
            : borderSubtle,
        width: 1.0,
      ),
      boxShadow: isElevated
          ? [
              BoxShadow(
                color: _isDark
                    ? Colors.black.withValues(alpha: 0.28)
                    : const Color(0xFF0F172A).withValues(alpha: 0.04),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
              if (glowColor != null)
                BoxShadow(
                  color: glowColor.withValues(alpha: _isDark ? 0.08 : 0.06),
                  blurRadius: 16,
                ),
            ]
          : [],
    );
  }

  /// Décoration de surface interne sobre (Input / Segmented Control)
  static BoxDecoration neumorphicInset({
    Color? color,
    double radius = 10,
  }) {
    final effectiveColor = color ?? surfaceInput;
    return BoxDecoration(
      color: effectiveColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderSubtle,
        width: 1.0,
      ),
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
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          color: primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: primaryText,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: secondaryText,
          fontSize: 12.5,
        ),
        bodySmall: TextStyle(
          color: mutedText,
          fontSize: 11,
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
        textStyle: TextStyle(color: primaryText, fontSize: 11.5),
      ),
    );
  }
}
