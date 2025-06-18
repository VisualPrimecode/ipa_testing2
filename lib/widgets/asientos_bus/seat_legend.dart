import 'package:flutter/material.dart';

class SeatLegend extends StatelessWidget {
  final Color color;
  final String label;

  const SeatLegend({required this.color, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 14, height: 14, color: color, margin: const EdgeInsets.only(right: 6)),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
