import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PasajerosPorDia {
  final int dia;
  final double cantidad;
  final double totalVendido;

  PasajerosPorDia({
    required this.dia,
    required this.cantidad,
    required this.totalVendido,
  });
}

class ResumenBarChart extends StatelessWidget {
  final List<PasajerosPorDia> datos;

  const ResumenBarChart({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: datos.length * 30, // Ajusta según sea necesario
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barGroups: datos
                .map(
                  (d) => BarChartGroupData(
                    x: d.dia,
                    barRods: [
                      BarChartRodData(
                        toY: d.cantidad,
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ],
                  ),
                )
                .toList(),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 40,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final int dia = value.toInt();
                    if (dia < 1 || dia > 31) return const SizedBox.shrink();
                    return Text(
                      dia.toString().padLeft(2, '0'),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                  interval: 1,
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final dato = datos.firstWhere((d) => d.dia == group.x.toInt());
                  return BarTooltipItem(
                    'Día ${dato.dia.toString().padLeft(2, '0')}\n'
                    'Pasajeros: ${dato.cantidad.toStringAsFixed(0)}\n'
                    'Total vendido: \$${dato.totalVendido.toStringAsFixed(0)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
