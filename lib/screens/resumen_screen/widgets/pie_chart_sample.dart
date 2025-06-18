import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ResumenPieData {
  final double valor;
  final String titulo;
  final Color color;

  ResumenPieData({
    required this.valor,
    required this.titulo,
    required this.color,
  });
}

class ResumenPieChart extends StatelessWidget {
  final List<ResumenPieData> datos;
  final double centerSpaceRadius;
  final double sectionsSpace;

  const ResumenPieChart({
    super.key,
    required this.datos,
    this.centerSpaceRadius = 40,
    this.sectionsSpace = 2,
  });

  @override
  Widget build(BuildContext context) {
    final double total = datos.fold(0, (sum, d) => sum + d.valor);

    return SizedBox(
      height: 250, // altura fija como antes, para no romper el layout
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Pie chart
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: centerSpaceRadius,
                      sectionsSpace: sectionsSpace,
                      sections: datos
                          .map(
                            (d) => PieChartSectionData(
                              value: d.valor,
                              color: d.color,
                              title: '',
                              showTitle: false,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),

                // Leyenda
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: datos.map((d) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(width: 12, height: 12, color: d.color),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${d.titulo}  \$${d.valor.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.fade,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Total debajo
          const SizedBox(height: 4),
          Text(
            'Total gastos: \$${total.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
