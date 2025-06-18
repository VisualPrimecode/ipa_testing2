import 'package:flutter/material.dart';

class ResumenCuadro extends StatelessWidget {
  final int totalViajes;
  final int totalPasajeros;
  final int totalProduccion;
  final double totalGastos; // NUEVO

  const ResumenCuadro({
    super.key,
    required this.totalViajes,
    required this.totalPasajeros,
    required this.totalProduccion,
    required this.totalGastos, // NUEVO
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _itemResumen('📅 Total de viajes', totalViajes.toString()),
            _itemResumen('👥 Pasajeros transportados', totalPasajeros.toString()),
            _itemResumen('💰 Producción total', '\$${totalProduccion.toString()}'),
            _itemResumen('💸 Gastos totales', '\$${totalGastos.toStringAsFixed(0)}'), // NUEVO
          ],
        ),
      ),
    );
  }

  Widget _itemResumen(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 16)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
