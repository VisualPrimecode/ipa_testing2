import 'package:flutter/material.dart';
import 'constans.dart';

class SeatBox extends StatelessWidget {
  final String id;
  final Color color;
  final bool isCompact;
  final VoidCallback? onTap;

  const SeatBox({
    required this.id,
    required this.color,
    this.onTap,
    this.isCompact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(isCompact ? 4 : 10),
          border: Border.all(color: Colors.black12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 1)],
        ),
        alignment: Alignment.center,
        child: FittedBox(
  fit: BoxFit.scaleDown,
  child: FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    id,
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
    softWrap: false,
    style: TextStyle(
      color: color == occupiedColor ? Colors.white : Colors.black,
      fontSize: isCompact ? 10 : 12,
      fontWeight: FontWeight.bold,
    ),
  ),
),

),

      ),
    );
  }
}
