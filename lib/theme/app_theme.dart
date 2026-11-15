import 'package:flutter/material.dart';

import '../models/enums.dart';

class EldenColors {
  static const Color teal = Color(0xFF1B6B6B);
  static const Color tealDark = Color(0xFF134F4F);
  static const Color sand = Color(0xFFF7F4EE);
  static const Color mist = Color(0xFFF3F6F8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1C2A2A);
  static const Color muted = Color(0xFF5C6B6B);
  static const Color success = Color(0xFF2E7D4F);
  static const Color warning = Color(0xFFB7791F);
  static const Color discrepancy = Color(0xFFB5473A);
  static const Color pending = Color(0xFF3D6B99);
}

class AppTheme {
  static ThemeData forRole(AppRole? role) {
    final isPatient = role == AppRole.patient;
    final isDoctor = role == AppRole.doctor;
    final surface = isPatient
        ? EldenColors.sand
        : (isDoctor ? const Color(0xFFF4F7FA) : EldenColors.mist);
    final primary = isDoctor ? const Color(0xFF0F5A5A) : EldenColors.teal;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          secondary: isDoctor ? const Color(0xFF0A3D3D) : EldenColors.tealDark,
          surface: surface,
          onSurface: EldenColors.ink,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: EldenColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: EldenColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: isPatient ? 24 : 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: EldenColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: EldenColors.teal.withValues(alpha: 0.08)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(64, isPatient ? 56 : 48),
          textStyle: TextStyle(
            fontSize: isPatient ? 18 : 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(64, isPatient ? 56 : 48),
          textStyle: TextStyle(
            fontSize: isPatient ? 18 : 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: isPatient ? 80 : 72,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: isPatient ? 14 : 12, fontWeight: FontWeight.w600),
        ),
      ),
    );

    if (!isPatient) return base;

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: EldenColors.ink,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: 20,
          height: 1.35,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 18,
          height: 1.35,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontSize: 18),
      ),
    );
  }
}

class StatusPalette {
  static Color color(OverallTaskStatus status) => switch (status) {
    OverallTaskStatus.verified ||
    OverallTaskStatus.completed => EldenColors.success,
    OverallTaskStatus.verifiedNotCompleted ||
    OverallTaskStatus.notCompleted => EldenColors.warning,
    OverallTaskStatus.discrepancy => EldenColors.discrepancy,
    OverallTaskStatus.awaitingConfirmation => EldenColors.pending,
  };

  static IconData icon(OverallTaskStatus status) => switch (status) {
    OverallTaskStatus.verified ||
    OverallTaskStatus.completed => Icons.check_circle_rounded,
    OverallTaskStatus.verifiedNotCompleted ||
    OverallTaskStatus.notCompleted => Icons.cancel_rounded,
    OverallTaskStatus.discrepancy => Icons.warning_rounded,
    OverallTaskStatus.awaitingConfirmation => Icons.hourglass_top_rounded,
  };
}
