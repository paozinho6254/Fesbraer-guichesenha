import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://tyrvpporjxeeirzuffjr.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cnZwcG9yanhlZWlyenVmZmpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3ODg0MDMsImV4cCI6MjA4MjM2NDQwM30.A-p8apDRNcciUN5cdAxht2cm94_njiZ8Bnqn5GAjtN0',
    );
    print("✅ Supabase Conectado!");
  } catch (e) {
    print("❌ Erro ao conectar no Supabase: $e");
  }

  runApp(const ProjetosVooApp()); // Substitua pelo nome do seu App principal
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