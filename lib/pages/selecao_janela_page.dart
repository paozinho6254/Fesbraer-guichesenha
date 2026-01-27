import 'package:flutter/material.dart';
import '../models/piloto.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelecaoJanelaPage extends StatefulWidget {
  final String categoria;
  final Color corTema;

  const SelecaoJanelaPage({super.key, required this.categoria, required this.corTema});

  @override
  State<SelecaoJanelaPage> createState() => _SelecaoJanelaPageState();
}

class _SelecaoJanelaPageState extends State<SelecaoJanelaPage> {
  final SupabaseService _service = SupabaseService();
  List<Piloto> _pilotosNaVila = [];
  final Set<String> _idsSelecionados = {}; // Armazena os IDs marcados
  bool _carregando = true;
  bool _enviando = false;

    Future<void> lancarJanelaParaMonitor(String categoriaAlvo) async {
    final int novoIdLote = DateTime.now().millisecondsSinceEpoch;

    try {
      await Supabase.instance.client
          .from('pilotos')
          .update({
            'status': 'aguardando',
            'janela_id': novoIdLote,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .match({'categoria': categoriaAlvo, 'status': 'inscrito'})
          .not('senha', 'is', null);

      print("Sucesso: Somente pilotos com senha receberam o ID $novoIdLote");
    } catch (e) {
      print("Erro ao lançar: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final lista = await _service.buscarPilotosPorCategoria(widget.categoria);
    setState(() {
      _pilotosNaVila = lista;
      _carregando = false;
    });
  }

  Future<void> _criarJanelaDeVoo() async {
    if (_idsSelecionados.isEmpty) return;

    setState(() => _enviando = true);
    try {
      await _service.abrirJanelaVoo(_idsSelecionados.toList());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Janela mandada para a fila!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volta para a tela anterior
      }
    } catch (e) {
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Fila: ${widget.categoria.toUpperCase()}"),
        backgroundColor: widget.corTema,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Contador e Aviso
          Container(
            padding: const EdgeInsets.all(15),
            color: widget.corTema.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Selecionados: ${_idsSelecionados.length} / 5",
                  style: TextStyle(fontWeight: FontWeight.bold, color: widget.corTema, fontSize: 16),
                ),
                if (_idsSelecionados.length == 5)
                  const Text("Limite atingido!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Lista de Pilotos
          Expanded(
            child: ListView.builder(
              itemCount: _pilotosNaVila.length,
              itemBuilder: (context, index) {
                final piloto = _pilotosNaVila[index];
                final isSelected = _idsSelecionados.contains(piloto.id);

                // Regra: Se já tem 5 e este não está selecionado, ele fica desativado
                final podeSelecionar = _idsSelecionados.length < 5 || isSelected;

                return CheckboxListTile(
                  title: Text(piloto.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Senha: ${piloto.senha} | Tel: ${piloto.telefone}"),
                  value: isSelected,
                  activeColor: widget.corTema,
                  onChanged: podeSelecionar
                      ? (bool? value) {
                    setState(() {
                      if (value == true) {
                        _idsSelecionados.add(piloto.id!);
                      } else {
                        _idsSelecionados.remove(piloto.id);
                      }
                    });
                  }
                      : null, // Desativa o clique se atingir o limite
                  secondary: CircleAvatar(
                    backgroundColor: isSelected ? widget.corTema : Colors.grey[300],
                    child: Text("${piloto.senha}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                );
              },
            ),
          ),

          // Botão de Criar Janela
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: (_idsSelecionados.isEmpty || _enviando) ? null : _criarJanelaDeVoo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.corTema,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _enviando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "CRIAR JANELA DE VOO (${_idsSelecionados.length})",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}