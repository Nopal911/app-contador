import 'package:flutter/material.dart';
import '../services/tema_service.dart';

/// Botón para cambiar entre tema claro y oscuro.
/// Se puede poner en el AppBar de cualquier pantalla.
class BotonTema extends StatelessWidget {
  final Color? color;
  const BotonTema({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: oscuro ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro',
      icon: Icon(oscuro ? Icons.light_mode : Icons.dark_mode, color: color),
      onPressed: () =>
          TemaService.establecer(oscuro ? ThemeMode.light : ThemeMode.dark),
    );
  }
}
