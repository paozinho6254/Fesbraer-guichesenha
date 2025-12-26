import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  // Garante que o Flutter esteja pronto antes de iniciar o Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Supabase
  await Supabase.initialize(
    url: 'SUA_URL_DO_SUPABASE', // Ex: https://xyz.supabase.co
    anonKey: 'SUA_CHAVE_ANON_DO_SUPABASE', // Chave comprida que começa com "eyJ..."
  );
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