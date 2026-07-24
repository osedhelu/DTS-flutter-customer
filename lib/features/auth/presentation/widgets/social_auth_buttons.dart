import 'package:flutter/material.dart';

/// Botones de acceso social con altura y estilo alineados al tema.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.onGoogle,
    this.onApple,
    this.showApple = false,
    this.enabled = true,
  });

  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final bool showApple;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          key: const Key('login_google'),
          onPressed: enabled ? onGoogle : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.onSurface,
            backgroundColor: isDark
                ? scheme.surfaceContainerHighest
                : scheme.surface,
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GoogleMark(),
              SizedBox(width: 10),
              Text('Continuar con Google'),
            ],
          ),
        ),
        if (showApple) ...[
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('login_apple'),
            onPressed: enabled ? onApple : null,
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apple, size: 22),
                SizedBox(width: 10),
                Text('Continuar con Apple'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Marca "G" multicolor sin asset externo.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.08,
      size.width * 0.84,
      size.height * 0.84,
    );

    // Blue arc
    stroke.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.4, 1.8, false, stroke);
    // Green
    stroke.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.4, 1.0, false, stroke);
    // Yellow
    stroke.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.4, 0.7, false, stroke);
    // Red
    stroke.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.1, 0.9, false, stroke);

    final bar = Paint()..color = const Color(0xFF4285F4);
    final cy = size.height * 0.5;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.48, cy - size.height * 0.09, size.width * 0.42, size.height * 0.18),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
