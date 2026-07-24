import 'package:flutter/material.dart';

/// Logo DTS (assets/images/logo.png) para AppBars / auth.
class DtsBrandMark extends StatelessWidget {
  const DtsBrandMark({super.key, this.size = 40, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    // El asset ya incluye el wordmark "TS"; si showWordmark es true
    // mostramos el logo completo un poco más ancho.
    final width = showWordmark ? size * 1.35 : size;

    return Image.asset(
      'assets/images/logo.png',
      width: width,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => SizedBox(
        width: size,
        height: size,
        child: ColoredBox(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
