import 'package:flutter/material.dart';
import 'controle_janela_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), 
      body: Column(
        children: [
          // Espaço da logo do Fesbraer de 60% da tela
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              child: Center(
                // Substituir depois pela logo o ICON
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.airplanemode_active, 
                      size: 120, 
                      color: Color(0xFF2C3E50),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "FESBRAER",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Espaço dos Botões 40%
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  _buildMenuButton(
                    context,
                    label: "CADASTRAR PILOTO",
                    icon: Icons.person_add_alt_1,
                    color: const Color(0xFF27AE60),
                    onTap: () {
                      // Caminho: Navigator para tela de cadastro
                      print("Indo para Cadastro...");
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildMenuButton(
                    context,
                    label: "JANELAS DE VOO",
                    icon: Icons.view_list_rounded,
                    color: const Color(0xFF2980B9), // Azul para controle
                    onTap: () {
                      // Caminho: Navigator para tela de controle
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ControleJanelaPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para criar botões padronizados e grandes
  Widget _buildMenuButton(BuildContext context, 
      {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 80, // Botão alto para facilitar o toque
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 28, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
      ),
    );
  }
}