import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart'; // 1. Importe o pacote

class CadastroBasePage extends StatefulWidget {
  const CadastroBasePage({super.key});

  @override
  State<CadastroBasePage> createState() => _CadastroBasePageState();
}

class _CadastroBasePageState extends State<CadastroBasePage> {
  final SupabaseService _service = SupabaseService();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  bool _carregando = false; // Para mostrar um indicador de progresso

  var maskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  // 2. Função de salvamento real no Supabase
  Future<void> _salvarNoSupabase() async {
    // 1. Validação simples: Nome não pode ser vazio e telefone deve estar completo
    // O telefone com máscara (XX) XXXXX-XXXX tem 15 caracteres
    if (_nomeController.text.trim().isEmpty || _telefoneController.text.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Preencha o nome e o telefone completo!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 2. Inicia o estado de carregamento (o botão fica desativado e mostra o girinho)
    setState(() => _carregando = true);

    try {
      // 3. Envia para o seu Service
      await _service.cadastrarPilotoBase(
        _nomeController.text.trim(),
        _telefoneController.text, // Salva o texto já com a máscara
      );

      // 4. Se deu certo, limpa tudo e avisa o usuário
      if (mounted) {
        _nomeController.clear();
        _telefoneController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Piloto cadastrado!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // 5. Se der erro (ex: internet caiu), avisa o erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Erro ao salvar: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      // 6. Volta o botão ao estado normal, independente de ter dado erro ou certo
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Importar Inscrito Sympla")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cadastro Pré-Evento",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: "Nome do Piloto",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _telefoneController,
              inputFormatters: [maskFormatter], // Aplica a máscara aqui
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Telefone / WhatsApp",
                hintText: "(00) 00000-0000",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                // 4. Se estiver carregando, desativa o botão
                onPressed: _carregando ? null : _salvarNoSupabase,
                icon: _carregando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload),
                label: Text(_carregando ? "SALVANDO..." : "SALVAR NO SUPABASE", style: const TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}