import 'package:flutter/material.dart';
import '../models/piloto.dart';
import '../services/supabase_service.dart';

class SelecaoPilotosPage extends StatefulWidget {
  final String categoria;
  final Color corCategoria;

  const SelecaoPilotosPage({
    super.key,
    required this.categoria,
    required this.corCategoria
  });

  @override
  State<SelecaoPilotosPage> createState() => _SelecaoPilotosPageState();
}

class _SelecaoPilotosPageState extends State<SelecaoPilotosPage> {
  final SupabaseService _service = SupabaseService();
  List<Map<String, dynamic>> _filaLocal = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarFila();
  }

  Future<void> _carregarFila() async {
    final lista = await _service.buscarFilaPorCategoria(widget.categoria);

    setState(() {
      // Criamos uma lista local que inclui a variável 'selecionado' para o Checkbox
      _filaLocal = lista.asMap().entries.map((entry) {
        int index = entry.key;
        Piloto p = entry.value;
        return {
          'piloto': p,
          'selecionado': index < 5, // Automação: seleciona os 5 primeiros
        };
      }).toList();
      _carregando = false;
    });
  }

  Future<void> _confirmarJanela() async {
    // Pegamos apenas os IDs dos que estão marcados
    final idsSelecionados = _filaLocal
        .where((item) => item['selecionado'] == true)
        .map((item) => (item['piloto'] as Piloto).id!)
        .toList();

    if (idsSelecionados.isEmpty) return;

    await _service.enviarPilotosParaPista(idsSelecionados);

    if (mounted) {
      Navigator.pop(context); // Volta para o controle
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Janela aberta! Pilotos enviados para o telão.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalSelecionados = _filaLocal.where((item) => item['selecionado']).length;

    return Scaffold(
      appBar: AppBar(
        title: Text("Fila: ${widget.categoria}"),
        backgroundColor: widget.corCategoria,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: widget.corCategoria.withOpacity(0.1),
            child: Text(
              "O sistema selecionou os 5 próximos. Ajuste se necessário:",
              style: TextStyle(color: widget.corCategoria, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filaLocal.length,
              itemBuilder: (context, index) {
                final item = _filaLocal[index];
                final Piloto p = item['piloto'];
                return CheckboxListTile(
                  title: Text("${p.senha} - ${p.nome}"),
                  subtitle: Text("Status: ${p.status}"),
                  value: item['selecionado'],
                  activeColor: widget.corCategoria,
                  onChanged: (valor) {
                    setState(() => item['selecionado'] = valor);
                  },
                );
              },
            ),
          ),
          // Botão de Confirmação
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: totalSelecionados > 0 ? _confirmarJanela : null,
                style: ElevatedButton.styleFrom(backgroundColor: widget.corCategoria),
                child: Text(
                  "ABRIR JANELA ($totalSelecionados PILOTOS)",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}