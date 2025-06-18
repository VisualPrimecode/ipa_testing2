import 'package:flutter/material.dart';
import '../controllers/viaje_controller.dart';
import '../widgets/travel_card.dart';
import '../widgets/filter_button.dart';
import '../screens/viaje_detalle_screen.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/exel_exporter.dart';
import 'package:share_plus/share_plus.dart';


class ViajesScreen extends StatefulWidget {
  const ViajesScreen({super.key});

  @override
  State<ViajesScreen> createState() => _ViajesScreenState();
}

class _ViajesScreenState extends State<ViajesScreen> {
  final _controller = ViajesController();
  late Future<List<dynamic>> _viajesFuture = Future.value([]);
  bool _cargando = true;

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;

    // Si no es admin, asignar el id al filtro automáticamente
    if (user != null && !Provider.of<UserProvider>(context, listen: false).isAdmin) {
      _controller.filtros['conductor'] = user.id;
    }

    await _inicializar();
  });
}
  Future<void> _inicializar() async {
    await _controller.loadConductores();
    await _aplicarFiltros();
    setState(() => _cargando = false);
  }

  Future<void> _aplicarFiltros() async {
    await _controller.aplicarFiltros();
    _viajesFuture = Future.value(_controller.viajesFiltrados);
    setState(() {});
  }
  
  void _limpiarFiltro(String key) async {
  final isAdmin = Provider.of<UserProvider>(context, listen: false).isAdmin;

  // 🚫 Evitar que conductores limpien su filtro
  if (key == 'conductor' && !isAdmin) return;

  _controller.filtros[key] = null;

  if (key == 'conductor' || key == 'ruta') {
    _controller.rutaSeleccionada = null;
    _controller.rutasDisponibles.clear();
  }

  await _aplicarFiltros();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Filtro $key limpiado')));
}


  Widget _buildFilter(String key, Function(BuildContext) selector, {String? label}) {
    return FilterButton(
      label: label ?? _controller.filtros[key] ?? key.capitalize(),
      onPressed: () async {
        await selector(context);
        await _aplicarFiltros();
      },
      onLongPress: () => _limpiarFiltro(key),
    );
  }

  Widget _buildFilterButtons() {
  final userProvider = Provider.of<UserProvider>(context);
  final user = userProvider.user;

  // Esperar a que se haya cargado el usuario
  if (user == null) return const SizedBox.shrink();

  final isAdmin = userProvider.isAdmin;

  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      _buildFilter('fecha', _controller.seleccionarFecha),
      _buildFilter('hora', _controller.seleccionarHora),
      if (isAdmin)
        _buildFilter('conductor', _controller.seleccionarConductor,
            label: _controller.nombreConductorSeleccionado),
      _buildFilter('ruta', _controller.seleccionarRuta,
          label: _controller.nombreRutaSeleccionada),
      FilterButton(
        label: _controller.filtros['estado'] ?? 'Estado',
        onPressed: () async {
          final selected = await showModalBottomSheet<String>(
            context: context,
            builder: (_) => Column(
              mainAxisSize: MainAxisSize.min,
              children: ['Todos', 'Activo', 'Anulado']
                  .map((estado) => ListTile(
                        title: Text(estado),
                        onTap: () => Navigator.pop(context, estado == 'Todos' ? null : estado),
                      ))
                  .toList(),
            ),
          );
          if (selected != null || _controller.filtros['estado'] != null) {
            _controller.filtros['estado'] = selected;
            await _aplicarFiltros();
          }
        },
        onLongPress: () => _limpiarFiltro('estado'),
      ),
    ],
  );
}



  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A0080),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A0080),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0080),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text('Listado de viajes', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildFilterButtons(),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _viajesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final viajes = snapshot.data ?? [];
                    if (viajes.isEmpty) {
                      return const Center(child: Text('No hay viajes disponibles.'));
                    }

                    return ListView.builder(
                      itemCount: viajes.length,
                      itemBuilder: (_, index) {
                        final viaje = viajes[index];
                        final conductorId = viaje['IdConductor'];
                        final conductor = _controller.conductores.firstWhere(
                          (c) => c['id'] == conductorId || c['idConductor'] == conductorId,
                          orElse: () => {},
                        );
                        final conductorNombre = conductor['nombre'] ?? 'Sin conductor';

                        return TravelCard(
                          number: '#${viaje['idProgramacion']}',
                          route: viaje['NomDestino'],
                          time: viaje['hora'],
                          conductor: conductorNombre,
                          onTap: () {
  final isAdmin = Provider.of<UserProvider>(context, listen: false).isAdmin;

  if (!isAdmin) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solo los administradores pueden ver el detalle del viaje')),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ViajeDetalleScreen(
        viaje: {...viaje, 'nombreConductor': conductorNombre},
      ),
    ),
  );
},

                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
       
  floatingActionButton: FloatingActionButton.extended(
  onPressed: () async {
    try {
      final viajes = _controller.viajesFiltrados.map((v) {
        final conductorId = v['IdConductor'];
        final conductor = _controller.conductores.firstWhere(
          (c) => c['id'] == conductorId || c['idConductor'] == conductorId,
          orElse: () => {},
        );
        final conductorNombre = conductor['nombre'] ?? 'Sin conductor';

        return {
          'idProgramacion': v['idProgramacion'],
          'NomDestino': v['NomDestino'],
          'hora': v['hora'],
          'conductor': conductorNombre,
        };
      }).toList();

      final file = await ExcelExporter.createExcelFile(viajes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Listado de viajes exportado',
        subject: 'Archivo Excel de viajes',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar archivo: $e')),
      );
    }
  },
  icon: const Icon(Icons.send),
  label: const Text('Enviar'),
  backgroundColor: Colors.deepPurple,
),
    );
  }
}

extension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
