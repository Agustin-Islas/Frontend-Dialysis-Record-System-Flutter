import 'package:flutter/material.dart';

/// Paleta de colores semántica para aplicación médica.
///
/// Prioriza la comunicación de estados clínicos:
/// - Azul  → información / primario
/// - Verde → correcto / completado
/// - Ámbar → advertencia
/// - Rojo  → error / alerta crítica
/// - Gris  → información secundaria
abstract final class AppColors {
  // ── Primary (azul médico vibrante) ──────────────────────────────────────────────
  static const Color primary = Color(0xFF005EB8);
  static const Color primaryLight = Color(0xFF4DA1FF);
  static const Color primaryDark = Color(0xFF00478D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFC8DAFF);
  static const Color onPrimaryContainer = Color(0xFF001B3D);

  // ── Secondary (Teal / Verde Azulado) ──────────────────────────────────────────
  static const Color secondary = Color(0xFF00A3AD);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF7AF1FC);
  static const Color onSecondaryContainer = Color(0xFF002022);

  // ── Tertiary (Teal claro para estados estables) ────────────────────────────────────────────
  static const Color tertiary = Color(0xFFE0F2F1);
  static const Color onTertiary = Color(0xFF004D40);
  static const Color tertiaryContainer = Color(0xFFB2DFDB);
  static const Color onTertiaryContainer = Color(0xFF002020);

  // ── Superficies (Medical Slate) ────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF8FAFC);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF9FAFB);
  static const Color surfaceContainer = Color(0xFFF8FAFC);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);
  static const Color surfaceContainerHighest = Color(0xFFD1D5DB);
  static const Color onSurface = Color(0xFF111827);
  static const Color onSurfaceVariant = Color(0xFF424752);
  static const Color scaffoldBackground = Color(0xFFF8FAFC);

  // ── Bordes ─────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF727783);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  // ── Semánticos: estados clínicos ───────────────────────────────────────
  static const Color success = Color(0xFF00A3AD);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFE0F2F1);
  static const Color onSuccessContainer = Color(0xFF004D40);

  static const Color warning = Color(0xFFF57F17);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFFE082);
  static const Color onWarningContainer = Color(0xFF3E2800);

  static const Color error = Color(0xFFD32F2F);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color info = Color(0xFF005EB8);
  static const Color onInfo = Color(0xFFFFFFFF);

  // ── Balance positivo / negativo (para pastillas de sesión) ─────────────
  static const Color balancePositive = Color(0xFF00A3AD);
  static const Color balanceNegative = Color(0xFFD32F2F);

  // ── Light ColorScheme ──────────────────────────────────────────────────
  static ColorScheme get lightColorScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    surfaceDim: surfaceDim,
    surfaceBright: surfaceBright,
  );
}
