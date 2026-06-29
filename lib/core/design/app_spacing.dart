/// Consistent spacing scale used across the entire application.
///
/// Based on a 4px grid for pixel-perfect alignment.
abstract final class AppSpacing {
  /// 4 dp
  static const double xs = 4;

  /// 8 dp
  static const double sm = 8;

  /// 12 dp
  static const double md = 12;

  /// 16 dp
  static const double lg = 16;

  /// 20 dp
  static const double xl = 20;

  /// 24 dp
  static const double xxl = 24;

  /// 32 dp
  static const double xxxl = 32;

  /// 48 dp — used for section separation
  static const double section = 48;

  /// Minimum tap target size (48x48 dp) for accessibility.
  static const double minTapTarget = 48;

  /// Default card border radius
  static const double cardRadius = 12;

  /// Default input border radius
  static const double inputRadius = 12;

  /// Default pill border radius
  static const double pillRadius = 999;

  /// Default page horizontal padding
  static const double pagePadding = 16;
}
