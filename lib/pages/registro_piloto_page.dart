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
  bool _buscandoSenha = false; // Novo loading para a senha

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

  // --- NOVA LÓGICA: Busca a senha ao clicar na categoria ---
  Future<void> _aoSelecionarCategoria(String categoria) async {
    setState(() {
      _categoriaSelecionada = categoria;
      _buscandoSenha = true;
      _senhaController.clear(); // Limpa enquanto busca
    });

    try {
      // Busca a próxima senha disponível no banco para essa categoria
      int proximaSenha = await _service.obterProximaSenha(categoria);
      
      setState(() {
        _senhaController.text = proximaSenha.toString();
      });
    } catch (e) {
      debugPrint("Erro ao buscar senha: $e");
    } finally {
      setState(() => _buscandoSenha = false);
    }
  }

  Future<void> _registrarVoo() async {
    if (_pilotoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione um piloto da lista!")),
      );
      return;
    }
    if (_categoriaSelecionada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escolha uma categoria!")),
      );
      return;
    }
    if (_senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aguarde a geração da senha!")),
      );
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
            content: Text(
              "✅ Senha ${_senhaController.text} gerada para ${_pilotoSelecionado!.nome}",
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar: $e"),
            backgroundColor: Colors.red,
          ),
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
        title: const Text(
          "Registro de Voo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _buscandoPilotos
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Buscar Piloto Inscrito",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  Autocomplete<Piloto>(
                    displayStringForOption: (Piloto p) => p.nome,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty)
                        return const Iterable<Piloto>.empty();
                      return _pilotosInscritos.where(
                        (p) => p.nome.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                      );
                    },
                    onSelected: (Piloto p) {
                      setState(() {
                        _pilotoSelecionado = p;
                        _telefoneController.text = p.telefone;
                      });
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
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

                  const Text(
                    "Selecione a Categoria",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // BOTÕES DE CATEGORIA
                  Row(
                    children: [
                      _buildCategoryOption(
                        "Acrobático",
                        const Color(0xFFE74C3C),
                        'acrobatico',
                      ),
                      const SizedBox(width: 10),
                      _buildCategoryOption(
                        "Jatos",
                        const Color(0xFF27AE60),
                        'jato',
                      ),
                      const SizedBox(width: 10),
                      _buildCategoryOption(
                        "Escala",
                        const Color(0xFF2980B9),
                        'escala',
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // --- ÁREA CONDICIONAL DA SENHA ---
                  // Só aparece se uma categoria for selecionada
                  if (_categoriaSelecionada.isNotEmpty) ...[
                    const Text(
                      "Ticket / Senha Gerada",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    
                    if (_buscandoSenha)
                      const Center(child: CircularProgressIndicator())
                    else
                      Center( // Centralizei para dar destaque ao número
                        child: SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _senhaController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            readOnly: false, // Pode deixar false caso queira corrigir manualmente
                            style: const TextStyle(
                              fontSize: 40, // Aumentei a fonte
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                            decoration: const InputDecoration(
                              hintText: "...",
                              helperText: "Sugerido automaticamente",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),

                    // O botão só aparece quando tudo está pronto
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _carregando ? null : _registrarVoo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _carregando
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "CONFIRMAR VOO",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    // Espaço vazio ou aviso para selecionar categoria
                    Container(
                      height: 100,
                      alignment: Alignment.center,
                      child: const Text(
                        "Selecione uma categoria acima para gerar a senha.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CadastroBasePage(),
                        ),
                      ),
                      child: const Text(
                        "Piloto não está na lista? Cadastre aqui",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryOption(String label, Color color, String value) {
    bool isSelected = _categoriaSelecionada == value;
    return Expanded(
      child: GestureDetector(
        // Alterado para chamar a função que busca a senha
        onTap: () => _aoSelecionarCategoria(value), 
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 2),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}