import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/asiento.dart';
import '../widgets/asientos_bus/bus_seats_widget.dart';
import '../widgets/salida_filter_form.dart';
import 'qr_scanner/qr_scanner_page.dart';
import 'registro_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';


class SalidaScreen extends StatefulWidget {
  const SalidaScreen({super.key});

  @override
  State<SalidaScreen> createState() => _SalidaScreenState();
}

class _SalidaScreenState extends State<SalidaScreen> {
  int _idConductor = 0;
  bool _mostrarFiltro = true;
  Future<List<dynamic>>? _viajesFuture;
  
  DateTime _fecha = DateTime.now();
  // 🆕 Mapa para cachear los asientos por viaje
  final Map<int, Future<List<Asiento>>> _asientosFutures = {};

  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      setState(() {
        _idConductor = user.id;
        _viajesFuture = fetchViajes(); // ← Inicialmente cargamos viajes
      });
    }
  });
}

  Future<List<dynamic>> fetchViajes() {
    final fechaStr = _fecha.toIso8601String().split('T')[0];
    return ApiService.getViajes(idConductor: _idConductor, fecha: fechaStr);
  }

  Future<List<Asiento>> _fetchAsientos(int idProgramacion) {
  print('🛫 Solicitando asientos para salida $idProgramacion');
  if (!_asientosFutures.containsKey(idProgramacion)) {
    _asientosFutures[idProgramacion] =
        ApiService.getAsientos(idProgramacion);
  }
  return _asientosFutures[idProgramacion]!;
}

  Color getColor(String estado) => {
        'En espera': Colors.red,
        'Activo': Colors.orange,
        'Finalizado': Colors.green,
      }[estado] ?? Colors.grey;

  Future<void> _cambiarEstadoViaje(int idProgramacion, String accion) async {
  try {
    await ApiService.marcarEstadoViaje(idProgramacion: idProgramacion, accion: accion);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viaje ${accion == 'iniciar' ? 'iniciado' : 'finalizado'} correctamente')),
    );

    setState(() {
      _asientosFutures.clear();
      _viajesFuture = fetchViajes(); // Recarga la lista de viajes
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al cambiar estado del viaje: $e')),
    );
  }
}

  @override
Widget build(BuildContext context) {
  final userProvider = Provider.of<UserProvider>(context);
  
  return Scaffold(
    backgroundColor:  const Color(0xFF1A0080),
     appBar: AppBar(
  backgroundColor: const Color(0xFF1A0080),
  elevation: 0,
  leading: const BackButton(color: Colors.white),
  centerTitle: true, // 🔹 Centra el título
  title: const Text(
    'Listado de Salidas',
    style: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
),
    body: Column(
  children: [
    // Mostrar botón para volver a mostrar el filtro
   // Mostrar botón para mostrar u ocultar el filtro
if (userProvider.isAdmin)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _mostrarFiltro = !_mostrarFiltro;
          });
        },
        icon: Icon(_mostrarFiltro ? Icons.filter_alt_off : Icons.filter_alt),
        label: Text(_mostrarFiltro ? 'Ocultar filtro' : 'Mostrar filtro'),
      ),
    ),
  ),


    // Mostrar el filtro solo si está activo y el usuario es admin
    if (_mostrarFiltro && userProvider.isAdmin)
      SalidaFilterForm(
  onFilter: (id, fecha) {
    setState(() {
      _idConductor = id;
      _fecha = fecha;
      _asientosFutures.clear();
      _mostrarFiltro = false;
      _viajesFuture = fetchViajes(); // ← Solo aquí se recarga
    });
  },
),


    // Viajes
    Expanded(
      child: FutureBuilder<List<dynamic>>(
future: _viajesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data?.isEmpty ?? true) {
            return const Center(child: Text('No hay viajes disponibles.'));
          }

         final viajesFiltrados = snapshot.data!.where((v) => v['Finalizado'] != 'Finalizado').toList();
return _buildViajesList(viajesFiltrados);

        },
      ),
    ),
  ],
),

  );
}

