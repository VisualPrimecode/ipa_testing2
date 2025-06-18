// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
//registro de salidas
class TipoGasto {
  final int id;
  final String nombre;

  TipoGasto({required this.id, required this.nombre});

  factory TipoGasto.fromJson(Map<String, dynamic> json) =>
      TipoGasto(id: json['IdTipoGasto'], nombre: json['NombreTipo']);
}

class RegistroScreen extends StatefulWidget {
  final int idProgramacion;
  const RegistroScreen({super.key, required this.idProgramacion});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final TextEditingController montoController = TextEditingController();
  File? _imagenComprobante;
  bool _isLoading = false;
  List<TipoGasto> _tiposGasto = [];
  int? _tipoSeleccionado;
  

  @override
  void initState() {
    super.initState();
    _cargarTiposGasto();
  }

  @override
  void dispose() {
    montoController.dispose();
    super.dispose();
  }

  Future<void> _cargarTiposGasto() async {
    final tipos = await ApiService.obtenerTiposGasto();
    setState(() => _tiposGasto = tipos.map((e) => TipoGasto.fromJson(e)).toList());
  }

  Future<void> _seleccionarImagen() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _imagenComprobante = File(picked.path));
  }

  Future<void> _registrarGasto() async {
    final monto = montoController.text.trim();
    if (_tipoSeleccionado == null || monto.isEmpty) {
      _showMsg('Completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.registrarGasto(
        idTipoGasto: _tipoSeleccionado!,
        monto: monto,
        idProgramacion: widget.idProgramacion,
        imagenComprobante: _imagenComprobante,
      );

      setState(() => _isLoading = false);
      res['success'] ? _onSuccess() : _showMsg('❌ Error: ${res['message']}');
    } catch (e) {
      setState(() => _isLoading = false);
      _showMsg('❌ Error de red: $e');
    }
  }

  void _onSuccess() {
    _showMsg('✅ Gasto registrado exitosamente');
    montoController.clear();
    setState(() => _imagenComprobante = null);
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _inputLabel(String text) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(text), const SizedBox(height: 8)],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[900],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registro de Pagos y Gastos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              _inputLabel('Tipo de gasto'),
              DropdownButtonFormField<int>(
                value: _tipoSeleccionado,
                items: _tiposGasto.map((tipo) => DropdownMenuItem(
                  value: tipo.id,
                  child: Text(tipo.nombre),
                )).toList(),
                onChanged: (value) => setState(() => _tipoSeleccionado = value),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 20),
              _inputLabel('Monto'),
              TextField(
                controller: montoController,
                decoration: InputDecoration(
                  hintText: '\$10.500',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _inputLabel('Imagen del comprobante'),
              GestureDetector(
                onTap: _seleccionarImagen,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                    image: _imagenComprobante != null
                        ? DecorationImage(image: FileImage(_imagenComprobante!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imagenComprobante == null
                      ? const Center(child: Icon(Icons.camera_alt, size: 40, color: Colors.black54))
                      : null,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registrarGasto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Registrar gasto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
