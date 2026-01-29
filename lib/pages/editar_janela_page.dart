import 'package:flutter/material.dart';
import '../models/piloto.dart';
import '../services/supabase_service.dart';

class EditarJanelaPage extends StatefulWidget {
  final int janelaId;
  final String categoria;
  final Color corTema;
  final List<Piloto> pilotosIniciais;

  const EditarJanelaPage({
    super.key,
    required this.janelaId,
    required this.categoria,
    required this.corTema,
    required this.pilotosIniciais,
  });

  @override
  State<EditarJanelaPage> createState() => _EditarJanelaPageState();
}

class _EditarJanelaPageState extends State<EditarJanelaPage> {
  final SupabaseService _service = SupabaseService();
  bool _carregando = true;

  List<Piloto> _pilotosNaJanela = [];
  List<Piloto> _pilotosDisponiveis = [];

  @override
  void initState() {
    super.initState();
    _pilotosNaJanela = List.from(widget.pilotosIniciais);
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    // Busca pilotos da mesma categoria que estão sem janela (janelaId == null)
    final disponiveis = await _service.buscarPilotosPorCategoria(
      widget.categoria,
    );
    setState(() {
      _pilotosDisponiveis = disponiveis;
      _carregando = false;
    });
  }

  Future<void> _confirmarExclusao(Piloto piloto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Inscrição?"),
        content: Text(
          "Deseja realmente remover ${piloto.nome} do evento?\n\n"
          "Esta ação não pode ser desfeita e ele sairá da fila de espera.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _carregando = true);
      try {
        // 1. Remove do Supabase
        await _service.excluirPiloto(int.parse(piloto.id));

        // 2. Remove da lista local para atualizar a tela
        setState(() {
          _pilotosDisponiveis.removeWhere((p) => p.id == piloto.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${piloto.nome} foi removido.")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erro ao excluir: $e")));
        }
      } finally {
        setState(() => _carregando = false);
      }
    }
  }

  // Move o piloto da janela para a lista de espera (janelaId vira null localmente)
  void _removerDaJanela(Piloto piloto) {
    setState(() {
      _pilotosNaJanela.remove(piloto);
      _pilotosDisponiveis.add(piloto);
      _pilotosDisponiveis.sort((a, b) => a.senha!.compareTo(b.senha!));
    });
  }

  // Move o piloto da espera para a janela
  void _adicionarNaJanela(Piloto piloto) {
    if (_pilotosNaJanela.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Limite de 5 pilotos atingido!")),
      );
      return;
    }
    setState(() {
      _pilotosDisponiveis.remove(piloto);
      _pilotosNaJanela.add(piloto);
    });
  }

  Future<void> _salvarAlteracoes() async {
    setState(() => _carregando = true);
    try {
      // 1. Quem saiu da janela: seta janelaId como NULL no banco
      // 2. Quem entrou na janela: seta janelaId como widget.janelaId no banco
      await _service.atualizarMembrosJanela(
        janelaId: widget.janelaId,
        membrosAtuais: _pilotosNaJanela,
        membrosRemovidos: _pilotosDisponiveis,
      );

      if (mounted) {
        // Retornamos 'true' para avisar a tela anterior que houve mudança
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e")));
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Editar Fila: ${widget.categoria.toUpperCase()}"),
        backgroundColor: widget.corTema,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // SEÇÃO 1: PILOTOS NA JANELA
                _buildHeaderSection(
                  "PILOTOS NA JANELA",
                  _pilotosNaJanela.length,
                  Colors.amber,
                ),
                Expanded(
                  child: ListView(
                    children: _pilotosNaJanela
                        .map((p) => _buildTilePiloto(p, isInJanela: true))
                        .toList(),
                  ),
                ),

                const Divider(height: 1, thickness: 2),

                // SEÇÃO 2: PILOTOS DISPONÍVEIS (FILA)
                _buildHeaderSection(
                  "FILA DE ESPERA (DISPONÍVEIS)",
                  _pilotosDisponiveis.length,
                  Colors.blueGrey,
                ),
                Expanded(
                  flex: 2, // Dá mais espaço para a fila de espera
                  child: ListView(
                    children: _pilotosDisponiveis
                        .map((p) => _buildTilePiloto(p, isInJanela: false))
                        .toList(),
                  ),
                ),

                // BOTÃO SALVAR
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.corTema,
                      ),
                      onPressed: _salvarAlteracoes,
                      child: const Text(
                        "CONFIRMAR ALTERAÇÕES",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderSection(String titulo, int total, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: cor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: TextStyle(fontWeight: FontWeight.bold, color: cor),
          ),
          Text(
            "$total Pilotos",
            style: TextStyle(fontWeight: FontWeight.bold, color: cor),
          ),
        ],
      ),
    );
  }

  Widget _buildTilePiloto(Piloto piloto, {required bool isInJanela}) {
    return ListTile(
      // Removido o CircleAvatar, usando um SizedBox para alinhar o texto
      leading: SizedBox(
        width: 45,
        child: Center(
          child: Text(
            "${piloto.senha}",
            style: TextStyle(
              fontSize: 24, // Senha bem grande
              fontWeight: FontWeight.bold, // Bem negrito
              color: widget.corTema.withOpacity(isInJanela ? 1 : 0.6),
            ),
          ),
        ),
      ),
      title: Text(
        piloto.nome,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(piloto.telefone),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isInJanela)
            IconButton(
              icon: const Icon(Icons.output_rounded, color: Colors.orange),
              onPressed: () => _removerDaJanela(piloto),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
              onPressed: () => _adicionarNaJanela(piloto),
            ),
            // Botão excluir (Lixeira) para remover do evento
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmarExclusao(piloto),
            ),
          ],
        ],
      ),
    );
  }
}
