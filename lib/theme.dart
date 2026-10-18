import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens do DESIGN.MD (Evergreen Concierge).
abstract final class AppColors {
  static const primary = Color(0xFF0C3B31);
  static const primaryDeep = Color(0xFF0A2E22);
  static const primaryRaised = Color(0xFF0A4137);
  static const secondary = Color(0xFF85A7A0);
  static const tertiary = Color(0xFFE3F124);
  static const tertiaryHover = Color(0xFFD2E01A);
  static const neutral = Color(0xFFFCF6EA);
  static const surfaceMint = Color(0xFFE8F4F0);
  static const surfaceLimeWash = Color(0xFFE5EFB2);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const onPrimary = Color(0xFFE3FDFA);
  static const onPrimaryMuted = Color(0xFFC5D9D5);
  static const onSurface = Color(0xFF112A26);
  static const onSurfaceMuted = Color(0xFF5E7A74);
  static const onTertiary = Color(0xFF0C3B31);
  static const inputBorder = Color(0xFFBFC6C6);
  static const error = Color(0xFFB3261E);
}

abstract final class AppRadius {
  static const sm = 4.0;
  static const md = 8.0;
  static const xl = 24.0;
}

const chipShadow = [
  BoxShadow(color: Color(0x1F0C3B31), blurRadius: 24, offset: Offset(0, 8)),
];

TextStyle _font(
  double size,
  FontWeight weight,
  double height, [
  double letterSpacingEm = 0,
]) => GoogleFonts.instrumentSans(
  fontSize: size,
  fontWeight: weight,
  height: height,
  letterSpacing: size * letterSpacingEm,
);

abstract final class AppText {
  static final display = _font(40, FontWeight.w500, 1.05, -0.03);
  static final headlineLg = _font(30, FontWeight.w500, 1.1, -0.025);
  static final headlineMd = _font(22, FontWeight.w500, 1.15, -0.02);
  static final bodyLg = _font(16, FontWeight.w400, 1.55);
  static final bodyMd = _font(14, FontWeight.w400, 1.55);
  static final bodySm = _font(12, FontWeight.w400, 1.5);
  static final labelLg = _font(18, FontWeight.w500, 1.3);
  static final labelMd = _font(14, FontWeight.w500, 1.2);
  static final labelSm = _font(11, FontWeight.w500, 1.2);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      surface: AppColors.neutral,
      onSurface: AppColors.onSurface,
      outline: AppColors.secondary,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.neutral,
  );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.sm),
    borderSide: BorderSide(color: c, width: w),
  );

  return base.copyWith(
    textTheme: GoogleFonts.instrumentSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.onSurface,
      displayColor: AppColors.primaryDeep,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceCard,
      // Sem o véu cinza do M3 no hover/foco: o campo continua branco e o
      // foco é indicado pela borda evergreen.
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      errorStyle: AppText.bodySm.copyWith(color: AppColors.error, height: 1.3),
      helperStyle: AppText.bodySm.copyWith(
        color: AppColors.onSurfaceMuted,
        height: 1.3,
      ),
      errorMaxLines: 2,
      helperMaxLines: 2,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      hintStyle: AppText.bodyLg.copyWith(
        color: AppColors.onSurfaceMuted.withValues(alpha: 0.6),
      ),
      labelStyle: AppText.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
      floatingLabelStyle: AppText.bodyMd.copyWith(color: AppColors.primary),
      border: border(AppColors.inputBorder),
      enabledBorder: border(AppColors.inputBorder),
      focusedBorder: border(AppColors.primary, 1.5),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 1.5),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      side: const BorderSide(color: AppColors.secondary, width: 1.5),
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
      ),
      checkColor: const WidgetStatePropertyAll(AppColors.tertiary),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: AppColors.neutral,
      dialBackgroundColor: AppColors.surfaceMint,
      hourMinuteColor: AppColors.surfaceMint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primary,
      contentTextStyle: AppText.bodyMd.copyWith(color: AppColors.onPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.neutral,
      showDragHandle: true,
      dragHandleColor: AppColors.secondary,
    ),
  );
}
