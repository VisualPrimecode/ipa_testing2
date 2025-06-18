import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SalidaFilterForm extends StatefulWidget {
  final void Function(int idConductor, DateTime fecha) onFilter;
  final String buttonText;
  final bool soloMes;

  const SalidaFilterForm({
    super.key,
    required this.onFilter,
    this.buttonText = 'Buscar salidas',
    this.soloMes = false,
  });

  @override
  State<SalidaFilterForm> createState() => _SalidaFilterFormState();
}

class _SalidaFilterFormState extends State<SalidaFilterForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();

  List<dynamic> _conductores = [];
  Map<String, dynamic>? _conductorSeleccionado;

  @override
  void initState() {
    super.initState();
    _loadConductores();
  }

  Future<void> _loadConductores() async {
    final conductores = await ApiService.getConductoresActivos();
    setState(() {
      _conductores = conductores;
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      // Modo de solo mes: seleccionamos el primer día del mes para propósitos prácticos
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectConductor(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: _conductores.map((c) {
          return ListTile(
            title: Text(c['nombre']),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _conductorSeleccionado = c;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  void _submit() {
    if (_conductorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un conductor.')),
      );
      return;
    }

    final id = _conductorSeleccionado!['idConductor'];
    widget.onFilter(id, _selectedDate);
  }

  @override
Widget build(BuildContext context) {
  return Card(
    margin: const EdgeInsets.all(16),
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 Conductor
            Text(
              'Conductor',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _conductorSeleccionado != null
                        ? _conductorSeleccionado!['nombre']
                        : 'Selecciona un conductor',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectConductor(context),
                  child: const Text('Elegir'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Fecha
            Text(
              'Fecha',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate.toLocal().toString().split(' ')[0],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _pickDate(context),
                  child: const Text('Cambiar'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔍 Botón de buscar
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: const Color(0xFF1A0080),
              ),
              onPressed: _submit,
              icon: const Icon(Icons.search),
              label: Text(
  widget.buttonText,
  style: const TextStyle(
    fontSize: 16,
    color: Colors.white, // 👈 Aquí defines el texto blanco
  ),
),

            ),
          ],
        ),
      ),
    ),
  );
}

}
