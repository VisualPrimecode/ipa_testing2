import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';


class DevolucionesScreen extends StatefulWidget {
  const DevolucionesScreen({super.key});
  @override
  State<DevolucionesScreen> createState() => _DevolucionesScreenState();
}

class _DevolucionesScreenState extends State<DevolucionesScreen> {
  final _controllers = {
    'idVenta': TextEditingController(),
    'fecha': TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10)),
    'monto': TextEditingController(),
    'comentario': TextEditingController(),
    'numeroTransferencia': TextEditingController(),
    'fechaTransferencia': TextEditingController(),
  };
  int _idUsuario = 0;


  bool _isLoading = false;
  List<Map<String, dynamic>> _causasDevolucion = [];
  int? _idCausaSeleccionada;

  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      setState(() {
        _idUsuario = user.id;
      });
    }
    _cargarCausas();
  });
}


  Future<void> _cargarCausas() async {
    final causas = await ApiService.obtenerCausasDevolucion();
    setState(() => _causasDevolucion = causas);
  }

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      );

  Future<void> _registrarDevolucion() async {
    final text = (String key) => _controllers[key]!.text.trim();
    final monto = double.tryParse(text('monto').replaceAll(',', '').replaceAll('\$', ''));
    final idVenta = int.tryParse(text('idVenta'));

    if (idVenta == null || monto == null || text('fecha').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campos obligatorios incompletos.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.registrarDevolucion(
        idVenta: idVenta,
        fechaDevolucion: text('fecha'),
        monto: monto,
        fechaTransferencia: text('fechaTransferencia').isEmpty ? null : text('fechaTransferencia'),
        numeroTransferencia: text('numeroTransferencia').isEmpty ? null : int.tryParse(text('numeroTransferencia')),
        idUsuario: _idUsuario,
        comentario: text('comentario').isEmpty ? null : text('comentario'),
        idCausaDevolucion: _idCausaSeleccionada,
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Devolución registrada con éxito.')));
      _controllers.forEach((_, c) => c.clear());
      _controllers['fecha']!.text = DateTime.now().toIso8601String().substring(0, 10);
      setState(() => _idCausaSeleccionada = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al registrar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _campo(String label, String key, {
    TextInputType tipo = TextInputType.text,
    bool readOnly = false,
    bool isDate = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextField(
          controller: _controllers[key],
          keyboardType: tipo,
          readOnly: readOnly || isDate,
          decoration: _input(label),
          onTap: isDate
              ? () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(_controllers[key]!.text) ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _controllers[key]!.text = picked.toIso8601String().substring(0, 10);
                  }
                }
              : null,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _dropdownCausas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Causa de Devolución'),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _idCausaSeleccionada,
          decoration: _input('Seleccione una causa'),
          items: _causasDevolucion.map((causa) {
            return DropdownMenuItem<int>(
              value: causa['IdCausa'],
              child: Text(causa['Descripcion']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _idCausaSeleccionada = value);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color(0xFF1A0080),
      appBar: AppBar(
  backgroundColor: const Color(0xFF1A0080),
  elevation: 0,
  leading: const BackButton(color: Colors.white),
  centerTitle: true, // 🔹 Centra el título
  title: const Text(
    'Registro de Devoluciones',
    style: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
),

      body: Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    
    Expanded(
      child: Container(
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
    const SizedBox(height: 20),

    // Datos de venta
    Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _campo('ID Venta', 'idVenta', tipo: TextInputType.number),
            _campo('Fecha de devolución', 'fecha', isDate: true),
            _campo('Monto', 'monto', tipo: TextInputType.number),
          ],
        ),
      ),
    ),
    const SizedBox(height: 20),

    // Transferencia
    Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _campo('Número de transferencia', 'numeroTransferencia', tipo: TextInputType.number),
            _campo('Fecha de transferencia ', 'fechaTransferencia', isDate: true),
          ],
        ),
      ),
    ),
    const SizedBox(height: 20),

    // Detalles adicionales
    Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _campo('Comentario', 'comentario'),
            _dropdownCausas(),
          ],
        ),
      ),
    ),
    const SizedBox(height: 20),

    // Botón
    SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registrarDevolucion,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Registrar devolución'),
      ),
    ),
  ],
),

        ),
      ),
    ),
  ],
),

    );
  }
}
