class DiretoStatus {
  final int codigo;
  final String situacao;
  final String? descricao;
  final DateTime criado;
  final DateTime? modificado;
  final int id;

  const DiretoStatus({
    required this.codigo,
    required this.situacao,
    required this.descricao,
    required this.criado,
    required this.modificado,
    required this.id,
  });

  factory DiretoStatus.fromJson(Map<String, dynamic> json) {
    return DiretoStatus(
      codigo: (json['codigo'] as num).toInt(),
      situacao: json['situacao'] as String,
      descricao: json['descricao'] as String?,
      criado: DateTime.parse(json['criado'] as String),
      modificado: json['modificado'] == null
          ? null
          : DateTime.parse(json['modificado'] as String),
      id: (json['id'] as num).toInt(),
    );
  }
}
