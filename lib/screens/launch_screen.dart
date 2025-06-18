import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'login_screen.dart';
import 'main_menu_screen.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
  try {
    final tokenValido = await ApiService.validarSesion();

    if (!mounted) return;

    if (tokenValido) {
      final token = await _storage.read(key: 'jwt_token');

      if (token != null && !JwtDecoder.isExpired(token)) {
        final decoded = JwtDecoder.decode(token);
        print('[DECODED JWT] $decoded');

        // Validar que las claves existan
        final id = decoded['id'];
        final tipo = decoded['tipo'];

        if (id != null && tipo != null) {
          final user = UserModel(
            id: int.parse(id.toString()),
            tipoUsuario: int.parse(tipo.toString()),
          );

          Provider.of<UserProvider>(context, listen: false).setUser(user);

          // Guardamos en el storage también
          await _storage.write(key: 'user_id', value: id.toString());
          await _storage.write(key: 'user_type', value: tipo.toString());

          print('[LAUNCH SCREEN] Usuario configurado: $id, tipo: $tipo');
        } else {
          print('[ERROR] Claves faltantes en el token');
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      );
    } else {
      await _storage.deleteAll();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  } catch (e, stacktrace) {
    print('[ERROR] En _verificarSesion: $e');
    print(stacktrace);
    await _storage.deleteAll();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}




  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A0080),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
