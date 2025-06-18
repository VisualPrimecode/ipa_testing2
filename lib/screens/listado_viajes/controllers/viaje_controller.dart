import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class ViajesController {
  List<dynamic> viajesFiltrados = [];
  List<dynamic> conductores = [];
  List<dynamic> rutasDisponibles = [];
  Map<String, dynamic> filtros = {
    'conductor': null,
  'fecha': DateTime.now().toIso8601String().split('T')[0],  // e.g., "2025-05-20"
    'hora': null,
    'ruta': null,
    'estado': null, // <-- nuevo filtro

  };

  TimeOfDay? horaSeleccionada;
  String? fechaSeleccionada;
  Map<String, dynamic>? rutaSeleccionada;

  Future<List<dynamic>> fetchViajes() {
    return ApiService.getViajesConFiltros(
      idConductor: filtros['conductor'],
      fecha: filtros['fecha'],
      hora: filtros['hora'],
      idDestino: filtros['ruta'],
    );
  }

  Future<void> loadConductores() async {
    final data = await ApiService.getConductoresActivos();
    conductores = data;
  }

  void updateFiltro(String tipo, dynamic valor) {
    filtros[tipo] = valor;
  }
  

  String? get nombreConductorSeleccionado {
  final id = filtros['conductor'];
  if (id == null || conductores.isEmpty) return null;

  final conductor = conductores.firstWhere(
  (c) => c['idConductor'] == id, // usar el mismo campo que en el modal
  orElse: () => null,
);


  return conductor?['nombre']; // O el campo correcto en tu modelo
}
String? get nombreRutaSeleccionada {
  final id = filtros['ruta'];
  if (id == null || rutasDisponibles.isEmpty) return null;

 final ruta = rutasDisponibles.firstWhere(
  (r) => r['idRuta'] == id,
  orElse: () => <String, dynamic>{}, // ✅ Retorna un mapa vacío
);


return ruta.isNotEmpty ? ruta['nombreRuta'] : null;
}

  Future<void> aplicarFiltros() async {
  final viajes = await ApiService.getViajesConFiltros(
    idConductor: filtros['conductor'],
    fecha: filtros['fecha'],
    hora: filtros['hora'],
    idDestino: filtros['ruta'],
    estado: filtros['estado'], // <-- AGREGA ESTA LÍNEA
  );
  viajesFiltrados = viajes;
}


  Future<void> seleccionarFecha(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final fechaStr = picked.toIso8601String().split('T')[0];
      fechaSeleccionada = fechaStr;
      updateFiltro('fecha', fechaStr);
      await aplicarFiltros();
    }
  }

  Future<void> seleccionarHora(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: horaSeleccionada ?? TimeOfDay.now(),
    );
    if (picked != null) {
      horaSeleccionada = picked;
      final horaStr = picked.format(context);
      updateFiltro('hora', horaStr);
      await aplicarFiltros();
    }
  }

  Future<void> seleccionarConductor(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: conductores.map<Widget>((conductor) {
          final nombre = conductor['nombre'];
          final id = conductor['idConductor'];
          return ListTile(
            title: Text(nombre),
            onTap: () async {
              Navigator.pop(context);
              updateFiltro('conductor', id);
              await cargarRutasDeConductor(id);
              await aplicarFiltros();
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> cargarRutasDeConductor(int idConductor) async {
    final rutas = await ApiService.getRutasPorConductor(idConductor);
    rutasDisponibles = rutas;
    rutaSeleccionada = null;
  }

  Future<void> seleccionarRuta(BuildContext context) async {
    if (rutasDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona un conductor.')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: rutasDisponibles.map<Widget>((ruta) {
          final nombre = ruta['nombreRuta'];
          final id = ruta['idRuta'];
          return ListTile(
            title: Text(nombre),
            onTap: () {
              Navigator.pop(context);
              rutaSeleccionada = ruta;
              updateFiltro('ruta', id);
              aplicarFiltros(); // no await porque ya cerramos el modal
            },
          );
        }).toList(),
      ),
    );
  }
}
