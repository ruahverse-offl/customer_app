import 'package:flutter/material.dart';

/// Brand palette — mirrors `new_balan_fe/src/index.css` so the customer app
/// and the marketing site read as one product.
class AppColors {
  // Primary blue (matches FE --primary)
  static const primary = Color(0xFF0056B3);
  static const primaryLight = Color(0xFFE7F3FF);
  static const primaryDark = Color(0xFF004085);

  // Secondary green (matches FE --secondary)
  static const secondary = Color(0xFF28A745);
  static const secondaryLight = Color(0xFFE8F5E9);
  static const secondaryDark = Color(0xFF1E7E34);

  static const accent = Color(0xFF5BC0DE);
  static const danger = Color(0xFFB91C1C);
  static const warning = Color(0xFFD97706);

  // Surfaces
  static const surface = Color(0xFFF9FAFB);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);

  // Text
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF4B5563);
  static const textMuted = Color(0xFF6B7280);

  // Grey ramp (matches FE --gray-*)
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);
}

/// Brand gradients — used by CTAs, hero panels, banners.
class AppGradients {
  static const primary = LinearGradient(
    colors: [Color(0xFF0056B3), Color(0xFF003D82)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const primarySoft = LinearGradient(
    colors: [Color(0xFF0066CC), Color(0xFF0056B3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const secondary = LinearGradient(
    colors: [Color(0xFF28A745), Color(0xFF1E7E34)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const surface = LinearGradient(
    colors: [Color(0xFFF0F7FF), Colors.white, Color(0xFFE8F5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
}

class AppRadius {
  static const sm = 6.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const pill = 9999.0;
}

class AppShadows {
  static List<BoxShadow> sm = [
    const BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static List<BoxShadow> md = [
    const BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4)),
    const BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static List<BoxShadow> lg = [
    const BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10)),
    const BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 4)),
  ];
  static List<BoxShadow> primaryGlow = [
    BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6)),
  ];
  static List<BoxShadow> secondaryGlow = [
    BoxShadow(color: AppColors.secondary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6)),
  ];
}

/// Motion tokens — match `--ease-smooth` and `--ease-spring` from the FE.
class AppMotion {
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 450);
  static const smooth = Cubic(0.4, 0.0, 0.2, 1.0);
  static const spring = Cubic(0.34, 1.56, 0.64, 1.0);
}

class AppTextStyles {
  static const _outfitBold = TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, letterSpacing: -0.2);
  static const _outfitExtra = TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800, letterSpacing: -0.3);
  static const _interRegular = TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400);
  static const _interSemiBold = TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600);

  static final display = _outfitExtra.copyWith(fontSize: 32, height: 1.1);
  static final h1 = _outfitBold.copyWith(fontSize: 28, height: 1.2);
  static final h2 = _outfitBold.copyWith(fontSize: 22, height: 1.3);
  static final h3 = _outfitBold.copyWith(fontSize: 18, height: 1.4);
  static final bodyLarge = _interRegular.copyWith(fontSize: 16, height: 1.55);
  static final body = _interRegular.copyWith(fontSize: 14, height: 1.55);
  static final bodySmall = _interRegular.copyWith(fontSize: 12, height: 1.5);
  static final labelLarge = _interSemiBold.copyWith(fontSize: 16);
  static final label = _interSemiBold.copyWith(fontSize: 14);
  static final labelSmall = _interSemiBold.copyWith(fontSize: 12);
  static final caption = _interRegular.copyWith(fontSize: 11, height: 1.4);
  static final overline = _interSemiBold.copyWith(fontSize: 10, letterSpacing: 0.8, height: 1.4);
}

// Dark-mode equivalents for surfaces/text — used anywhere an explicit
// container color is needed that should adapt to dark mode.
class AppColorsDark {
  static const primary = Color(0xFF60A5FA);
  static const primaryLight = Color(0xFF1E3A5F);
  static const secondary = Color(0xFF4ADE80);
  static const danger = Color(0xFFF87171);
  static const warning = Color(0xFFFBBF24);
  static const surface = Color(0xFF0F172A);
  static const card = Color(0xFF1E293B);
  static const border = Color(0xFF334155);
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColorsDark.primary,
      primary: AppColorsDark.primary,
      secondary: AppColorsDark.secondary,
      surface: AppColorsDark.card,
      error: AppColorsDark.danger,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColorsDark.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColorsDark.card,
      foregroundColor: AppColorsDark.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: AppColorsDark.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.primary,
        foregroundColor: AppColorsDark.surface,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: AppTextStyles.labelLarge,
        elevation: 2,
        shadowColor: AppColorsDark.primary.withOpacity(0.4),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorsDark.primary,
        side: const BorderSide(color: AppColorsDark.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: AppTextStyles.label,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsDark.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColorsDark.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColorsDark.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColorsDark.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColorsDark.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: AppTextStyles.body.copyWith(color: AppColorsDark.textSecondary),
      hintStyle: AppTextStyles.body.copyWith(color: AppColorsDark.textMuted),
    ),
    cardTheme: CardThemeData(
      color: AppColorsDark.card,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColorsDark.border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColorsDark.border, thickness: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColorsDark.card,
      indicatorColor: AppColorsDark.primary.withOpacity(0.18),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.caption.copyWith(
            color: AppColorsDark.primary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          );
        }
        return AppTextStyles.caption.copyWith(color: AppColorsDark.textMuted, fontSize: 11);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColorsDark.primary, size: 24);
        }
        return const IconThemeData(color: AppColorsDark.textMuted, size: 24);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColorsDark.card,
      contentTextStyle: AppTextStyles.body.copyWith(color: AppColorsDark.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: AppColors.card,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: AppTextStyles.labelLarge,
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.35),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: AppTextStyles.label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.label,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      floatingLabelStyle: AppTextStyles.label.copyWith(color: AppColors.primary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.06),
      surfaceTintColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.primary.withOpacity(0.12),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.08),
      surfaceTintColor: AppColors.card,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          );
        }
        return AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return const IconThemeData(color: AppColors.textMuted, size: 24);
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryLight,
      side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
      labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.gray900,
      contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      actionTextColor: AppColors.accent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      titleTextStyle: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
      contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      showDragHandle: true,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.gray200,
      circularTrackColor: AppColors.gray200,
    ),
    splashFactory: InkRipple.splashFactory,
  );
}
