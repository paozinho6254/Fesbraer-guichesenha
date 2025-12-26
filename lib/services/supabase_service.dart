import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/piloto.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // 1. Cadastro Inicial (Sua tela de Cadastro Base - Sympla)
  Future<void> cadastrarPilotoBase(String nome, String telefone) async {
    await _supabase.from('pilotos').insert({
      'nome': nome,
      'telefone': telefone,
      'status': 'inscrito',
      'categoria': 'pendente',
    });
  }

  // 2. Finalizar Registro (Sua tela de Registro - Dá a senha e categoria)
  Future<void> ativarPiloto(String id, String categoria, int senha) async {
    await _supabase.from('pilotos').update({
      'categoria': categoria,
      'senha': senha,
      'status': 'aguardando',
    }).eq('id', id);
  }

  // 3. Buscar pilotos por categoria que estão na fila (Aguardando)
  Future<List<Piloto>> buscarFilaPorCategoria(String categoria) async {
    final response = await _supabase
        .from('pilotos')
        .select()
        .eq('categoria', categoria)
        .eq('status', 'aguardando')
        .order('created_at', ascending: true);

    return (response as List).map((p) => Piloto.fromMap(p['id'], p)).toList();
  }

  // 4. Mudar status para "Pista" (Quando os 5 são selecionados)
  Future<void> iniciarJanela(List<String> idsPilotos) async {
    await _supabase
        .from('pilotos')
        .update({'status': 'pista'})
        .inFilter('id', idsPilotos);
  }
}