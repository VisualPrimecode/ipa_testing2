class DatosQR {
  final int idVenta;
  final int idProgramacion;
  final String fecha;
  final String hora;
  final int asiento;

  DatosQR({
    required this.idVenta,
    required this.idProgramacion,
    required this.fecha,
    required this.hora,
    required this.asiento,
  });

  factory DatosQR.fromJson(Map<String, dynamic> json) {
    return DatosQR(
      idVenta: json['idVenta'],
      idProgramacion: json['idProgramacion'],
      fecha: json['fecha'],
      hora: json['hora'],
      asiento: json['asiento'],
    );
  }
}
