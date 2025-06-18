import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

Future<File> exportarResumenMensualExcel({
  required int totalViajes,
  required int totalPasajeros,
  required int totalProduccion,
  required double totalGastos,
  required List datosGrafico,
  required List datosPie,
}) async {
  final excel = Excel.createExcel();
  final sheet = excel['Resumen'];

  sheet.appendRow([
    TextCellValue('Resumen Mensual')
  ]);
  sheet.appendRow([
    TextCellValue('Total viajes'),
    TextCellValue(totalViajes.toString())
  ]);
  sheet.appendRow([
    TextCellValue('Total pasajeros'),
    TextCellValue(totalPasajeros.toString())
  ]);
  sheet.appendRow([
    TextCellValue('Total producción'),
    TextCellValue(totalProduccion.toString())
  ]);
  sheet.appendRow([
    TextCellValue('Total gastos'),
    TextCellValue(totalGastos.toStringAsFixed(2))
  ]);
  sheet.appendRow([]);

  sheet.appendRow([
    TextCellValue('Gráfico: Pasajeros por Día')
  ]);
  sheet.appendRow([
    TextCellValue('Día'),
    TextCellValue('Pasajeros'),
    TextCellValue('Total Vendido')
  ]);

  for (var d in datosGrafico) {
    sheet.appendRow([
      TextCellValue(d.dia.toString()),
      TextCellValue(d.cantidad.toString()),
      TextCellValue(d.totalVendido.toStringAsFixed(2)),
    ]);
  }

  sheet.appendRow([]);
  sheet.appendRow([
    TextCellValue('Gastos por Programación')
  ]);
  sheet.appendRow([
    TextCellValue('Título'),
    TextCellValue('Monto')
  ]);

  for (var g in datosPie) {
    sheet.appendRow([
      TextCellValue(g.titulo),
      TextCellValue(g.valor.toStringAsFixed(2)),
    ]);
  }

  final bytes = excel.encode();
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/resumen_mensual.xlsx');
  await file.writeAsBytes(bytes!);
  return file;
}
