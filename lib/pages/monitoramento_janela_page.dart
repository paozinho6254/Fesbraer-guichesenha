import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/piloto.dart'; // Certifique-se que o caminho está correto

class MonitoramentoJanelaPage extends StatefulWidget {
  const MonitoramentoJanelaPage({super.key});

  @override
  State<MonitoramentoJanelaPage> createState() =>
      _MonitoramentoJanelaPageState();
}

class _MonitoramentoJanelaPageState extends State<MonitoramentoJanelaPage> {
  final _supabase = Supabase.instance.client;

  // Variáveis do Timer
  Timer? _timer;
  int _segundosRestantes = 600; // 10 minutos padrão
  bool _estaRodando = false;

  // Variáveis do Carrossel
  final PageController _pageController = PageController();
  int _paginaAtual = 0;

  Color _getCorPorCategoria(String? categoria) {
    if (categoria == null) return Colors.grey;
    final cat = categoria.toLowerCase();
    if (cat.contains("acro")) return const Color(0xFFE74C3C);
    if (cat.contains("escala")) return const Color(0xFF3498DB);
    if (cat.contains("jato")) return const Color(0xFF2ECC71);
    return Colors.blueGrey;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // --- LÓGICA DO TIMER ---
  void _alternarTimer() {
    if (_estaRodando) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_segundosRestantes > 0) {
            _segundosRestantes--;
          } else {
            _timer?.cancel();
            _estaRodando = false;
          }
        });
      });
    }
    setState(() => _estaRodando = !_estaRodando);
  }

  void _reiniciarTimer() {
    setState(() {
      _timer?.cancel();
      _estaRodando = false;
      _segundosRestantes = 600; // Volta para 10 minutos
    });
  }

  String _formatarTempo(int segundos) {
    Duration duration = Duration(seconds: segundos);
    String doisDigitos(int n) => n.toString().padLeft(2, "0");
    String horas = doisDigitos(duration.inHours);
    String minutos = doisDigitos(duration.inMinutes.remainder(60));
    String segs = doisDigitos(duration.inSeconds.remainder(60));
    return "$horas:$minutos:$segs";
  }

  // --- LÓGICA DO BANCO ---
  Future<void> _limparSistema() async {
    // Deleta todos os pilotos (Filtro 'neq' com ID impossível limpa tudo)
    await _supabase
        .from('pilotos')
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sistema reiniciado com sucesso!")),
    );
  }

  List<List<Piloto>> _agruparPorJanela(List<Piloto> lista) {
    if (lista.isEmpty) return [];

    lista.sort((a, b) => (a.senha ?? 0).compareTo(b.senha ?? 0));

    Map<int, List<Piloto>> grupos = {};

    for (var piloto in lista) {
      if (piloto.janelaId != null) {
        int id = piloto.janelaId!;

        if (!grupos.containsKey(id)) {
          grupos[id] = [];
        }
        grupos[id]!.add(piloto);
      }
    }
    return grupos.values.toList();
  }

  Future<void> finalizarJanelaAtual(int idDaJanela) async {
    try {
      await _supabase
          .from('pilotos')
          .update({'status': 'concluido'}) // Marca como finalizado
          .eq('janela_id', idDaJanela); // Filtra pelo ID do lote todo

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Janela finalizada com sucesso!")),
      );
    } catch (e) {
      print("Erro ao finalizar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "CONTROLE DE VOO",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () => _mostrarConfirmacaoLimpeza(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('pilotos')
            .stream(primaryKey: ['id'])
            .order('senha', ascending: true), // O mais recente primeiro!

        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final todos = snapshot.data!
              .map((m) => Piloto.fromMap(m['id'], m))
              .toList();

          // 1. JANELA ATUAL: Pega apenas quem tem status 'pista'
          // Como ordenamos por updated_at DESC, os pilotos que acabaram de entrar na pista estarão no topo
          final pilotosNaPista = todos
              .where((p) => p.status == 'pista')
              .toList();
          final janelasNaPista = _agruparPorJanela(pilotosNaPista);

          // A Janela Atual será sempre o primeiro grupo da lista de pista
          final janelaAtual = janelasNaPista.isNotEmpty
              ? janelasNaPista[0]
              : <Piloto>[];

          // 2. PRÓXIMAS JANELAS:
          // Inclui: outras categorias que por acaso estejam na pista + todos que estão 'aguardando'
          final janelasFila = _agruparPorJanela(
            todos.where((p) => p.status == 'aguardando').toList(),
          );

          final proximasJanelas = [
            if (janelasNaPista.length > 1) ...janelasNaPista.sublist(1),
            ...janelasFila,
          ];

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildCardJanela(
                  titulo: "JANELA ATUAL",
                  corDestaque: _getCorPorCategoria(
                    janelaAtual.isNotEmpty ? janelaAtual[0].categoria : null,
                  ),
                  pilotos: janelaAtual,
                  vazioTexto: "AGUARDANDO CHAMADA",
                  onFinalizar: janelaAtual.isNotEmpty
                      ? () => finalizarJanelaAtual(janelaAtual[0].janelaId ?? 0)
                      : null,
                ),

                _buildTimerSection(),

                const SizedBox(height: 20),
                const Text(
                  "Próximas Janelas",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                // --- CARROSSEL ---
                SizedBox(
                  height: 380,
                  child: proximasJanelas.isEmpty
                      ? const Center(
                          child: Text(
                            "FILA VAZIA",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          onPageChanged: (page) =>
                              setState(() => _paginaAtual = page),
                          itemCount: proximasJanelas.length,
                          itemBuilder: (context, index) {
                            final grupo = proximasJanelas[index];
                            return _buildCardJanela(
                              titulo:
                                  "PRÓXIMA: ${grupo[0].categoria.toUpperCase()}",
                              corDestaque: _getCorPorCategoria(
                                grupo[0].categoria,
                              ),
                              pilotos: grupo,
                            );
                          },
                        ),
                ),

                // Indicador de bolinhas
                if (proximasJanelas.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      proximasJanelas.length,
                      (index) => _buildDot(index == _paginaAtual),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardJanela({
    required String titulo,
    required Color corDestaque,
    required List<Piloto> pilotos,
    String? vazioTexto,
    VoidCallback? onFinalizar,
  }) {
    return Container(
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: corDestaque,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (onFinalizar != null && pilotos.isNotEmpty)
                  ElevatedButton(
                    onPressed: onFinalizar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      "FINALIZAR",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Editar",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Editar",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(15, 0, 15, 20),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: pilotos.isEmpty
                ? SizedBox(
                    height: 100,
                    child: Center(child: Text(vazioTexto ?? "Vazio")),
                  )
                : Column(
                    children: pilotos
                        .map(
                          (p) => ListTile(
                            leading: Text(
                              "${p.senha}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            title: Text(
                              p.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatarTempo(_segundosRestantes),
              style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: _alternarTimer,
              icon: Icon(
                _estaRodando
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                size: 50,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _btnTimer(
              Icons.remove,
              () => setState(
                () => _segundosRestantes = (_segundosRestantes >= 60)
                    ? _segundosRestantes - 60
                    : 0,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("TEMPO"),
            ),
            _btnTimer(
              Icons.add,
              () => setState(() => _segundosRestantes += 60),
            ),
          ],
        ),
      ],
    );
  }

  Widget _btnTimer(IconData icon, VoidCallback action) {
    return IconButton(
      onPressed: action,
      icon: Icon(icon, size: 30),
      color: Colors.black,
    );
  }

  Widget _buildDot(bool active) {
    return Container(
      margin: const EdgeInsets.all(4),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? Colors.black : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  void _mostrarConfirmacaoLimpeza() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Limpar Sistema?"),
        content: const Text(
          "Isso apagará TODOS os pilotos e janelas. Esta ação não pode ser desfeita.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              _limparSistema();
              Navigator.pop(context);
            },
            child: const Text(
              "LIMPAR TUDO",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
