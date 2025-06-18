import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ExcelExporter {
  static Future<File> createExcelFile(List<Map<String, dynamic>> viajes) async {
    final excel = Excel.createExcel();
    final sheet = excel['Viajes'];

    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Destino'),
      TextCellValue('Hora'),
      TextCellValue('Conductor'),
    ]);

    for (var viaje in viajes) {
      sheet.appendRow([
        TextCellValue('${viaje['idProgramacion'] ?? ''}'),
        TextCellValue('${viaje['NomDestino'] ?? ''}'),
        TextCellValue('${viaje['hora'] ?? ''}'),
        TextCellValue('${viaje['conductor'] ?? ''}'),
      ]);
    }

    final bytes = excel.encode();

    // Guardar en directorio temporal para compartir
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/viajes_exportados_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    final file = File(filePath);
    await file.writeAsBytes(bytes!);

    return file;
  }
}
