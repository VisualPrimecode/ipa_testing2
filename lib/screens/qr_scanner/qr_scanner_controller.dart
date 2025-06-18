import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';

class QRScannerController extends ChangeNotifier {
  final String tripId;
  final String tripDate;
  final String tripTime;
  final String userId;  // Ahora viene por constructor
  final MobileScannerController scannerController = MobileScannerController();

  QRScannerController({
    required this.tripId,
    required this.tripDate,
    required this.tripTime,
    required this.userId,  // obligatorio
  });
  String? qrText;
  bool _isScanned = false;
  String? asientoValidado;
  String? scanErrorMessage;

  void onDetect(BarcodeCapture capture) async {
    if (_isScanned) return;

    final Barcode barcode = capture.barcodes.first;
    final String? code = barcode.rawValue;
    

    if (code != null) {
      qrText = code;
      _isScanned = true;
      scannerController.stop();
      notifyListeners();

      try {
  final respuesta = await ApiService.enviarCodigoQR(
    code,
    tripId,
    tripDate,
    tripTime,
    userId,
  );

  if (respuesta['error'] == true) {
    if (respuesta['detalles'] != null && respuesta['detalles'] is List) {
      // Unir los detalles en un solo string legible
      scanErrorMessage = (respuesta['detalles'] as List).join('\n');
    } else {
      scanErrorMessage = respuesta['message'] ?? 'Error desconocido';
    }
    asientoValidado = null;
  } else if (respuesta['asiento'] != null) {
    asientoValidado = respuesta['asiento'];
    scanErrorMessage = null;
  } else {
    scanErrorMessage = respuesta['message'] ?? 'Código inválido';
    asientoValidado = null;
  }

  notifyListeners();
} catch (e) {
  scanErrorMessage = "Error de red: ${e.toString()}";
  notifyListeners();
}
    }
  }

  void resetScan() {
    _isScanned = false;
    qrText = null;
    scanErrorMessage = null;
    asientoValidado = null;
    scannerController.start();
    notifyListeners();
  }

  void disposeController() {
    scannerController.dispose();
  }
}
