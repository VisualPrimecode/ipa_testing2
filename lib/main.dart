import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/launch_screen.dart'; // 👈 Importa la nueva pantalla
import 'providers/user_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LaunchScreen(), // 👈 Aquí cambias LoginScreen por LaunchScreen
    );
  }
}
