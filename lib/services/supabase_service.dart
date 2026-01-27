import 'package:flutter/material.dart';
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

  Future<void> finalizarEPromoverProxima(int janelaIdAtual) async {
    // 1. Tira a janela atual da pista (move para concluído)
    await _supabase
        .from('pilotos')
        .update({'status': 'concluido'})
        .eq('janela_id', janelaIdAtual);

    // 2. Procura QUALQUER piloto que esteja aguardando
    // Ordenamos por updated_at (o mais antigo primeiro = o primeiro da fila)
    final response = await _supabase
        .from('pilotos')
        .select('janela_id')
        .eq('status', 'aguardando')
        .order('updated_at', ascending: true) // O segredo está aqui
        .limit(1);

    // 3. Se achou alguém na fila...
    if ((response as List).isNotEmpty) {
      final proximoId = response[0]['janela_id'];

      // ...Promove TODOS desse grupo para a pista
      await _supabase
          .from('pilotos')
          .update({'status': 'pista'})
          .eq('janela_id', proximoId);
    }
  }

  Future<void> gerarJanelaComPilotos({
    required List<Piloto> pilotos,
    required String categoria,
    required int senha,
  }) async {
    // Criamos um ID único para este grupo (janela)
    final int janelaId = DateTime.now().millisecondsSinceEpoch;

    // Preparamos as atualizações para cada piloto
    // Usamos Future.wait para disparar todas as atualizações ao mesmo tempo
    await Future.wait(
      pilotos.map((piloto) {
        return _supabase
            .from('pilotos')
            .update({
              'status': 'aguardando', // Vai para a fila
              'categoria': categoria,
              'senha': senha,
              'janela_id': janelaId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', piloto.id); // Filtra pelo ID único do piloto
      }),
    );
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

  Future<int> obterProximaSenha(String categoria) async {
    try {
      // Busca o registro com a maior senha para esta categoria
      final response = await _supabase
          .from('pilotos')
          .select('senha')
          .eq('categoria', categoria)
          .order('senha', ascending: false) // Ordena do maior para o menor
          .limit(1)
          .maybeSingle(); // Retorna null se não houver ninguém ainda

      if (response == null) {
        return 1; // Se for o primeiro da categoria, começa no 1
      }

      // Se já tiver, pega a última e soma 1
      return (response['senha'] as int) + 1;
    } catch (e) {
      print("Erro ao calcular próxima senha: $e");
      return 1; // Fallback seguro
    }
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

  Future<void> cancelarOuFinalizarJanela(int janelaId) async {
    await _supabase
        .from('pilotos')
        .update({
          'status': 'inscrito',
          'janela_id': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('janela_id', janelaId);
  }

  Future<void> _tratarExclusao(BuildContext context, int janelaId) async {
    // Mostra um alerta de confirmação
    bool? confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Janela"),
        content: const Text("Deseja remover este grupo da fila?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Não"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sim"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // Volta os pilotos para 'inscrito' e limpa o janela_id
      await cancelarOuFinalizarJanela(janelaId);
    }
  }
}
