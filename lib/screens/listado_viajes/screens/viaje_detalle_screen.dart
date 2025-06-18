import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../.././../utils/chofer_utils.dart';
class ViajeDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> viaje;

  const ViajeDetalleScreen({Key? key, required this.viaje}) : super(key: key);

  Future<void> _anularViaje(BuildContext context) async {
    final bool confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar anulación'),
        content: const Text('¿Estás seguro de que deseas anular este viaje?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            child: const Text('Anular'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.anularViaje(idProgramacion: viaje['idProgramacion']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viaje anulado exitosamente')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al anular el viaje: $e')),
      );
    }
  }

  Future<void> _asignarViaje(BuildContext context) async {
  try {
    // 1. Usamos la utilidad para mostrar el selector de chofer
    final int? idSeleccionado = await ChoferUtils.mostrarSelectorDeChofer(context);

    if (idSeleccionado == null) return;

    // 2. Asignar viaje al conductor seleccionado
    final response = await ApiService.asignarViajeAnulado(
      idProgramacion: viaje['idProgramacion'],
      idConductor: idSeleccionado,
    );

    final mensaje = response['message'] ?? 'Viaje asignado exitosamente';
    final idsVenta = response['idsVenta'] ?? [];

    final texto = '$mensaje\nVentas: ${idsVenta.join(', ')}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al asignar el viaje: $e')),
    );
  }
}



  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0080),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0080),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Detalle del viaje',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoTile('ID Programación', '${viaje['idProgramacion']}'),
                _buildInfoTile('Destino', '${viaje['NomDestino']}'),
                _buildInfoTile('Hora', '${viaje['hora']}'),
                _buildInfoTile('Conductor', viaje['nombreConductor'] ?? 'Sin conductor'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _anularViaje(context),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Anular viaje'),
                        style: ElevatedButton.styleFrom(
  backgroundColor: Colors.red, // o Colors.green
  foregroundColor: Colors.white, // <-- ESTO hace que el texto (y el ícono) sea blanco
  padding: const EdgeInsets.symmetric(vertical: 14),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
),

                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _asignarViaje(context),
                        icon: const Icon(Icons.assignment_ind),
                        label: const Text('Asignar viaje'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white, // <-- ESTO hace que el texto (y el ícono) sea blanco

                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
