import 'package:flutter/material.dart';

class CadastroBasePage extends StatefulWidget {
  const CadastroBasePage({super.key});

  @override
  State<CadastroBasePage> createState() => _CadastroBasePageState();
}

class _CadastroBasePageState extends State<CadastroBasePage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();

  // Função que simula o salvamento no banco de dados
  void _salvarNoBanco() {
    if (_nomeController.text.isEmpty || _telefoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos!")),
      );
      return;
    }

    // Estrutura de dados que será enviada para a API futuramente
    final novoPiloto = {
      "nome": _nomeController.text,
      "telefone": _telefoneController.text,
      "categoria": "pendente", // Definido como pendente conforme solicitado
      "status": "inscrito",    // Status para indicar que ainda não pegou senha
      "senha": null,           // Ainda sem senha
    };

    print("Salvando no banco: $novoPiloto");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${_nomeController.text} cadastrado na base!")),
    );

    _nomeController.clear();
    _telefoneController.clear();
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
            const SizedBox(height: 8),
            const Text(
              "Insira os dados do piloto conforme a inscrição do Sympla. A categoria e senha serão definidas na recepção do evento.",
              style: TextStyle(color: Colors.grey),
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
                onPressed: _salvarNoBanco,
                icon: const Icon(Icons.save),
                label: const Text("SALVAR NA BASE", style: TextStyle(fontSize: 18)),
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