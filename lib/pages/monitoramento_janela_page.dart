import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/piloto.dart';
import 'editar_janela_page.dart';
import '../services/supabase_service.dart';

class MonitoramentoPage extends StatefulWidget {
  const MonitoramentoPage({super.key});
  @override
  State<MonitoramentoPage> createState() => _MonitoramentoPageState();
}

class _MonitoramentoPageState extends State<MonitoramentoPage> {
  final SupabaseService _service = SupabaseService();
  final PageController _pageController = PageController(viewportFraction: 0.9);

  // Fluxo de dados em tempo real
  final _pilotosStream = Supabase.instance.client
      .from('pilotos')
      .stream(primaryKey: ['id'])
      .order('updated_at', ascending: true); // Garante a ordem da fila

  final _supabase = Supabase.instance.client;

  // Variáveis do Timer
  Timer? _timer;
  int _segundosRestantes = 600; // 10 minutos padrão
  bool _estaRodando = false;
  int _paginaAtual = 0;
  List<List<Piloto>> proximasJanelas = [];

  List<List<Piloto>> janelaAtual = [];
  List<List<Piloto>> janelasFila = [];
  bool _carregando = false;

  Color _getCorPorCategoria(String? categoria) {
    if (categoria == null) return Colors.grey;
    final cat = categoria.toLowerCase();
    if (cat.contains("acro")) return const Color(0xFFE74C3C);
    if (cat.contains("escala")) return const Color(0xFF3498DB);
    if (cat.contains("jato")) return const Color(0xFF2ECC71);
    return Colors.blueGrey;
  }

