import 'package:flutter/material.dart';

import 'constants.dart';

abstract final class AppTheme {
  static const _baseTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 40,
      fontWeight: FontWeight.w700,
      height: 1.05,
      letterSpacing: -1.2,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.9,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.4,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.5,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.4,
    ),
  );

  static ThemeData get light {
    const postFinanceYellow = Color(0xFFFFCC00);
    const ink = Color(0xFF171717);
    const muted = Color(0xFF5F6368);
    const line = Color(0xFFD8D8D8);
    const lineSoft = Color(0xFFECECEC);
    const background = Color(0xFFF7F5F2);
    const surfaceMuted = Color(0xFFF9F9F9);
    const positive = Color(0xFF2E7D32);
    const negative = Color(0xFFB3261E);

    const colorScheme = ColorScheme.light(
      primary: postFinanceYellow,
      secondary: ink,
      onPrimary: ink,
      onSecondary: Colors.white,
      onSurface: ink,
      outline: line,
      outlineVariant: lineSoft,
      surfaceContainerHighest: surfaceMuted,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      background: background,
      line: line,
      lineSoft: lineSoft,
      ink: ink,
      muted: muted,
      positive: positive,
      negative: negative,
      brightness: Brightness.light,
    );
  }

  static ThemeData get dark {
    const postFinanceYellow = Color(0xFFFFCC00);
    const ink = Color(0xFFF6F6F4);
    const muted = Color(0xFFB7B7B4);
    const line = Color(0xFF323232);
    const lineSoft = Color(0xFF252525);
    const background = Color(0xFF101010);
    const surface = Color(0xFF181818);
    const surfaceMuted = Color(0xFF242424);
    const positive = Color(0xFF5AD18A);
    const negative = Color(0xFFFF7A70);

    const colorScheme = ColorScheme.dark(
      primary: postFinanceYellow,
      secondary: ink,
      surface: surface,
      onSurface: ink,
      outline: line,
      outlineVariant: lineSoft,
      surfaceContainerHighest: surfaceMuted,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      background: background,
      line: line,
      lineSoft: lineSoft,
      ink: ink,
      muted: muted,
      positive: positive,
      negative: negative,
      brightness: Brightness.dark,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color background,
    required Color line,
    required Color lineSoft,
    required Color ink,
    required Color muted,
    required Color positive,
    required Color negative,
    required Brightness brightness,
  }) {
    final textTheme = _baseTextTheme
        .apply(bodyColor: ink, displayColor: ink)
        .copyWith(
          bodyMedium: _baseTextTheme.bodyMedium?.copyWith(color: muted),
          labelMedium: _baseTextTheme.labelMedium?.copyWith(color: muted),
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkRipple.splashFactory,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppLayout.cardRadius,
          side: BorderSide(color: line),
        ),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: AppLayout.inputRadius,
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppLayout.inputRadius,
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppLayout.inputRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppLayout.inputRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppLayout.inputRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: lineSoft,
          disabledForegroundColor: muted,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: AppLayout.inputRadius,
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: lineSoft,
          disabledForegroundColor: muted,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: AppLayout.inputRadius,
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: AppLayout.inputRadius,
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.titleMedium,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.surface,
        disabledColor: colorScheme.surfaceContainerHighest,
        secondarySelectedColor: colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: textTheme.labelLarge ?? const TextStyle(),
        secondaryLabelStyle: textTheme.labelLarge ?? const TextStyle(),
        brightness: brightness,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppLayout.inputRadius,
          side: BorderSide(color: line),
        ),
        side: BorderSide(color: line),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.primary,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: colorScheme.onPrimary,
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.24);
          }
          return colorScheme.outlineVariant;
        }),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      extensions: <ThemeExtension<dynamic>>[
        _StatusColors(success: positive, danger: negative),
      ],
    );
  }
}

class _StatusColors extends ThemeExtension<_StatusColors> {
  const _StatusColors({required this.success, required this.danger});

  final Color success;
  final Color danger;

  @override
  _StatusColors copyWith({Color? success, Color? danger}) {
    return _StatusColors(
      success: success ?? this.success,
      danger: danger ?? this.danger,
    );
  }

  @override
  _StatusColors lerp(ThemeExtension<_StatusColors>? other, double t) {
    if (other is! _StatusColors) {
      return this;
    }

    return _StatusColors(
      success: Color.lerp(success, other.success, t) ?? success,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
    );
  }
}

extension StatusColorsThemeX on ThemeData {
  Color get successColor {
    return extension<_StatusColors>()?.success ?? colorScheme.primary;
  }

  Color get dangerColor {
    return extension<_StatusColors>()?.danger ?? colorScheme.error;
  }
}
