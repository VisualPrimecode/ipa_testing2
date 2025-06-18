import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'widgets/resumen_cuadro.dart';
import 'widgets/bar_chart_sample.dart';
import 'widgets/pie_chart_sample.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../../utils/export_utils.dart';
 // Ajusta el path

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
double totalGastos = 0.0;

  int _idConductor = 0;
  bool mostrarResumen = false;
  bool verGrafico = false;

  int totalViajes = 0;
  int totalPasajeros = 0;
  int totalProduccion = 0;
  bool _cargandoResumen = false;


  List<ResumenPieData> datosPie = [];
List<PasajerosPorDia> datosGrafico = [];

  late int selectedMonth;
  late int selectedYear;

  final List<String> meses = const [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  List<dynamic> _conductores = [];
  Map<String, dynamic>? _conductorSeleccionado;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = now.month;
    selectedYear = now.year;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user != null) {
        setState(() {
          _idConductor = user.id;
        });
        await _loadConductores();
      }
    });
  }

  Future<void> _loadConductores() async {
    final lista = await ApiService.getConductoresActivos();
    setState(() {
      _conductores = lista;
      _conductorSeleccionado = lista.firstWhere(
        (c) => c['idConductor'] == _idConductor,
        orElse: () => null,
      );
    });
  }

  Future<void> _selectConductor() async {
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
                _idConductor = c['idConductor'];
              });
            },
          );
        }).toList(),
      ),
    );
  }

  DateTime get fechaInicio => DateTime(selectedYear, selectedMonth, 1);
  DateTime get fechaFin => DateTime(selectedYear, selectedMonth + 1, 0);

 Future<void> _buscarResumen() async {
  setState(() {
    _cargandoResumen = true;
  });

  final formato = DateFormat('yyyy-MM-dd');

  final dataResumen = await ApiService.obtenerResumenMensual(
    idConductor: _idConductor,
    fechaInicio: formato.format(fechaInicio),
    fechaFin: formato.format(fechaFin),
  );

  final dataGastos = await ApiService.obtenerGastosPorConductor(
    idConductor: _idConductor,
    fechaInicio: formato.format(fechaInicio),
    fechaFin: formato.format(fechaFin),
  );

  if (dataResumen != null) {
    print('Resumen mensual obtenido: ${dataGastos?.length ?? 0} registros');

    final Map<int, double> pasajerosPorDia = {};
    final Map<int, double> totalVendidoPorDia = {};
    int pasajerosTotales = 0;
    int produccionTotal = 0;

    for (var item in dataResumen) {
      final fecha = DateTime.tryParse(item['fecha'] ?? '');
      if (fecha == null) continue;

      final int dia = fecha.day;
      final int pasajeros = (item['PasajerosTransportados'] as num?)?.toInt() ?? 0;
      final double produccion = (item['TotalProduccion'] as num?)?.toDouble() ?? 0.0;

      pasajerosPorDia.update(
        dia,
        (valorActual) => valorActual + pasajeros.toDouble(),
        ifAbsent: () => pasajeros.toDouble(),
      );

      totalVendidoPorDia.update(
        dia,
        (valorActual) => valorActual + produccion,
        ifAbsent: () => produccion,
      );

      pasajerosTotales += pasajeros;
      produccionTotal += produccion.toInt();
    }

    final List<PasajerosPorDia> grafico = pasajerosPorDia.entries
        .map((e) => PasajerosPorDia(
              dia: e.key,
              cantidad: e.value,
              totalVendido: totalVendidoPorDia[e.key] ?? 0.0,
            ))
        .toList()
      ..sort((a, b) => a.dia.compareTo(b.dia));

    final List<ResumenPieData> pie = [];

    if (dataGastos != null && dataGastos.isNotEmpty) {
      for (var gasto in dataGastos) {
        final double monto = (gasto['Monto'] as num?)?.toDouble() ?? 0.0;
        final int idProg = gasto['IdProgramacion'] as int? ?? 0;

        if (monto > 0 && idProg > 0) {
          pie.add(
            ResumenPieData(
              valor: monto,
              titulo: 'P$idProg',
              color: Colors.primaries[pie.length % Colors.primaries.length],
            ),
          );
        }
      }
    }

    setState(() {
      totalViajes = dataResumen.length;
      totalPasajeros = pasajerosTotales;
      totalProduccion = produccionTotal;
      totalGastos = (dataGastos ?? []).fold(0.0, (suma, gasto) {
        final double monto = (gasto['Monto'] as num?)?.toDouble() ?? 0.0;
        final int idProg = gasto['IdProgramacion'] as int? ?? 0;
        return (monto > 0 && idProg > 0) ? suma + monto : suma;
      });
      datosGrafico = grafico;
      datosPie = pie;
      mostrarResumen = true;
      verGrafico = false;
      _cargandoResumen = false;
    });
  } else {
    setState(() {
      _cargandoResumen = false;
    });
  }
}

  Widget _buildMesSelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: selectedMonth,
            items: List.generate(12, (i) {
              return DropdownMenuItem(
                value: i + 1,
                child: Text(meses[i]),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedMonth = value;
                });
              }
            },
            decoration: const InputDecoration(labelText: 'Mes'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: selectedYear,
            items: List.generate(5, (i) {
              final year = DateTime.now().year - i;
              return DropdownMenuItem(
                value: year,
                child: Text('$year'),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedYear = value;
                });
              }
            },
            decoration: const InputDecoration(labelText: 'Año'),
          ),
        ),
      ],
    );
  }
