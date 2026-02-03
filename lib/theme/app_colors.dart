import 'package:flutter/material.dart';

/// Semantic color palette for LilyNotes.
///
/// Every color has a light and dark variant accessed through the
/// static [light] and [dark] instances.
class AppColors {
  const AppColors._({
    // Backgrounds
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.card,
    required this.cardHover,
    // Brand
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.secondary,
    required this.secondaryContainer,
    required this.onSecondary,
    required this.tertiary,
    required this.tertiaryContainer,
    // Accent
    required this.accent,
    required this.accentContainer,
    // Text
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnPrimary,
    // Borders & dividers
    required this.divider,
    required this.border,
    required this.borderFocused,
    // Semantic
    required this.error,
    required this.errorContainer,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
    // Shadows
    required this.shadow,
    // Widget accent colors (subtle tints for widget headers / icons)
    required this.widgetNote,
    required this.widgetTask,
    required this.widgetCalendar,
    required this.widgetBookmark,
    required this.widgetGallery,
    required this.widgetDatabase,
    required this.widgetKanban,
    required this.widgetTimeline,
  });

  // ── Backgrounds ──────────────────────────────────────────────────────
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color card;
  final Color cardHover;

  // ── Brand ────────────────────────────────────────────────────────────
  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;
  final Color secondary;
  final Color secondaryContainer;
  final Color onSecondary;
  final Color tertiary;
  final Color tertiaryContainer;

  // ── Accent ───────────────────────────────────────────────────────────
  final Color accent;
  final Color accentContainer;

  // ── Text ──────────────────────────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnPrimary;

  // ── Borders & dividers ───────────────────────────────────────────────
  final Color divider;
  final Color border;
  final Color borderFocused;

  // ── Semantic ─────────────────────────────────────────────────────────
  final Color error;
  final Color errorContainer;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;

  // ── Shadows ──────────────────────────────────────────────────────────
  final Color shadow;

  // ── Widget-specific accent colors ────────────────────────────────────
  final Color widgetNote;
  final Color widgetTask;
  final Color widgetCalendar;
  final Color widgetBookmark;
  final Color widgetGallery;
  final Color widgetDatabase;
  final Color widgetKanban;
  final Color widgetTimeline;

  // ====================================================================
  // Light palette
  // ====================================================================
  static const light = AppColors._(
    // Backgrounds
    background: Color(0xFFFFF8F0),
    surface: Color(0xFFFFFBF5),
    surfaceVariant: Color(0xFFF5EDE3),
    card: Color(0xFFFFF5EB),
    cardHover: Color(0xFFFFF0E0),

    // Brand
    primary: Color(0xFFE8853D),       // warm amber-orange
    primaryContainer: Color(0xFFFFE0C2),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF5B9E9E),     // soft teal
    secondaryContainer: Color(0xFFD4EFEF),
    onSecondary: Color(0xFFFFFFFF),
    tertiary: Color(0xFFA07CDC),      // gentle lavender
    tertiaryContainer: Color(0xFFEDE0FA),

    // Accent
    accent: Color(0xFFE8853D),
    accentContainer: Color(0xFFFFE0C2),

    // Text
    textPrimary: Color(0xFF2D2017),
    textSecondary: Color(0xFF6B5B4F),
    textTertiary: Color(0xFF9E8E82),
    textOnPrimary: Color(0xFFFFFFFF),

    // Borders & dividers
    divider: Color(0xFFEDE4D9),
    border: Color(0xFFDDD2C5),
    borderFocused: Color(0xFFE8853D),

    // Semantic
    error: Color(0xFFD64545),
    errorContainer: Color(0xFFFCE4E4),
    success: Color(0xFF4CAF6E),
    successContainer: Color(0xFFDFF5E6),
    warning: Color(0xFFE8A33D),
    warningContainer: Color(0xFFFFF3D6),
    info: Color(0xFF4A90D9),
    infoContainer: Color(0xFFDFECFA),

    // Shadows
    shadow: Color(0x1A8B7355),

    // Widget accents
    widgetNote: Color(0xFFFBE8C8),
    widgetTask: Color(0xFFD4EFEF),
    widgetCalendar: Color(0xFFEDE0FA),
    widgetBookmark: Color(0xFFFFE0C2),
    widgetGallery: Color(0xFFFFDDE5),
    widgetDatabase: Color(0xFFDFECFA),
    widgetKanban: Color(0xFFDFF5E6),
    widgetTimeline: Color(0xFFFFF3D6),
  );

  // ====================================================================
  // Dark palette
  // ====================================================================
  static const dark = AppColors._(
    // Backgrounds
    background: Color(0xFF1A1A2E),
    surface: Color(0xFF1E1E34),
    surfaceVariant: Color(0xFF262640),
    card: Color(0xFF16213E),
    cardHover: Color(0xFF1B2845),

    // Brand
    primary: Color(0xFFEFA05E),       // lighter amber for contrast
    primaryContainer: Color(0xFF4A3220),
    onPrimary: Color(0xFF1A1A2E),
    secondary: Color(0xFF7BC5C5),     // brighter teal for dark
    secondaryContainer: Color(0xFF1E3E3E),
    onSecondary: Color(0xFF1A1A2E),
    tertiary: Color(0xFFBFA0E8),      // brighter lavender
    tertiaryContainer: Color(0xFF32264A),

    // Accent
    accent: Color(0xFFEFA05E),
    accentContainer: Color(0xFF4A3220),

    // Text
    textPrimary: Color(0xFFF0E6DA),
    textSecondary: Color(0xFFA99E94),
    textTertiary: Color(0xFF7A7068),
    textOnPrimary: Color(0xFF1A1A2E),

    // Borders & dividers
    divider: Color(0xFF2E2E48),
    border: Color(0xFF3A3A58),
    borderFocused: Color(0xFFEFA05E),

    // Semantic
    error: Color(0xFFEF7070),
    errorContainer: Color(0xFF3E1A1A),
    success: Color(0xFF6ED492),
    successContainer: Color(0xFF1A3E24),
    warning: Color(0xFFEFBF6E),
    warningContainer: Color(0xFF3E3218),
    info: Color(0xFF6EB0EF),
    infoContainer: Color(0xFF1A2E3E),

    // Shadows
    shadow: Color(0x40000000),

    // Widget accents
    widgetNote: Color(0xFF3E3220),
    widgetTask: Color(0xFF1E3838),
    widgetCalendar: Color(0xFF2E2440),
    widgetBookmark: Color(0xFF3E2E1A),
    widgetGallery: Color(0xFF3E1E28),
    widgetDatabase: Color(0xFF1A2838),
    widgetKanban: Color(0xFF1E3828),
    widgetTimeline: Color(0xFF3E3618),
  );
}
