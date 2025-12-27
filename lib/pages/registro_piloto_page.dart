import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../models/piloto.dart';
import '../services/supabase_service.dart';
import 'cadastro_base_page.dart';

class RegistroPilotoPage extends StatefulWidget {
  const RegistroPilotoPage({super.key});

  @override
  State<RegistroPilotoPage> createState() => _RegistroPilotoPageState();
}

class _RegistroPilotoPageState extends State<RegistroPilotoPage> {
  final SupabaseService _service = SupabaseService();
  bool _carregando = false;
  bool _buscandoPilotos = true;

  var maskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  Piloto? _pilotoSelecionado;
  String _categoriaSelecionada = '';
  List<Piloto> _pilotosInscritos = [];

  @override
  void initState() {
    super.initState();
    _carregarPilotosBase();
  }

  // Busca os pilotos que foram importados do Sympla
  Future<void> _carregarPilotosBase() async {
    try {
      final lista = await _service.buscarInscritos();
      setState(() {
        _pilotosInscritos = lista;
        _buscandoPilotos = false;
      });
    } catch (e) {
      setState(() => _buscandoPilotos = false);
      debugPrint("Erro ao carregar pilotos: $e");
    }
  }

  Future<void> _registrarVoo() async {
    // Validações
    if (_pilotoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione um piloto da lista!")));
      return;
    }
    if (_categoriaSelecionada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Escolha uma categoria!")));
      return;
    }
    if (_senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Informe o número da senha!")));
      return;
    }

    setState(() => _carregando = true);

    try {
      await _service.gerarNovaSenhaVoo(
        nome: _pilotoSelecionado!.nome,
        telefone: _telefoneController.text,
        categoria: _categoriaSelecionada,
        senha: int.parse(_senhaController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Senha ${_senhaController.text} gerada para ${_pilotoSelecionado!.nome}"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Volta para a Home após sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro de Voo (Gerar Senha)", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _buscandoPilotos
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Buscar Piloto Inscrito", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // AUTOCOMPLETE para buscar pelo nome
            Autocomplete<Piloto>(
              displayStringForOption: (Piloto p) => p.nome,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<Piloto>.empty();
                return _pilotosInscritos.where((p) => p.nome.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (Piloto p) {
                setState(() {
                  _pilotoSelecionado = p;
                  _telefoneController.text = p.telefone;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: "Comece a digitar o nome...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _telefoneController,
              inputFormatters: [maskFormatter],
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Telefone (Confirmar)",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),

            const Text("Selecione a Categoria deste Voo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            Row(
              children: [
                _buildCategoryOption("Acrobático", const Color(0xFFE74C3C), 'acrobatico'),
                const SizedBox(width: 10),
                _buildCategoryOption("Jatos", const Color(0xFF27AE60), 'jato'),
                const SizedBox(width: 10),
                _buildCategoryOption("Escala", const Color(0xFF2980B9), 'escala'),
              ],
            ),
            const SizedBox(height: 25),

            const Text("Ticket Físico", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            SizedBox(
              width: 200,
              child: TextField(
                controller: _senhaController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: "Nº da Senha",
                  floatingLabelAlignment: FloatingLabelAlignment.center,
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Botão Salvar com LOGICA DE LOADING
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _carregando ? null : _registrarVoo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SALVAR E ENVIAR PARA FILA", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CadastroBasePage())),
                child: const Text("Piloto não está na lista? Cadastre aqui", style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOption(String label, Color color, String value) {
    bool isSelected = _categoriaSelecionada == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _categoriaSelecionada = value),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}