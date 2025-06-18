import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'qr_scanner_controller.dart';
import '../../widgets/qr_overlay.dart';
import '../../providers/user_provider.dart'; // Ajusta según tu estructura

class QRScannerPage extends StatefulWidget {
  final String tripId;
  final String tripDate;
  final String tripTime;

  const QRScannerPage({
    super.key,
    required this.tripId,
    required this.tripDate,
    required this.tripTime,
  });

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  QRScannerController? _controller;
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_controller == null) {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user != null) {
        _userId = user.id.toString();
        _controller = QRScannerController(
          tripId: widget.tripId,
          tripDate: widget.tripDate,
          tripTime: widget.tripTime,
          userId: _userId!,
        );
        setState(() {}); // Reconstruir para mostrar el scanner con el controlador inicializado
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _controller?.scannerController.stop();
    _controller?.scannerController.start();
  }

  @override
  void dispose() {
    _controller?.disposeController();
    super.dispose();
  }

  Widget _buildMessageContainer({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomInfoPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.black54,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _controller?.qrText != null
                  ? 'Código: ${_controller!.qrText}'
                  : 'Escanea un código QR',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: Colors.deepPurple[900],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, _controller!.asientoValidado != null);
          },
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller!,
        builder: (context, _) {
          if (_controller!.asientoValidado != null || _controller!.scanErrorMessage != null) {
            return Stack(
              children: [
                MobileScanner(
                  controller: _controller!.scannerController,
                  onDetect: _controller!.onDetect,
                ),
                const QRScannerOverlay(),
                Positioned(
                  bottom: 140,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      _controller!.scanErrorMessage != null
                          ? _buildMessageContainer(
                              message: _controller!.scanErrorMessage!,
                              color: Colors.red.shade700,
                              icon: Icons.error_outline,
                            )
                          : _buildMessageContainer(
                              message: 'Asiento validado: ${_controller!.asientoValidado!}',
                              color: Colors.green.shade700,
                              icon: Icons.check_circle_outline,
                            ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _controller!.resetScan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Escanear otro'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                _bottomInfoPanel(),
              ],
            );
          }

          return Stack(
            children: [
              MobileScanner(
                controller: _controller!.scannerController,
                onDetect: _controller!.onDetect,
              ),
              const QRScannerOverlay(),
              _bottomInfoPanel(),
            ],
          );
        },
      ),
    );
  }
}
