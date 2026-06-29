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
  // ── Primary (azul médico) ──────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD6E4FF);
  static const Color onPrimaryContainer = Color(0xFF001A41);

  // ── Secondary (azul grisáceo) ──────────────────────────────────────────
  static const Color secondary = Color(0xFF546E7A);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD7E3EB);
  static const Color onSecondaryContainer = Color(0xFF0D1D26);

  // ── Tertiary (teal clínico) ────────────────────────────────────────────
  static const Color tertiary = Color(0xFF00796B);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFB2DFDB);
  static const Color onTertiaryContainer = Color(0xFF002020);

  // ── Superficies ────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFE8E8EC);
  static const Color surfaceBright = Color(0xFFF8F9FC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3F7);
  static const Color surfaceContainer = Color(0xFFEDEDF1);
  static const Color surfaceContainerHigh = Color(0xFFE7E8EC);
  static const Color surfaceContainerHighest = Color(0xFFE1E2E6);
  static const Color onSurface = Color(0xFF1B1B1F);
  static const Color onSurfaceVariant = Color(0xFF44474F);
  static const Color scaffoldBackground = Color(0xFFF6F8FA);

  // ── Bordes ─────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C6D0);

  // ── Semánticos: estados clínicos ───────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFBCF0C0);
  static const Color onSuccessContainer = Color(0xFF002106);

  static const Color warning = Color(0xFFF57F17);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFFE082);
  static const Color onWarningContainer = Color(0xFF3E2800);

  static const Color error = Color(0xFFC62828);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color info = Color(0xFF1565C0);
  static const Color onInfo = Color(0xFFFFFFFF);

  // ── Balance positivo / negativo (para pastillas de sesión) ─────────────
  static const Color balancePositive = Color(0xFF2E7D32);
  static const Color balanceNegative = Color(0xFFC62828);

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
