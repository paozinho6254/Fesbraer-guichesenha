import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    await Supabase.initialize(
      url: dotenv.env['PUBLIC_SUPABASE_URL']!,
      anonKey: dotenv.env['PUBLIC_SUPABASE_ANON_KEY']!,
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
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}