void _recargarAsientos(int idProgramacion) {
  setState(() {
    _asientosFutures.remove(idProgramacion);
  });
}

  Widget _buildViajesList(List<dynamic> viajes) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona tu salida',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...viajes.map((v) {
                final idProgramacion = v['idProgramacion'] as int;
                return ExpansionTile(
                  title: _buildViajeTitle(v),
                  children: [
                    _buildAccionButtons(v),

                    TextButton.icon(
  onPressed: () async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          // Usamos StatefulBuilder para controlar el estado localmente
          return StatefulBuilder(
            builder: (context, setModalState) {
              // El future se vuelve local y recargable
              Future<List<Asiento>> futureAsientos = _fetchAsientos(idProgramacion);

              return Container(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<List<Asiento>>(
                  future: futureAsientos,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Text('Error al cargar asientos');
                    } else if (snapshot.hasData) {
                      return Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                // Limpiamos el cache y forzamos la recarga
                                _asientosFutures.remove(idProgramacion);
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Actualizar asientos'),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: controller,
                              child: BusSeatsWidget(asientos: snapshot.data!),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return const Text('No se encontraron asientos.');
                    }
                  },
                ),
              );
            },
          );
        },
      );
    },
  );
},

  icon: const Icon(Icons.event_seat),
  label: const Text('Ver Asientos'),
),

                  ],
                );
              }),
            ],
          ),
        ),
      );
  //BUILD ACCION BUTTONS
  Widget _buildAccionButtons(dynamic v) {
  final estadoFinalizado = v['Finalizado'];
  final estadoIniciado = v['Iniciado'];

  final idProgramacion = v['idProgramacion'];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final asiento = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QRScannerPage(
                        tripId: idProgramacion.toString(),
                        tripDate: _fecha.toIso8601String().split('T')[0],
                        tripTime: v['hora'],
                      ),
                    ),
                  );
                  if (asiento == true) {
  setState(() {
    _asientosFutures.remove(idProgramacion);
  });
}

                },
                icon: const Icon(Icons.qr_code),
                label: const Text('Ver QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegistroScreen(
                        idProgramacion: idProgramacion,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.attach_money),
                label: const Text('Gastos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 🔘 Botones de estado
        if (estadoIniciado == 'En espera')
  ElevatedButton.icon(
    onPressed: () => _confirmarAccion(
      context,
      titulo: '¿Iniciar viaje?',
      mensaje: '¿Estás seguro que deseas iniciar este viaje?',
      onConfirm: () => _cambiarEstadoViaje(idProgramacion, 'iniciar'),
    ),
    icon: const Icon(Icons.play_arrow),
    label: const Text('Iniciar viaje'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
    ),
  ),

// Botón: Finalizar viaje
if (estadoIniciado != 'En espera' && estadoFinalizado != 'Finalizado')
  ElevatedButton.icon(
    onPressed: () => _confirmarAccion(
      context,
      titulo: '¿Finalizar viaje?',
      mensaje: '¿Estás seguro que deseas finalizar este viaje?',
      onConfirm: () => _cambiarEstadoViaje(idProgramacion, 'finalizar'),
    ),
    icon: const Icon(Icons.check),
    label: const Text('Finalizar viaje'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
    ),
  ),
      ],
    ),
  );
}
  //NOMBRE DEL ESTADO DEL VIAJE
  Widget _buildViajeTitle(dynamic v) {
  final iniciado = v['Iniciado'] == 'Activo';
  final finalizado = v['Finalizado'] == 'Finalizado';

  String estadoTexto;
  Color estadoColor;

  if (!iniciado) {
    estadoTexto = 'Pendiente';
    estadoColor = Colors.red;
  } else if (iniciado && !finalizado) {
    estadoTexto = 'Activo';
    estadoColor = Colors.orange;
  } else {
    estadoTexto = 'Finalizado';
    estadoColor = Colors.green;
  }

  return Row(
    children: [
      Text(
        '#${v['idProgramacion']}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v['NomDestino'], style: const TextStyle(fontSize: 16)),
            Text(v['hora'], style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: estadoColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          estadoTexto,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ],
  );
}

 void _confirmarAccion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ElevatedButton(
            child: const Text('Confirmar'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onConfirm();
            },
          ),
        ],
      );
    },
  );
}

}
