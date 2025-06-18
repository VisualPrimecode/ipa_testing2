import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';

class QrDesdeVentaScreen extends StatefulWidget {
  const QrDesdeVentaScreen({super.key});

  @override
  State<QrDesdeVentaScreen> createState() => _QrDesdeVentaScreenState();
}

class _QrDesdeVentaScreenState extends State<QrDesdeVentaScreen> {
  final TextEditingController _ventaIdController = TextEditingController();
  String? _qrContenido;
  String? _qrBase64;
  bool _cargando = false;
  String? _error;

  Future<void> _generarQR() async {
    final idVentaText = _ventaIdController.text;
    if (idVentaText.isEmpty) {
      setState(() => _error = 'Debes ingresar un ID de venta');
      return;
    }

    final idVenta = int.tryParse(idVentaText);
    if (idVenta == null) {
      setState(() => _error = 'ID de venta inválido');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
      _qrContenido = null;
      _qrBase64 = null;
    });

    final resultado = await ApiService.generarQRDesdeVenta(idVenta);

    setState(() {
      _cargando = false;
      if (resultado != null) {
        _qrContenido = resultado['contenido'];
        _qrBase64 = resultado['qrBase64'];
      } else {
        _error = 'No se pudo generar el QR. Verifica el ID.';
      }
    });
  }

  Widget _buildQRImage() {
    if (_qrBase64 == null) return const SizedBox();

    try {
      final base64Str = _qrBase64!.split(',').last;
      final bytes = base64Decode(base64Str);
      return Image.memory(bytes, width: 200, height: 200);
    } catch (e) {
      return const Text('⚠️ Error al mostrar el QR');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generar QR desde Venta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ventaIdController,
              decoration: const InputDecoration(
                labelText: 'ID de Venta',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargando ? null : _generarQR,
              child: _cargando
                  ? const CircularProgressIndicator()
                  : const Text('Generar QR'),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_qrContenido != null)
              Text('Contenido: $_qrContenido'),
            const SizedBox(height: 16),
            _buildQRImage(),
          ],
        ),
      ),
    );
  }
}
