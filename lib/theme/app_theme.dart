import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Central theme configuration for LilyNotes.
///
/// Access the pre-built themes via [AppTheme.light] and [AppTheme.dark].
class AppTheme {
  AppTheme._();

  // ── Shared constants ─────────────────────────────────────────────────
  static const double _radius = 16.0;
  static const double _radiusSmall = 12.0;
  static const double _radiusLarge = 24.0;
  static const double _cardElevation = 1.0;
  static const double _dialogElevation = 4.0;

  static final BorderRadius borderRadius = BorderRadius.circular(_radius);
  static final BorderRadius borderRadiusSmall =
      BorderRadius.circular(_radiusSmall);
  static final BorderRadius borderRadiusLarge =
      BorderRadius.circular(_radiusLarge);

  // ── Light theme ──────────────────────────────────────────────────────
  static final ThemeData light = _build(AppColors.light, Brightness.light);

  // ── Dark theme ───────────────────────────────────────────────────────
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);

  // ── Builder ──────────────────────────────────────────────────────────
  static ThemeData _build(AppColors c, Brightness brightness) {
    final bool isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: isLight ? c.textPrimary : c.textPrimary,
      secondary: c.secondary,
      onSecondary: c.onSecondary,
      secondaryContainer: c.secondaryContainer,
      onSecondaryContainer: isLight ? c.textPrimary : c.textPrimary,
      tertiary: c.tertiary,
      onTertiary: c.onPrimary,
      tertiaryContainer: c.tertiaryContainer,
      onTertiaryContainer: isLight ? c.textPrimary : c.textPrimary,
      error: c.error,
      onError: Colors.white,
      errorContainer: c.errorContainer,
      onErrorContainer: c.error,
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.surfaceVariant,
      onSurfaceVariant: c.textSecondary,
      outline: c.border,
      outlineVariant: c.divider,
      shadow: c.shadow,
      inverseSurface: isLight ? c.textPrimary : c.card,
      onInverseSurface: isLight ? c.surface : c.textPrimary,
    );

    final textTheme = _textTheme(c);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      textTheme: textTheme,
      fontFamily: 'Inter',
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      // ── IconButton ────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(52, 52),
          iconSize: 28,
        ),
      ),

      // ── AppBar ─────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: c.textSecondary, size: 22),
      ),

      // ── Card ───────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: c.card,
        elevation: _cardElevation,
        shadowColor: c.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: c.divider, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── Elevated button ────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Outlined button ────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          side: BorderSide(color: c.border, width: 1.2),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Text button ────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusSmall),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),

      // ── FAB ────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Input decoration ───────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: c.divider, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: c.borderFocused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: c.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: c.textTertiary,
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        labelStyle: TextStyle(color: c.textSecondary, fontSize: 15),
        floatingLabelStyle: TextStyle(color: c.primary),
        prefixIconColor: c.textTertiary,
        suffixIconColor: c.textTertiary,
      ),

      // ── Chip ───────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceVariant,
        selectedColor: c.primaryContainer,
        disabledColor: c.surfaceVariant,
        labelStyle: TextStyle(
          color: c.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(color: c.primary),
        side: BorderSide(color: c.divider, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: borderRadiusSmall),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Dialog ─────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: _dialogElevation,
        shadowColor: c.shadow,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusLarge),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: textTheme.bodyMedium,
      ),

      // ── Bottom sheet ───────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: _dialogElevation,
        shadowColor: c.shadow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        dragHandleColor: c.border,
        dragHandleSize: const Size(40, 4),
        modalBarrierColor: Colors.black38,
      ),

      // ── Snackbar ───────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? c.textPrimary : c.surfaceVariant,
        contentTextStyle: TextStyle(
          color: isLight ? c.surface : c.textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: borderRadiusSmall),
        behavior: SnackBarBehavior.floating,
        elevation: 2,
      ),

      // ── Divider ────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: c.divider,
        thickness: 0.8,
        space: 1,
      ),

      // ── ListTile ───────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: borderRadiusSmall),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: c.textSecondary,
        ),
        tileColor: Colors.transparent,
        selectedTileColor: c.primaryContainer.withAlpha(80),
      ),

      // ── Icon ───────────────────────────────────────────────────────
      iconTheme: IconThemeData(color: c.textSecondary, size: 22),

      // ── Tooltip ────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isLight ? c.textPrimary : c.surfaceVariant,
          borderRadius: borderRadiusSmall,
        ),
        textStyle: TextStyle(
          color: isLight ? c.surface : c.textPrimary,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ── Switch / Checkbox / Radio ──────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.onPrimary;
          return c.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.primary;
          return c.surfaceVariant;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return c.border;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(c.onPrimary),
        side: BorderSide(color: c.border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.primary;
          return c.border;
        }),
      ),

      // ── Navigation bar ─────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: c.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: c.primary, size: 24);
          }
          return IconThemeData(color: c.textTertiary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: c.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: c.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      // ── Tab bar ────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        indicatorColor: c.primary,
        labelColor: c.primary,
        unselectedLabelColor: c.textTertiary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),

      // ── PopupMenu ──────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: c.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: c.divider, width: 0.5),
        ),
        textStyle: textTheme.bodyMedium,
      ),

      // ── ProgressIndicator ──────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surfaceVariant,
        circularTrackColor: c.surfaceVariant,
        linearMinHeight: 4,
      ),

      // ── Slider ─────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        inactiveTrackColor: c.surfaceVariant,
        thumbColor: c.primary,
        overlayColor: c.primary.withAlpha(30),
        trackHeight: 4,
      ),
    );
  }

  // ── Text theme ───────────────────────────────────────────────────────
  static TextTheme _textTheme(AppColors c) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: c.textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: c.textPrimary,
        height: 1.25,
        letterSpacing: -0.3,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
        height: 1.3,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
        height: 1.35,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
        height: 1.35,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: c.textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: c.textPrimary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: c.textSecondary,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
        height: 1.4,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: c.textSecondary,
        height: 1.4,
        letterSpacing: 0.3,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: c.textTertiary,
        height: 1.4,
        letterSpacing: 0.3,
      ),
    );
  }
}
