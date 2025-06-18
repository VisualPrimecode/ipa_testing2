import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'login_screen.dart';
import 'salidas_screen.dart';
import 'devoluciones_screen.dart';
import '../screens/listado_viajes/screens/viajes_screen.dart';
import '../screens/resumen_screen/monthly_summary_screen.dart';
import '../services/api_service.dart'; // Asegúrate que la ruta sea correcta
import '../screens/qrGenerador_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  static final _storage = FlutterSecureStorage();
  String? userName;

  final List<_MenuItem> _menuItems = const [
    _MenuItem('Resumen', MonthlySummaryScreen()),
    _MenuItem('Devoluciones', DevolucionesScreen()),
    _MenuItem('Viajes', ViajesScreen()),
    _MenuItem('Salidas', SalidaScreen()),
  ];

 @override
void didChangeDependencies() {
  super.didChangeDependencies();

  // Validar cada vez que se accede a esta pantalla
  if (ModalRoute.of(context)?.isCurrent ?? false) {
    _validarYContinuar();
  }
}

  Future<void> _validarYContinuar() async {
  final sesionValida = await ApiService.validarSesion();

  if (!sesionValida) {
    await _storage.deleteAll();

    if (!mounted) return;

    // Mostrar mensaje de sesión vencida
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tu sesión ha vencido. Por favor, inicia sesión nuevamente.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );

    // Esperar un momento antes de redirigir
    await Future.delayed(const Duration(seconds: 2));

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  } else {
    _loadUserName();
  }
}


  Future<void> _loadUserName() async {
    final name = await _storage.read(key: 'user_name');
    setState(() {
      userName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0080),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0080),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Menú Principal',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1A0080),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (userName != null)
                  Text(
                    '👋 Hola, $userName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                IconButton(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Cerrar sesión',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    children: _menuItems
                        .map((item) =>
                            _buildMenuButton(context, item.title, item.screen))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, Widget screen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple[900],
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        child: Text(title),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    try {
      await _storage.deleteAll();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      print('[LOGOUT ERROR] $e');
    }
  }
}

class _MenuItem {
  final String title;
  final Widget screen;
  const _MenuItem(this.title, this.screen);
}
