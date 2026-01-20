import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Material Design 3)
  static const Color primary = Color(0xFFFF9500); // Orange
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFFE0B2);
  static const Color onPrimaryContainer = Color(0xFF2E1500);

  // Secondary Colors
  static const Color secondary = Color(0xFF03DAC6); // Teal
  static const Color onSecondary = Color(0xFF000000);
  static const Color secondaryContainer = Color(0xFFB2EBF2);
  static const Color onSecondaryContainer = Color(0xFF002020);

  // Tertiary Colors
  static const Color tertiary = Color(0xFFFF6F00); // Orange
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFE0B2);
  static const Color onTertiaryContainer = Color(0xFF2E1500);

  // Error Colors
  static const Color error = Color(0xFFB00020);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFCD8DF);
  static const Color onErrorContainer = Color(0xFF410002);

  // Success Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFC8E6C9);
  static const Color onSuccessContainer = Color(0xFF1B5E20);

  // Warning Colors
  static const Color warning = Color(0xFFFFC107);
  static const Color onWarning = Color(0xFF000000);
  static const Color warningContainer = Color(0xFFFFECB3);
  static const Color onWarningContainer = Color(0xFF3E2723);

  // Info Colors
  static const Color info = Color(0xFF2196F3);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color infoContainer = Color(0xFFBBDEFB);
  static const Color onInfoContainer = Color(0xFF0D47A1);

  // Surface Colors (Light)
  static const Color surfaceLight = Color(0xFFFFFBFE);
  static const Color onSurfaceLight = Color(0xFF1C1B1F);
  static const Color surfaceVariantLight = Color(0xFFE7E0EC);
  static const Color onSurfaceVariantLight = Color(0xFF49454F);

  // Surface Colors (Dark)
  static const Color surfaceDark = Color(0xFF1C1B1F);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);
  static const Color surfaceVariantDark = Color(0xFF49454F);
  static const Color onSurfaceVariantDark = Color(0xFFCAC4D0);

  // Background Colors
  static const Color backgroundLight = Color(0xFFFFFBFE);
  static const Color onBackgroundLight = Color(0xFF1C1B1F);
  static const Color backgroundDark = Color(0xFF1C1B1F);
  static const Color onBackgroundDark = Color(0xFFE6E1E5);

  // Outline Colors
  static const Color outlineLight = Color(0xFF79747E);
  static const Color outlineVariantLight = Color(0xFFCAC4D0);
  static const Color outlineDark = Color(0xFF938F99);
  static const Color outlineVariantDark = Color(0xFF49454F);

  // Shadow & Scrim
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);

  // Inverse Colors
  static const Color inverseSurfaceLight = Color(0xFF313033);
  static const Color inverseOnSurfaceLight = Color(0xFFF4EFF4);
  static const Color inversePrimaryLight = Color(0xFFBBC7FF);

  static const Color inverseSurfaceDark = Color(0xFFE6E1E5);
  static const Color inverseOnSurfaceDark = Color(0xFF313033);
  static const Color inversePrimaryDark = Color(0xFF415AA9);

  // Semantic Colors for App Features
  static const Color eventColor = Color(0xFF2196F3);
  static const Color forumColor = Color(0xFF9C27B0);
  static const Color certificateColor = Color(0xFFFF9800);
  static const Color resourceColor = Color(0xFF4CAF50);
  static const Color aiColor = Color(0xFF00BCD4);
  static const Color achievementColor = Color(0xFFFFEB3B);

  // Status Colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color away = Color(0xFFFFC107);
  static const Color busy = Color(0xFFF44336);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF03DAC6), Color(0xFF018786)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shimmer Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF424242);
  static const Color shimmerHighlightDark = Color(0xFF616161);
}
