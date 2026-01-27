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

  Future<List<Piloto>> buscarPilotosPorCategoria(String categoria) async {
    final response = await _supabase
        .from('pilotos')
        .select()
        .eq('categoria', categoria);

    final todosOsPilotos = (response as List)
        .map((m) => Piloto.fromMap(m['id'], m))
        .toList();

    return todosOsPilotos.where((p) {
      bool temSenha = p.senha != null;
      bool semJanela = p.janelaId == null;
      bool naoConcluiu = p.status != 'concluido';

      return temSenha && semJanela && naoConcluiu;
    }).toList();
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

  Future<void> abrirJanelaVoo(List<String> idsPilotos) async {
    final int novoJanelaId = DateTime.now().millisecondsSinceEpoch;

    // 1. Verifica se existe alguém voando agora (status 'pista')
    final respostaPista = await _supabase
        .from('pilotos')
        .select('id')
        .eq('status', 'pista')
        .limit(1);

    // Se não houver ninguém, a pista está livre
    bool pistaLivre = (respostaPista as List).isEmpty;
    String statusDestino = pistaLivre ? 'pista' : 'aguardando';

    // 2. Atualiza os pilotos selecionados
    await _supabase
        .from('pilotos')
        .update({
          'status': statusDestino,
          'janela_id': novoJanelaId,
          'updated_at': DateTime.now()
              .toIso8601String(), // Garanta que o nome aqui é igual ao do banco
        })
        .inFilter('id', idsPilotos);
  }

  Stream<List<Piloto>> ouvirPilotosNaPista() {
    return _supabase
        .from('pilotos')
        .stream(primaryKey: ['id'])
        .eq('status', 'pista') // Filtra apenas quem está na pista agora
        .map(
          (data) => data.map((map) => Piloto.fromMap(map['id'], map)).toList(),
        );
  }

  // Método para quando o piloto terminar o voo e sair do telão
  Future<void> finalizarVoo(String id) async {
    await _supabase
        .from('pilotos')
        .update({'status': 'finalizado'})
        .eq('id', id);
  }
}
