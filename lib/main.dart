import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const ProjetosVooApp());
}

class ProjetosVooApp extends StatelessWidget {
  const ProjetosVooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fesbraer Controle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}