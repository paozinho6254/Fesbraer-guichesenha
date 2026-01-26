import 'package:flutter/material.dart';

class MonitoramentoJanelasPage extends StatefulWidget {
  const MonitoramentoJanelasPage({super.key});

  @override
  State<MonitoramentoJanelasPage> createState() =>
      _MonitoramentoJanelasPageState();
}

class _MonitoramentoJanelasPageState extends State<MonitoramentoJanelasPage> {
  int _minutosTimer = 10;
  bool _isTimerRunning = false;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSecaoJanela(
              titulo: "JANELA ATUAL",
              corFundo: Colors.red,
              pilotos: [
                "João S.",
                "Marcos P.",
                "Jorge S.",
                "Benício R.",
                "Lenilson P.",
              ],
              senhas: ["101", "102", "103", "104", "105"],
            ),

            _buildTimerSection(),

            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return _buildSecaoJanela(
                          titulo: "Próximas janelas",
                          corFundo: Colors.green,
                          pilotos: [
                            "Ítalo M.",
                            "Jorge P.",
                            "Paulo B.",
                            "João S.",
                            "Jerson P.",
                          ],
                          senhas: ["94", "95", "96", "97", "98"],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => _buildDot(index == 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoJanela({
    required String titulo,
    required Color corFundo,
    required List<String> pilotos,
    required List<String> senhas,
  }) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40), 
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Editar janela",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          ...List.generate(
            pilotos.length,
            (i) => _buildLinhaPiloto(senhas[i], pilotos[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaPiloto(String senha, String nome) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            senha,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(width: 15),
          Text(
            nome,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
              "$_minutosTimer:00:00",
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.play_arrow, size: 40),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => setState(() => _minutosTimer--),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            const Text("TEMPO", style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () => setState(() => _minutosTimer++),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}
