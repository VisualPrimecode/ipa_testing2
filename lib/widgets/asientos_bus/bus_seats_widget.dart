import 'package:flutter/material.dart';
import '../../models/asiento.dart'; // Ajusta el path si es necesario
import 'constans.dart';
import 'seat_legend.dart';
import 'full_seat_grid.dart';
import 'compact_seat_view.dart';

class BusSeatsWidget extends StatefulWidget {
  final List<Asiento> asientos;

  const BusSeatsWidget({
    super.key,
    required this.asientos,
  });

  @override
  State<BusSeatsWidget> createState() => _BusSeatsWidgetState();
}

class _BusSeatsWidgetState extends State<BusSeatsWidget> {
  final Set<String> selected = {};
  bool isCompactView = false;

  List<String> get allSeatIds =>
      widget.asientos.map((a) => a.idAsiento.toString()).toList();

  Set<String> get occupiedSeatIds => widget.asientos
      .where((a) => a.vendido == 1 || a.registrado == 1)
      .map((a) => a.idAsiento.toString())
      .toSet();

  void toggleView() {
    setState(() {
      isCompactView = !isCompactView;
    });
  }

  void onSeatTap(String id) {
    if (occupiedSeatIds.contains(id)) return;

    setState(() {
      if (selected.contains(id)) {
        selected.remove(id);
      } else {
        selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🎫 BusSeatsWidget construido con ${widget.asientos.length} asientos');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
  children: const [
    SeatLegend(color: occupiedColor, label: 'Ocupado'),
    SizedBox(width: 12),
    SeatLegend(color: reservedColor, label: 'Vendido'), // ← Nuevo
    SizedBox(width: 12),
    SeatLegend(color: selectedColor, label: 'Seleccionado'),
    SizedBox(width: 12),
    SeatLegend(color: freeColor, label: 'Libre'),
  ],
),

              TextButton(
                onPressed: toggleView,
                child: Text(isCompactView ? 'Vista Completa' : 'Vista Compacta'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        isCompactView
  ? CompactSeatView(
      asientos: widget.asientos, // Pasa la lista de objetos Asiento
      selected: selected,
    )
  : FullSeatGrid(
      asientos: widget.asientos,
      selected: selected,
      onSeatTap: onSeatTap,
    ),

        if (selected.isNotEmpty && !isCompactView) ...[
          const SizedBox(height: 10),
          Text('Seleccionados: ${selected.join(', ')}'),
          TextButton.icon(
            onPressed: () => setState(() => selected.clear()),
            icon: const Icon(Icons.clear),
            label: const Text('Limpiar selección'),
          ),
        ],
      ],
    );
  }
}
