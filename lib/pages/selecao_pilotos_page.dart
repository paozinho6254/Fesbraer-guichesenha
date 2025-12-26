import 'package:flutter/material.dart';

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
  // Simulação de banco de dados (Mock)
  // Na vida real, isso viria de um GET /pilotos?status=aguardando&categoria=...
  List<Map<String, dynamic>> pilotosDaFila = [
    {'senha': 101, 'nome': 'João Silva', 'selecionado': true},
    {'senha': 102, 'nome': 'Marcos Pereira', 'selecionado': true},
    {'senha': 103, 'nome': 'Jorge Santos', 'selecionado': true},
    {'senha': 104, 'nome': 'Benício Ramos', 'selecionado': true},
    {'senha': 105, 'nome': 'Lenilson Porto', 'selecionado': true},
    {'senha': 106, 'nome': 'Cristiano Ronaldo', 'selecionado': false},
    {'senha': 107, 'nome': 'Ayrton Senna', 'selecionado': false},
  ];

  @override
  Widget build(BuildContext context) {
    // Filtramos apenas os que o sistema marcou como os 5 primeiros
    int totalSelecionados = pilotosDaFila.where((p) => p['selecionado']).length;

    return Scaffold(
      appBar: AppBar(
        title: Text("Fila: ${widget.categoria}"),
        backgroundColor: widget.corCategoria,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: widget.corCategoria.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blueGrey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "O sistema selecionou automaticamente os 5 próximos pilotos da categoria ${widget.categoria}.",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: pilotosDaFila.length,
              itemBuilder: (context, index) {
                final piloto = pilotosDaFila[index];
                return CheckboxListTile(
                  title: Text("${piloto['senha']} - ${piloto['nome']}"),
                  subtitle: Text(piloto['selecionado'] ? "Selecionado para esta janela" : "Na fila de espera"),
                  value: piloto['selecionado'],
                  activeColor: widget.corCategoria,
                  onChanged: (bool? valor) {
                    setState(() {
                      piloto['selecionado'] = valor!;
                    });
                  },
                );
              },
            ),
          ),

          // Rodapé com resumo e botão de confirmação
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
            ),
            child: Column(
              children: [
                Text(
                  "Pilotos selecionados: $totalSelecionados / 5",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: totalSelecionados == 5 ? Colors.green : Colors.orange
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: totalSelecionados == 5
                        ? () {
                      // Lógica para criar a janela e enviar para o banco
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Janela criada com sucesso!"))
                      );
                      Navigator.pop(context);
                    }
                        : null, // Desabilita se não tiver 5
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.corCategoria,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: const Text(
                        "CONFIRMAR JANELA",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}