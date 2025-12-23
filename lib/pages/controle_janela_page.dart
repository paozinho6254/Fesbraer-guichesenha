import 'package:flutter/material.dart';

class ControleJanelaPage extends StatelessWidget {
  const ControleJanelaPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Valores estáticos (Mock) para os contadores.
    // Documentação: No futuro, estes valores virão de uma variável de estado
    // alimentada por uma chamada de API (ex: pilots.where((p) => p.category == 'acro').length)
    int acroCount = 0;
    int jatosCount = 0;
    int escalaCount = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova Janela de Voo", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título com espaçamento do topo
            const Padding(
              padding: EdgeInsets.only(top: 20), // 20px do topo
              child: Text(
                "Nova Janela de Voo",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            
            const Text(
              "Selecione a categoria para escolher os pilotos",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 50),

            // Botões de Categoria
            _buildCategoryButton(
              label: "Acrobático",
              count: acroCount,
              color: const Color(0xFFE74C3C), // Vermelho
              onTap: () => print("Acro selecionado"),
            ),
            
            const SizedBox(height: 12),

            _buildCategoryButton(
              label: "Jatos",
              count: jatosCount,
              color: const Color(0xFF27AE60), // Verde
              onTap: () => print("Jatos selecionado"),
            ),

            const SizedBox(height: 12),

            _buildCategoryButton(
              label: "Escala",
              count: escalaCount,
              color: const Color(0xFF2980B9), // Azul
              onTap: () => print("Escala selecionada"),
            ),

            const Spacer(), // Empurra os botões finais para o rodapé

            // Botões de Gerenciamento
            _buildManagementButton(
              label: "Visualizar Janela Atual",
              icon: Icons.remove_red_eye,
              onTap: () => print("Visualizar"),
            ),
            
            const SizedBox(height: 10),

            _buildManagementButton(
              label: "Editar Janelas Presentes",
              icon: Icons.edit,
              onTap: () => print("Editar"),
            ),
            
            const SizedBox(height: 30), // Margem inferior
          ],
        ),
      ),
    );
  }

  // Widget para os botões de categoria (com contador)
  Widget _buildCategoryButton({
    required String label, 
    required int count, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count', // Exibe o char '0' conforme solicitado
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget para os botões de rodapé (mais discretos)
  Widget _buildManagementButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: Colors.blueGrey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}