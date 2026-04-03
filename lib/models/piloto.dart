class Piloto {
  String id;
  String nome;
  String telefone;
  String categoria;
  String status;
  int? senha;
  int? janelaId;
  String? updated_at;
  String? timerFinal;
  bool timerAtivo = false;
  int segundosRestantes = 600;

  Piloto({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.timerAtivo,
    required this.segundosRestantes,
    this.categoria = 'pendente',
    this.status = 'inscrito',
    this.senha,
    this.janelaId,
    this.updated_at,
    this.timerFinal,
  });

  // Converte para o formato que o Supabase entende (JSON/Map)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'telefone': telefone,
      'categoria': categoria,
      'status': status,
      'senha': senha,
      if (janelaId != null) 'janela_id': janelaId,
      if (updated_at != null) 'updated_at': updated_at,
      if (timerFinal != null) 'timer_final': timerFinal,
      'segundos_restantes': segundosRestantes,
    };
  }

  // Converte o que vem do Supabase de volta para o objeto Piloto
  factory Piloto.fromMap(String id, Map<String, dynamic> map) {
    return Piloto(
      id: id,
      nome: map['nome'] ?? '',
      telefone: map['telefone'] ?? '',
      categoria: map['categoria'] ?? 'pendente',
      status: map['status'] ?? 'inscrito',
      senha: map['senha'],
      janelaId: map['janela_id'],
      updated_at: map['updated_at'],
      timerFinal: map['timer_final'], // Lê do banco
      timerAtivo: map['timer_ativo'] ?? false, // Lê do banco
      segundosRestantes: map['segundos_restantes'], // Lê do banco
    );
  }
}
