import 'package:flutter/material.dart';
import 'constans.dart';
import 'seat_box.dart';
import '../../models/asiento.dart';
class CompactSeatView extends StatelessWidget {
  final List<Asiento> asientos; // Cambiado de List<String> a List<Asiento>
  final Set<String> selected;

  const CompactSeatView({
    required this.asientos,
    required this.selected,
    super.key,
  });

  static const int seatsPerRow = 4;
  static const double aisleSpacing = 16.0;
  static const double rowSpacing = 2.0;

  Color getSeatColor(Asiento asiento) {
    // Si el asiento está registrado, lo marcamos como ocupado
    if (asiento.registrado) return occupiedColor;
    // Si el asiento está vendido pero no registrado, lo marcamos como "Vendido"
    if (asiento.vendido) return reservedColor; // Color para vendido pero no registrado
    // Si está seleccionado, se marca como seleccionado
    if (selected.contains(asiento.idAsiento)) return selectedColor;
    // Si no está vendido ni registrado, lo marcamos como libre
    return freeColor;
  }

  Widget buildSeatRow(List<Asiento> group) {
    final leftSide = group.length >= 2 ? group.sublist(0, 2) : group;
    final rightSide = group.length == 4 ? group.sublist(2, 4) : [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: rowSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...leftSide.map((asiento) => SeatBox(id: asiento.idAsiento, color: getSeatColor(asiento), isCompact: true)),
          if (rightSide.isNotEmpty) const SizedBox(width: aisleSpacing),
          ...rightSide.map((asiento) => SeatBox(id: asiento.idAsiento, color: getSeatColor(asiento), isCompact: true)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < asientos.length; i += seatsPerRow) {
      final group = asientos.skip(i).take(seatsPerRow).toList();
      rows.add(buildSeatRow(group));
    }

    return Column(children: rows);
  }
}
