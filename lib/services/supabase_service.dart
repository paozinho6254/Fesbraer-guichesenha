import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/piloto.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // Função para cadastrar o piloto vindo do Sympla (Cadastro Base)
  Future<void> cadastrarPilotoBase(String nome, String telefone) async {
    await _supabase.from('pilotos').insert({
      'nome': nome,
      'telefone': telefone,
      'status': 'inscrito',
      'categoria': 'pendente',
    });
  }

  // Função para buscar inscritos (usada no Autocomplete da próxima tela)
  Future<List<Piloto>> buscarInscritos() async {
    final response = await _supabase
        .from('pilotos')
        .select()
        .eq('status', 'inscrito');

    return (response as List).map((p) => Piloto.fromMap(p['id'], p)).toList();
  }
}