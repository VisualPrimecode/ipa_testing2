import 'package:flutter/material.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0080), // fondo azul igual que main menu
       // igual color azul
      
      body: const Center(
        child: LoginForm(),
      ),
    );
  }
}
