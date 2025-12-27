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

  // Buscar pilotos aguardando por categoria (Ordenados por senha)
  Future<List<Piloto>> buscarFilaPorCategoria(String categoria) async {
    final response = await _supabase
        .from('pilotos')
        .select()
        .eq('categoria', categoria)
        .eq('status', 'aguardando')
        .order('senha', ascending: true); // Garante que a senha menor vem primeiro

    return (response as List).map((p) => Piloto.fromMap(p['id'], p)).toList();
  }

// Mudar o status dos 5 selecionados para 'pista'
  Future<void> enviarPilotosParaPista(List<String> ids) async {
    await _supabase
        .from('pilotos')
        .update({'status': 'pista'})
        .inFilter('id', ids); // O comando in_ seleciona todos os IDs da lista
  }

  Future<void> gerarNovaSenhaVoo({
    required String nome,
    required String telefone,
    required String categoria,
    required int senha,
  }) async {
    // Usamos INSERT em vez de update para permitir que o piloto
    // tenha vários registros (um para cada voo/categoria)
    await _supabase.from('pilotos').insert({
      'nome': nome,
      'telefone': telefone,
      'categoria': categoria,
      'senha': senha,
      'status': 'aguardando', // Ele entra na fila
      'created_at': DateTime.now().toIso8601String(),
    });
  }

}