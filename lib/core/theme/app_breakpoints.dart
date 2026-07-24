/// Anchos máximos para layouts adaptativos (phone / tablet).
abstract final class AppBreakpoints {
  /// Formulario de auth centrado en tablets / landscape.
  static const double authFormMaxWidth = 440;

  /// Contenido principal (listas / detalle) en pantallas anchas.
  static const double contentMaxWidth = 720;

  /// Umbral a partir del cual se considera layout "wide".
  static const double tablet = 600;
}
