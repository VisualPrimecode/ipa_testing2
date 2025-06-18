// utils/chofer_utils.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChoferUtils {
  static Future<int?> mostrarSelectorDeChofer(BuildContext context) async {
    try {
      final conductores = await ApiService.getConductoresActivos();

      return await showModalBottomSheet<int>(
        context: context,
        builder: (context) => ListView(
          children: conductores.map<Widget>((conductor) {
            final nombre = conductor['nombre'];
            final id = conductor['idConductor'];

            return ListTile(
              title: Text(nombre),
              onTap: () => Navigator.pop(context, id),
            );
          }).toList(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar choferes: $e')),
      );
      return null;
    }
  }
}
