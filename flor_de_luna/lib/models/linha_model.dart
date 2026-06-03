class LinhaModel {
  final String id;
  final String marca;
  final String? codigo;
  final String nomeCor;
  final double quantidade;
  final String statusEstoque; // DISPONIVEL, ACABANDO, COMPRAR

  LinhaModel({
    required this.id,
    required this.marca,
    this.codigo,
    required this.nomeCor,
    required this.quantidade,
    required this.statusEstoque,
  });

  String get marcaECodigo {
    if (codigo != null && codigo!.isNotEmpty) {
      return '$marca $codigo';
    }
    return marca;
  }
} 

