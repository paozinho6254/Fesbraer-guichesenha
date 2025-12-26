import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. Importe o pacote

class CadastroBasePage extends StatefulWidget {
  const CadastroBasePage({super.key});

  @override
  State<CadastroBasePage> createState() => _CadastroBasePageState();
}

class _CadastroBasePageState extends State<CadastroBasePage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  bool _carregando = false; // Para mostrar um indicador de progresso

  // 2. Função de salvamento real no Supabase
  Future<void> _salvarNoSupabase() async {
    if (_nomeController.text.isEmpty || _telefoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha o nome e o telefone!")),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      // 3. Comando para inserir na tabela 'pilotos'
      await Supabase.instance.client.from('pilotos').insert({
        'nome': _nomeController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'categoria': 'pendente',
        'status': 'inscrito',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Piloto salvo com sucesso no banco!"),
            backgroundColor: Colors.green,
          ),
        );
        _nomeController.clear();
        _telefoneController.clear();
      }
    } on PostgrestException catch (error) {
      // Erro específico do banco de dados
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro no banco: ${error.message}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // Erro genérico
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro inesperado ao salvar."), backgroundColor: Colors.red),
        );
      }
    } finally {
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