import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/asiento.dart'; // Asegúrate de importar el modelo
import 'dart:io';
import 'package:http_parser/http_parser.dart'; // 👈 Asegúrate de tener este import
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/datosQR_model.dart'; // Asegúrate de importar el modelo DatosQR


class ApiService {
  static const String baseUrl = 'https://node-sqlserver-uvs5.onrender.com/api';
 //
//
 // static const String baseUrl = 'http://10.0.2.2:3000/api'; // <-- cambia esto por tu IP local real


 //static const String baseUrl = 'http://127.0.0.1:3000/api'; seguramente sea la ip para probar en el navegador
  static const _storage = FlutterSecureStorage();

  static Future<List<dynamic>> getUsuarios() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/usuarios'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cargar usuarios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de red: $e');
    }
  }
  static Future<List<Map<String, dynamic>>> getRutasPorConductor(int idConductor) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/rutasConductores?idConductor=$idConductor'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al cargar rutas: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error de red al obtener rutas por conductor: $e');
  }
}

  static Future<List<dynamic>> getConductoresActivos() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/conductores'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar conductores: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error de red al obtener conductores: $e');
  }
}


  static Future<List<Asiento>> getAsientos(int salidaId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/asientos?idProgramacion=$salidaId'),
      );

      if (response.statusCode == 200) {
  final data = jsonDecode(response.body) as List;
  print('******************SIG****************');

  // Si quieres ser más claro:
  for (var i = 0; i < data.length; i++) {
    print('🔍 Asiento[$i]: ${data[i]}');
  }

  return data.map((json) => Asiento.fromJson(json)).toList();
} else {
        throw Exception('Error al cargar asientos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de red: $e');
    }
  }

  static Future<Map<String, dynamic>> login(String nombreUsuario, String password) async {
  final url = Uri.parse('$baseUrl/login-jwt');
  final body = jsonEncode({'nombreUsuario': nombreUsuario, 'password': password});

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['token'] != null) {
      // Guardar tokens y userId
      await _storage.write(key: 'jwt_token', value: data['token']);
      await _storage.write(key: 'refresh_token', value: data['refreshToken']);
      await _storage.write(key: 'user_id', value: data['user']['IdUsuario'].toString());
      await _storage.write(key: 'user_type', value: data['user']['IdTipoUsuario'].toString());
      final nombreCompleto = '${data['user']['NombresUsuario']} ${data['user']['ApellidoPaterno']} ${data['user']['ApellidoMaterno']}';
      await _storage.write(key: 'user_name', value: nombreCompleto);



      // Logs de depuración
  
      print('👤 userId guardado: ${data['user']['IdUsuario']}');
      print('👤 userType guardado: ${data['user']['IdTipoUsuario']}');
      print('👤 Nombre completo guardado: $nombreCompleto');

      return {
        'success': true,
        'user': data['user'],
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Credenciales inválidas',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Error de red: $e',
    };
  }
}


static Future<Map<String, dynamic>> enviarCodigoQR(
  String codigo,
  String tripId,
  String tripDate,
  String tripTime,
  String userId,
) async {
  final url = Uri.parse('$baseUrl/registro-qr');
  final body = jsonEncode({
    'codigo': codigo,
    'tripId': tripId,
    'tripDate': tripDate,
    'tripTime': tripTime,
    'idUsuario': userId,
  });

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      return {
        'error': true,
        'status': response.statusCode,
        'message': data['message'] ?? 'Error desconocido del servidor',
        'detalles': data['detalles'] ?? []
      };
    }
  } catch (e) {
    return {
      'error': true,
      'message': 'Error de red: ${e.toString()}',
    };
  }
}



static Future<bool> _renovarToken() async {
  print('[DEBUG] Intentando renovar token...');

  final refreshToken = await _storage.read(key: 'refresh_token');
  final userId = await _storage.read(key: 'user_id');

  if (refreshToken == null || userId == null) {
    print('[DEBUG] No se encontró refreshToken o userId en almacenamiento seguro.');
    return false;
  }

  print('[DEBUG] refreshToken y userId encontrados. Haciendo POST a /refresh-token');

  final url = Uri.parse('$baseUrl/refresh-token');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'userId': int.parse(userId),
      'refreshToken': refreshToken,
    }),
  );

  print('[DEBUG] Respuesta de /refresh-token: ${response.statusCode}');
  print('[DEBUG] Cuerpo: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    await _storage.write(key: 'jwt_token', value: data['accessToken']);
    await _storage.write(key: 'refresh_token', value: data['refreshToken']);
    print('[DEBUG] Tokens renovados y almacenados correctamente.');
    return true;
  }

  print('[DEBUG] Falló la renovación del token.');
  return false;
}


  // 🌐 GET con reintento si el token expiró
  static Future<http.Response> _getConAuthRetry(Uri url) async {
  print('[DEBUG] _getConAuthRetry: Iniciando solicitud GET a $url');

  String? token = await _storage.read(key: 'jwt_token');
  print('[DEBUG] Usando access token: $token');

  http.Response response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  print('[DEBUG] Respuesta inicial: ${response.statusCode}');

  if (response.statusCode == 401) {
    print('[DEBUG] Token expirado o inválido. Intentando renovar...');

    final renovado = await _renovarToken();
    if (renovado) {
      print('[DEBUG] Token renovado. Reintentando solicitud GET...');

      token = await _storage.read(key: 'jwt_token');
      response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[DEBUG] Respuesta tras renovación: ${response.statusCode}');
    } else {
      print('[DEBUG] Falló la renovación del token. No se reintentó la solicitud.');
    }
  }

  return response;
}