Future<void> _exportarResumen() async {
  final file = await exportarResumenMensualExcel(
    totalViajes: totalViajes,
    totalPasajeros: totalPasajeros,
    totalProduccion: totalProduccion,
    totalGastos: totalGastos,
    datosGrafico: datosGrafico,
    datosPie: datosPie,
  );

  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'Resumen mensual exportado',
    subject: 'Archivo Excel - Resumen de viajes',
  );
}

  @override
Widget build(BuildContext context) {
  final isAdmin = Provider.of<UserProvider>(context).isAdmin;

  return Scaffold(
  backgroundColor: const Color(0xFF1A0080), // fondo general oscuro

 appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  centerTitle: true, // 👈 centrado del título
  title: const Text(
    'Resumen mensual',
    style: TextStyle(color: Colors.white),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
),


  body: Padding(
  padding: const EdgeInsets.all(20),
  child: _cargandoResumen
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
          child: Column(
            children: [
              // 🔹 Filtros agrupados en Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (isAdmin && _conductores.isNotEmpty) _buildConductorSelector(),
                      _buildMesSelector(),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (isAdmin && _conductorSeleccionado == null) {
                            _showSnackBar('Por favor selecciona un conductor.');
                            return;
                          }
                          _buscarResumen();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Buscar'),
                      ),
                    ],
                  ),
                ),
              ),

              // 🔹 Resumen agrupado en Card
              if (totalViajes > 0)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  margin: const EdgeInsets.only(top: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildResumenView(),
                  ),
                ),
            ],
          ),
        ),
),

  floatingActionButton: totalViajes > 0
    ? FloatingActionButton.extended(
        onPressed: _exportarResumen,
        icon: const Icon(Icons.share),
        label: const Text('Exportar resumen'),
        backgroundColor: Colors.green,
      )
    : null,

);
}


Widget _buildConductorSelector() {
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              _conductorSeleccionado != null
                  ? 'Conductor: ${_conductorSeleccionado!['nombre']}'
                  : 'Selecciona un conductor',
            ),
          ),
          ElevatedButton(
  onPressed: _selectConductor,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
  child: const Text('Elegir conductor'),
),

        ],
      ),
      const SizedBox(height: 20),
    ],
  );
}

Widget _buildResumenView() {
  return Column(
    children: [
      mostrarResumen
          ? Column(
              children: [
                verGrafico
                    ? Column(
                        children: [
                          SizedBox(height: 250, child: ResumenBarChart(datos: datosGrafico)),
                          const SizedBox(height: 20),
                          SizedBox(height: 250, child: ResumenPieChart(datos: datosPie)),
                        ],
                      )
                    : ResumenCuadro(
                        totalViajes: totalViajes,
                        totalPasajeros: totalPasajeros,
                        totalProduccion: totalProduccion,
                        totalGastos: totalGastos, // ← ¡AGREGAR ESTO!

                      ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => mostrarResumen = false),
                      icon: const Icon(Icons.visibility_off),
                      label: const Text('Ocultar resumen'),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () => setState(() => verGrafico = !verGrafico),
                      icon: Icon(verGrafico ? Icons.table_chart : Icons.bar_chart),
                      label: Text(verGrafico ? 'Ver cuadro' : 'Ver gráfico'),
                    ),
                  ],
                ),
              ],
            )
          : TextButton.icon(
              onPressed: () => setState(() => mostrarResumen = true),
              icon: const Icon(Icons.visibility),
              label: const Text('Ver resumen'),
            ),
    ],
  );
}

void _showSnackBar(String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}


}
