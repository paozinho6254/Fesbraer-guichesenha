import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'cadastro_base_page.dart';

class RegistroPilotoPage extends StatefulWidget {
  const RegistroPilotoPage({super.key});

  @override
  State<RegistroPilotoPage> createState() => _RegistroPilotoPageState();
}

class _RegistroPilotoPageState extends State<RegistroPilotoPage> {

  var maskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  // Controladores para capturar o texto dos campos
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  
  String _categoriaSelecionada = ''; // Armazena a categoria escolhida

  // Função para limpar o formulário após salvar
  void _limparCampos() {
    _nomeController.clear();
    _telefoneController.clear();
    _senhaController.clear();
    setState(() {
      _categoriaSelecionada = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro de Piloto", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dados do Piloto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // Campo Nome
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: "Nome Completo",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // Campo Telefone
            TextField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Telefone (WhatsApp)",
                hintText: "(00) 00000-0000",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),

            const Text("Selecione a Categoria", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // Grade de Seleção de Categorias
            Row(
              children: [
                _buildCategoryOption("Acrobático", const Color(0xFFE74C3C), 'acro'),
                const SizedBox(width: 10),
                _buildCategoryOption("Jatos", const Color(0xFF27AE60), 'jato'),
                const SizedBox(width: 10),
                _buildCategoryOption("Escala", const Color(0xFF2980B9), 'escala'),
              ],
            ),
            const SizedBox(height: 25),

            const Text("Identificação", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // Campo Senha (Ticket Físico)
            SizedBox(
              width: 200,
              child: TextField(
                controller: _senhaController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: "Nº da Senha",
                  floatingLabelAlignment: FloatingLabelAlignment.center,
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  // Aqui entrará a chamada da API POST /pilotos
                  final snackBar = SnackBar(
                    content: Text('Piloto ${_nomeController.text} cadastrado com sucesso!'),
                    backgroundColor: Colors.green,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  _limparCampos();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  "SALVAR E GERAR TICKET",
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Atalho para Cadastro Base
            Center(
              child: TextButton(
                onPressed: () {
                  // Redireciona para a tela de Cadastro Base
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CadastroBasePage()),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    children: [
                      TextSpan(text: "Piloto não está na lista? "),
                      TextSpan(
                        text: "Cadastre aqui",
                        style: TextStyle(
                          color: Color(0xFF2980B9),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
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

  // Widget para os botões de opção de categoria
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
            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}