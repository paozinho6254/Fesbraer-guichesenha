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
        .order('senha', ascending: true); // Garante que a senha menor vem primeiro

    return (response as List).map((p) => Piloto.fromMap(p['id'], p)).toList();
  }

  Future<void> enviarPilotosParaPista(List<String> ids) async {
    await _supabase
        .from('pilotos')
        .update({'status': 'pista'})
        .inFilter('id', ids); // O comando in_ seleciona todos os IDs da lista
  }

  // 4. Mudar status para "Pista" (Quando os 5 são selecionados)
  Future<void> iniciarJanela(List<String> idsPilotos) async {
    await _supabase
        .from('pilotos')
        .update({'status': 'pista'})
        .inFilter('id', idsPilotos);
  }

  Future<List<Piloto>> buscarPilotosInscritos() async {
    final response = await _supabase
        .from('pilotos')
        .select()
        .eq('status', 'inscrito'); // Apenas quem ainda não foi registrado na pista

    return (response as List).map((p) => Piloto.fromMap(p['id'], p)).toList();
  }

  Future<void> gerarNovaSenhaVoo({
    required String nome,
    required String telefone,
    required String categoria,
    required int senha,
  }) async {
    await _supabase.from('pilotos').insert({
      'nome': nome,
      'telefone': telefone,
      'categoria': categoria,
      'senha': senha,
      'status': 'aguardando', // Ele entra na fila agora
      'created_at': DateTime.now().toIso8601String(),
    });
  }

}