import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/main_menu_screen.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _nombreUsuarioController = TextEditingController(text: 'dtorres');
  final _passwordController = TextEditingController(text: 'Zq1xw2ce3\$');
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _login() async {
    final nombreUsuario = _nombreUsuarioController.text.trim();
    final password = _passwordController.text.trim();

    if (nombreUsuario.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // 👉 Mostrar loading
    });

    try {
      final result = await ApiService.login(nombreUsuario, password);

      if (!mounted) return;

      if (result['success'] == true) {
        final userJson = result['user'];
        final user = UserModel.fromJson(userJson);
        Provider.of<UserProvider>(context, listen: false).setUser(user);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
        );
      } else {
        final errorMessage = result['message'] ?? 'Credenciales incorrectas';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 👉 Ocultar loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema local para textos y campos en blanco, para que se vean sobre fondo azul oscuro
    final inputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white70),
      borderRadius: BorderRadius.circular(4),
    );

    return Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24.0),
  child: SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40), // Espacio superior ajustable
        Image.asset(
          'assets/images/logo.png',
          height: 120,
        ),
        const SizedBox(height: 24),
        const Text(
          'Inicio de sesión',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ingresa tus credenciales para continuar',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nombreUsuarioController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Nombre de usuario',
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: inputBorder,
            focusedBorder: inputBorder.copyWith(
                borderSide: const BorderSide(color: Colors.white)),
            border: inputBorder,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Contraseña',
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: inputBorder,
            focusedBorder: inputBorder.copyWith(
                borderSide: const BorderSide(color: Colors.white)),
            border: inputBorder,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF1A0080),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Iniciar sesión'),
                ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Al hacer clic en Continuar, acepta nuestras Condiciones\n de servicio y Política de privacidad.',
          style: TextStyle(fontSize: 12, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40), // Espacio inferior opcional
      ],
    ),
  ),
);

  }
}
