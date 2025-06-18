import 'package:flutter/material.dart';

class TravelCard extends StatelessWidget {
  final String number;
  final String route;
  final String time;
  final String conductor;
  final VoidCallback? onTap; // <-- nuevo

  const TravelCard({
    super.key,
    required this.number,
    required this.route,
    required this.time,
    required this.conductor,
    this.onTap, // <-- nuevo
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // <-- nuevo
      onTap: onTap,         // <-- nuevo
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(number, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(route),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A0080),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        conductor,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
