class Piloto {
  String? id;
  String nome;
  String telefone;
  String categoria;
  String status;
  int? senha;

  Piloto({
    this.id,
    required this.nome,
    required this.telefone,
    this.categoria = 'pendente',
    this.status = 'inscrito',
    this.senha,
  });

  // Converte para o formato que o Supabase entende (JSON/Map)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'telefone': telefone,
      'categoria': categoria,
      'status': status,
      'senha': senha,
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
    );
  }
}