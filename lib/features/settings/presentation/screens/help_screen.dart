import 'package:flutter/material.dart';

import '../../../../core/widgets/widgets.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const faqs = [
      (
        '¿Cómo hago un pedido?',
        'Elige un comercio abierto, agrega productos al carrito y confirma en checkout con tu dirección.'
      ),
      (
        '¿Puedo seguir al conductor?',
        'Sí. En Pedidos abre un pedido activo y toca Ver en mapa.'
      ),
      (
        '¿Cómo contacto soporte?',
        'Desde Ajustes → Soporte o escribe a soporte@dtsdelivery.com.'
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DtsSectionHeader(title: 'Preguntas frecuentes'),
          ...faqs.map(
            (f) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                title: Text(f.$1),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(f.$2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