  @override
  void initState() {
    super.initState();
    _carregarJanelas();
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

  Future<void> _carregarJanelas() async {
    setState(() => _carregando = true);

    try {
      // 1. Busca todos os pilotos que possuem um janela_id atribuído
      // Filtramos apenas por status que não sejam 'finalizado' (ajuste conforme seu banco)
      final response = await _supabase
          .from('pilotos')
          .select()
          .not('janela_id', 'is', null)
          .order('janela_id', ascending: true);

      final List<Piloto> todosPilotosComJanela = (response as List)
          .map((p) => Piloto.fromMap(p['id'], p))
          .toList();

      // 2. Agrupar os pilotos por ID da Janela
      Map<int, List<Piloto>> grupos = {};
      for (var piloto in todosPilotosComJanela) {
        if (!grupos.containsKey(piloto.janelaId)) {
          grupos[piloto.janelaId!] = [];
        }
        grupos[piloto.janelaId]!.add(piloto);
      }

      // 3. Transformar o Map em uma lista de listas ordenada por ID da janela
      List<List<Piloto>> todasJanelas = grupos.values.toList();
      todasJanelas.sort(
        (a, b) => a.first.janelaId!.compareTo(b.first.janelaId!),
      );

      setState(() {
        if (todasJanelas.isNotEmpty) {
          // A primeira janela da lista (menor ID) é a que está na pista agora
          janelaAtual = [todasJanelas.first];

          // As demais janelas vão para a fila de "Próximas"
          janelasFila = todasJanelas.skip(1).toList();
        } else {
          janelaAtual = [];
          janelasFila = [];
        }
        _carregando = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar monitoramento: $e");
      setState(() => _carregando = false);
    }
  }

  Future<void> _excluirJanela(int janelaId) async {
    try {
      await _supabase.from('pilotos').delete().eq('janela_id', janelaId);

      setState(() {
        proximasJanelas.removeWhere(
          (grupo) => grupo.first.janelaId == janelaId,
        );

        if (_paginaAtual >= proximasJanelas.length && _paginaAtual > 0) {
          _paginaAtual = proximasJanelas.length - 1;
          _pageController.animateToPage(
            _paginaAtual,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Janela removida da fila.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao excluir: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  List<List<Piloto>> _agruparPorJanela(List<Piloto> pilotos) {
    final Map<int, List<Piloto>> grupos = {};

    for (var p in pilotos) {
      if (p.janelaId != null) {
        if (!grupos.containsKey(p.janelaId)) {
          grupos[p.janelaId!] = [];
        }
        grupos[p.janelaId]!.add(p);
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
      appBar: AppBar(title: const Text("Monitoramento")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _pilotosStream,
        builder: (context, snapshot) {
          // 1. Verificações de carregamento e erro
          if (snapshot.hasError)
            return Center(child: Text("Erro: ${snapshot.error}"));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          // 2. Converter dados brutos para Objetos Piloto
          final dadosBrutos = snapshot.data!;
          final todosPilotos = dadosBrutos
              .map((m) => Piloto.fromMap(m['id'], m))
              .toList();

          // 3. Separar: Quem é Pista vs Quem é Fila
          // Importante: Filtramos aqui na memória para ser reativo
          final pilotosPista = todosPilotos
              .where((p) => p.status == 'pista')
              .toList();
          final pilotosFila = todosPilotos
              .where((p) => p.status == 'aguardando')
              .toList();

          // 4. Agrupar a fila em janelas (ex: [Jatos, Helis])
          final janelasFila = _agruparPorJanela(pilotosFila);
          final janelaAtual = _agruparPorJanela(pilotosPista);

          return SingleChildScrollView(
            child: Column(
              children: [
                if (janelaAtual.isNotEmpty)
                  _buildCardJanela(
                    titulo:
                        "AGORA: ${janelaAtual.first.first.categoria.toUpperCase()}",
                    corDestaque: _getCorPorCategoria(
                      janelaAtual.first.first.categoria,
                    ), // Cor de destaque
                    pilotos: janelaAtual.first,
                    isFila: false,
                    widgetAdicional: _buildTimerSection(),
                    onFinalizar: () => _tratarBotaoFinalizar(
                      janelaAtual.first.first.janelaId!,
                    ),
                  )
                else
                  const SizedBox(
                    height: 150,
                    child: Center(
                      child: Text(
                        "PISTA LIVRE",
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                    ),
                  ),

                const Divider(),

                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Próximas Janelas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // --- CARROSSEL DA FILA ---
                ListView.builder(
                  shrinkWrap:
                      true, // Faz a lista ocupar apenas o espaço necessário
                  physics:
                      const NeverScrollableScrollPhysics(), // O scroll será controlado pelo pai
                  itemCount: janelasFila.length,
                  itemBuilder: (context, index) {
                    final grupo = [...janelasFila[index]]
                      ..sort((a, b) => (a.senha ?? 0).compareTo(b.senha ?? 0));

                    return _buildCardJanela(
                      titulo: grupo.first.categoria.toUpperCase(),
                      corDestaque: _getCorPorCategoria(grupo.first.categoria),
                      pilotos: grupo,
                      isFila: true,
                      onFinalizar: () => _service.cancelarOuFinalizarJanela(
                        grupo.first.janelaId!,
                      ),
                      onEditar: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditarJanelaPage(
                              janelaId: grupo.first.janelaId!,
                              categoria: grupo.first.categoria,
                              corTema: _getCorPorCategoria(
                                grupo.first.categoria,
                              ),
                              pilotosIniciais: grupo,
                            ),
                          ),
                        );
                        if (result == true) _carregarJanelas();
                      },
                    );
                  },
                ),
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
    Widget? widgetAdicional,
    VoidCallback? onFinalizar,
    VoidCallback? onEditar,
    bool isFila = false,
  }) {
    return Container(
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: corDestaque,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    Row(
                      children: [
                        if (isFila && onEditar != null)
                          ElevatedButton(
                            onPressed: onEditar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: corDestaque,
                            ),
                            child: const Text("EDITAR"),
                          ),

                        if (onFinalizar != null) ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: onFinalizar,
                            child: Text(isFila ? "EXCLUIR" : "FINALIZAR"),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (widgetAdicional != null) ...[
                  const SizedBox(height: 10),
                  widgetAdicional,
                ],
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
            child: Column(
              children: [
                pilotos.isEmpty
                    ? const Center(child: Text("Vazio"))
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const ClampingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: pilotos.length,
                        itemBuilder: (context, i) {
                          final p = pilotos[i];
                          return ListTile(
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
                                fontSize: 14,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(
          0.1,
        ), // Um fundo leve para destacar o timer
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatarTempo(_segundosRestantes),
                style: const TextStyle(
                  fontSize: 48, // Tamanho grande para o visor
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 15),
              IconButton(
                onPressed: _alternarTimer,
                icon: Icon(
                  _estaRodando
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          // Botões de ajuste de tempo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.white70,
                ),
                onPressed: () => setState(
                  () => _segundosRestantes = _segundosRestantes >= 60
                      ? _segundosRestantes - 60
                      : 0,
                ),
              ),
              const Text(
                "AJUSTAR TEMPO",
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white70,
                ),
                onPressed: () => setState(() => _segundosRestantes += 60),
              ),
            ],
          ),
        ],
      ),
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

  Future<void> _tratarBotaoFinalizar(int janelaId) async {
    try {
      // 1. Para o timer visualmente antes de começar a transição
      setState(() {
        _estaRodando = false;
        _timer?.cancel();
      });

      // 2. Chama o serviço que muda os status no Supabase
      // Isso vai disparar o StreamBuilder automaticamente
      await _service.finalizarEPromoverProxima(janelaId);

      // 3. Reseta o timer para a próxima janela que vai subir
      setState(() {
        _segundosRestantes = 600; // 10 minutos ou seu tempo padrão
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Janela concluída e próxima chamada!")),
      );
    } catch (e) {
      print("Erro ao finalizar janela: $e");
    }
  }
}
