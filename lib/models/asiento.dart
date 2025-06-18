class Asiento {
  final String idAsiento;        // ej. "1", "2", …
  final bool vendido;     // true si vendido == 1
  final bool registrado;  // true si registrado == 1

  Asiento({
    required this.idAsiento,
    required this.vendido,
    required this.registrado,
  });

  factory Asiento.fromJson(Map<String, dynamic> json) {
  return Asiento(
    idAsiento: json['IdAsiento'].toString(),  // Usa la mayúscula exacta
    vendido: json['Vendido'] != 0,            // Corregido
    registrado: json['Registrado'] != 0,      // Corregido
  );
}

}
