import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0056B3);
  static const accent = Color(0xFF0066CC);
  static const secondary = Color(0xFF28A745);
  static const danger = Color(0xFFB91C1C);
  static const warning = Color(0xFFD97706);
  static const surface = Color(0xFFF8FAFC);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const gray50 = Color(0xFFF8FAFC);
  static const gray100 = Color(0xFFF1F5F9);
  static const gray200 = Color(0xFFE2E8F0);
  static const gray300 = Color(0xFFCBD5E1);
  static const gray600 = Color(0xFF475569);
  static const gray900 = Color(0xFF0F172A);
}

class AppTextStyles {
  static const _outfitBold = TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700);
  static const _interRegular = TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400);
  static const _interSemiBold = TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600);

  static final h1 = _outfitBold.copyWith(fontSize: 28, color: AppColors.textPrimary, height: 1.2);
  static final h2 = _outfitBold.copyWith(fontSize: 22, color: AppColors.textPrimary, height: 1.3);
  static final h3 = _outfitBold.copyWith(fontSize: 18, color: AppColors.textPrimary, height: 1.4);
  static final bodyLarge = _interRegular.copyWith(fontSize: 16, color: AppColors.textPrimary, height: 1.5);
  static final body = _interRegular.copyWith(fontSize: 14, color: AppColors.textPrimary, height: 1.5);
  static final bodySmall = _interRegular.copyWith(fontSize: 12, color: AppColors.textSecondary, height: 1.5);
  static final labelLarge = _interSemiBold.copyWith(fontSize: 16, color: AppColors.textPrimary);
  static final label = _interSemiBold.copyWith(fontSize: 14, color: AppColors.textPrimary);
  static final labelSmall = _interSemiBold.copyWith(fontSize: 12, color: AppColors.textSecondary);
  static final caption = _interRegular.copyWith(fontSize: 11, color: AppColors.textMuted, height: 1.4);
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
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: AppColors.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.label,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}
