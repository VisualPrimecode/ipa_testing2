import 'package:flutter/material.dart';
import 'constans.dart';
import 'seat_box.dart';
import '../../models/asiento.dart';

class FullSeatGrid extends StatelessWidget {
  final List<Asiento> asientos;
  final Set<String> selected;
  final void Function(String id) onSeatTap;

  const FullSeatGrid({
    required this.asientos,
    required this.selected,
    required this.onSeatTap,
    super.key,
  });

  static const int columnsPerRow = 5;
  static const int aisleColumnIndex = 2;

  int computeRealIndex(int index) {
    final row = index ~/ columnsPerRow;
    final column = index % columnsPerRow;
    final seatsSkippedByRow = row;
    final seatsSkippedByColumn = column > aisleColumnIndex ? 1 : 0;
    return index - seatsSkippedByRow - seatsSkippedByColumn;
  }

  bool isAislePosition(int index) {
    return index % columnsPerRow == aisleColumnIndex;
  }

  int computeItemCount() {
    final totalSeats = asientos.length;
    final seatsPerRow = columnsPerRow - 1;
    final requiredRows = (totalSeats / seatsPerRow).ceil();
    return requiredRows * columnsPerRow;
  }

  Color getSeatColor(Asiento asiento) {
  if (asiento.registrado) return occupiedColor;         // Ocupado físicamente
  if (asiento.vendido) return reservedColor;             // Vendido pero no registrado
  if (selected.contains(asiento.idAsiento)) return selectedColor; // Seleccionado
  return freeColor;                                      // Libre
}


  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: computeItemCount(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnsPerRow,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, index) {
        if (isAislePosition(index)) {
          return const SizedBox.shrink(); // Pasillo
        }

        final realIndex = computeRealIndex(index);
        if (realIndex >= asientos.length) {
          return const SizedBox.shrink(); // Vacío fuera de rango
        }

        final asiento = asientos[realIndex];
        final idStr = asiento.idAsiento;
        final color = getSeatColor(asiento);

        return SeatBox(
          id: idStr,
          color: color,
          isCompact: false,
          onTap: asiento.registrado ? null : () => onSeatTap(idStr),
        );
      },
    );
  }
}