static Future<List<dynamic>> getViajes({
    required int idConductor,
    required String fecha,
  }) async {
    final url = Uri.parse('$baseUrl/viajes?idConductor=$idConductor&fecha=$fecha');

    try {
      final response = await _getConAuthRetry(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener viajes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de red: $e');
    }
  }

  
static Future<List<dynamic>> getViajesConFiltros({
  int? idConductor,
  String? fecha,
  String? hora,
  int? idDestino,
  String? estado,
}) async {
  String? estadoNumero;
  if (estado != null) {
    if (estado.toLowerCase() == 'activo' || estado.toLowerCase() == 'vigente') {
      estadoNumero = '1';
    } else if (estado.toLowerCase() == 'anulado') {
      estadoNumero = '0';
    }
  }

  final queryParams = {
    if (idConductor != null) 'idConductor': idConductor.toString(),
    if (fecha != null) 'fecha': fecha,
    if (hora != null) 'hora': hora,
    if (idDestino != null) 'idDestino': idDestino.toString(),
    if (estadoNumero != null) 'estado': estadoNumero,
  };

  final uri = Uri.parse('$baseUrl/viajesFiltrados').replace(queryParameters: queryParams);

  try {
    print('🔍 Consultando viajes con filtros: $queryParams');
    final response = await _getConAuthRetry(uri);

    if (response.statusCode == 200) {
      print('🔍 Respuesta de viajes: ${response.body}');
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener viajes: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error de red: $e');
  }
}



  static Future<Map<String, dynamic>> registrarGasto({
  required int idTipoGasto,
  required String monto,
  required int idProgramacion,
  File? imagenComprobante,
}) async {
  final url = Uri.parse('$baseUrl/gastos');
  final request = http.MultipartRequest('POST', url);

  request.fields['idTipoGasto'] = idTipoGasto.toString();
  request.fields['monto'] = monto;
  request.fields['idProgramacion'] = idProgramacion.toString();

  if (imagenComprobante != null) {
    final extension = imagenComprobante.path.split('.').last.toLowerCase();

    String mimeSubtype;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        mimeSubtype = 'jpeg';
        break;
      case 'png':
        mimeSubtype = 'png';
        break;
      case 'pdf':
        mimeSubtype = 'pdf';
        break;
      default:
        mimeSubtype = 'jpeg';
    }

    request.files.add(await http.MultipartFile.fromPath(
      'comprobante',
      imagenComprobante.path,
      contentType: MediaType('image', mimeSubtype),
    ));
  }

  try {
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return {
        'success': true,
        'data': jsonDecode(responseBody),
      };
    } else {
      return {
        'success': false,
        'message': 'Error al registrar gasto: ${response.statusCode}',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Error de red: $e',
    };
  }
}
static Future<List<Map<String, dynamic>>> obtenerTiposGasto() async {
  final url = Uri.parse('$baseUrl/tipos-gasto');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'];
      return data.cast<Map<String, dynamic>>();
    } else {
      print('❌ Error al obtener tipos de gasto: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('❌ Error de red al obtener tipos de gasto: $e');
    return [];
  }
}
static Future<List<Map<String, dynamic>>> obtenerCausasDevolucion() async {
  final url = Uri.parse('$baseUrl/causasDevolucion');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'];
      return data.cast<Map<String, dynamic>>();
    } else {
      print('❌ Error al obtener causas de devolución: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('❌ Error de red al obtener causas de devolución: $e');
    return [];
  }
}

static Future<void> registrarDevolucion({
  required int idVenta, // Ahora solo se requiere este identificador
  required String fechaDevolucion,
  required double monto,
  String? fechaTransferencia,
  int? numeroTransferencia,
  required int idUsuario,
  String? comentario,
  int? idCausaDevolucion,
}) async {
  final url = Uri.parse('$baseUrl/registroDevolucion');

  final Map<String, dynamic> body = {
    'idVenta': idVenta,
    'numeroBoleto': idVenta.toString(), // Se envía como string, como espera el backend
    'fechaDevolucion': fechaDevolucion,
    'monto': monto,
    'fechaTransferencia': fechaTransferencia,
    'numeroTransaccion': numeroTransferencia?.toString(),
    'idUsuario': idUsuario,
    'comentario': comentario,
    'idCausaDevolucion': idCausaDevolucion,
  }..removeWhere((key, value) => value == null); // Limpia campos opcionales nulos

  try {
    print('📤 Enviando devolución: $body');
    final response = await http.post(
      url,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al registrar devolución: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error de red al registrar devolución: $e');
  }
}
static Future<void> anularViaje({
  required int idProgramacion,
}) async {
  final url = Uri.parse('$baseUrl/anularViaje');

  final Map<String, dynamic> body = {
    'idProgramacion': idProgramacion,
  };

  try {
    print('📤 Enviando solicitud de anulación: $body');
    final response = await http.post(
      url,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al anular el viaje: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error de red al anular viaje: $e');
  }
}
static Future<Map<String, dynamic>> asignarViajeAnulado({
  required int idProgramacion,
  required int idConductor,
}) async {
  final url = Uri.parse('$baseUrl/asignarViajeConductor');

  final Map<String, dynamic> body = {
    'idProgramacion': idProgramacion,
    'idConductor': idConductor,
  };

  try {
    print('📤 Enviando solicitud de asignación: $body');
    final response = await http.post(
      url,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al asignar el viaje anulado: ${response.body}');
    }

    // 👇 Esta línea decodifica el JSON que devuelve tu backend
    return jsonDecode(response.body) as Map<String, dynamic>;

  } catch (e) {
    throw Exception('Error de red al asignar viaje anulado: $e');
  }
}

static Future<List<dynamic>?> obtenerResumenMensual({
  required int idConductor,
  required String fechaInicio,
  required String fechaFin,
}) async {
  final url = Uri.parse('$baseUrl/obtenerResumen?idConductor=$idConductor&fechaInicio=$fechaInicio&fechaFin=$fechaFin');
  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      print('❌ Error al obtener resumen mensual: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('❌ Error de red al obtener resumen mensual: $e');
    return null;
  }

  
}

static Future<List<dynamic>?> obtenerGastosPorConductor({
  required int idConductor,
  required String fechaInicio,
  required String fechaFin,
}) async {
  
  final url = Uri.parse('$baseUrl/obtenerGastosConductor?idConductor=$idConductor&fechaInicio=$fechaInicio&fechaFin=$fechaFin');
  print('🔍 Consultando gastos del conductor: $url');
  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      print('❌ Error al obtener gastos del conductor: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('❌ Error de red al obtener gastos del conductor: $e');
    return null;
  }
}
static Future<void> marcarEstadoViaje({
  required int idProgramacion,
  required String accion, // 'iniciar' o 'finalizar'
}) async {
  final uri = Uri.parse('$baseUrl/marcarEstadoViaje');

  final body = jsonEncode({
    'idProgramacion': idProgramacion,
    'accion': accion,
  });

  try {
    print('📤 Enviando POST a $uri con body: $body');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      print('✅ Estado del viaje actualizado correctamente: ${response.body}');
    } else {
      print('❌ Error al actualizar estado del viaje: ${response.statusCode} ${response.body}');
      throw Exception('Error al marcar estado del viaje.');
    }
  } catch (e) {
    print('❌ Error de red al marcar estado del viaje: $e');
    throw Exception('Error de red al marcar estado del viaje.');
  }
}
static Future<bool> validarSesion() async {
  final url = Uri.parse('$baseUrl/validar-token');

  try {
    final response = await _getConAuthRetry(url);

    if (response.statusCode == 200) {
      print('[VALIDAR SESIÓN] Token válido');

      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        final decodedToken = JwtDecoder.decode(token);

        print('[DECODED JWT] $decodedToken');

        // Guardamos datos extraídos si es necesario
        await _storage.write(key: 'user_id', value: decodedToken['id'].toString());
        await _storage.write(key: 'user_type', value: decodedToken['tipo'].toString());
        await _storage.write(key: 'user_email', value: decodedToken['email'].toString());
      }

      return true;
    } else {
      print('[VALIDAR SESIÓN] Token inválido: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('[ERROR] Validando sesión: $e');
    return false;
  }
}

 static Future<Map<String, dynamic>?> generarQRDesdeVenta(int idVenta) async {
  final url = Uri.parse('$baseUrl/datosQR/$idVenta');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'contenido': data['contenido'],
        'qrBase64': data['qrBase64'],
      };
    } else {
      print('❌ Error al generar QR: ${response.body}');
      return null;
    }
  } catch (e) {
    print('❌ Excepción al generar QR desde venta: $e');
    return null;
  }
}

}










