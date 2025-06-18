import 'package:flutter/material.dart';

class QRScannerOverlay extends StatelessWidget {
  const QRScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final scanSize = screenWidth * 0.7;
        final scanLeft = (screenWidth - scanSize) / 2;
        final scanTop = (screenHeight - scanSize) / 2;

        return Stack(
          children: [
            // Parte superior del overlay
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: scanTop,
              child: Container(color: Colors.black54),
            ),

            // Parte izquierda del overlay
            Positioned(
              left: 0,
              top: scanTop,
              width: scanLeft,
              height: scanSize,
              child: Container(color: Colors.black54),
            ),

            // Parte derecha del overlay
            Positioned(
              right: 0,
              top: scanTop,
              width: scanLeft,
              height: scanSize,
              child: Container(color: Colors.black54),
            ),

            // Parte inferior del overlay
            Positioned(
              left: 0,
              bottom: 0,
              right: 0,
              height: scanTop,
              child: Container(color: Colors.black54),
            ),

            // Marco blanco del área de escaneo
            Positioned(
              left: scanLeft,
              top: scanTop,
              width: scanSize,
              height: scanSize,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
