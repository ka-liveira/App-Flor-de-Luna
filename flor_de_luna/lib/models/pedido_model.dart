// models/pedido_model.dart
import 'cliente_model.dart';
import 'linha_resumida_model.dart';

class PedidoModel {
  final String id;
  final ClienteModel cliente;
  final DateTime dataPedido;
  final DateTime dataEntrega;
  final String tema;
  final String textoBordar;
  final String tejido;
  final int larguraPontos;
  final int alturaPontos;
  final List<LinhaResumida> linhas;
  final double valorCobrado;
  final double valorPago;
  final String statusProducao; // NA_FILA, EM_PRODUCAO, CONCLUIDO, ENTREGUE
  final String statusPagamento; // PENDENTE, PAGO_PARCIAL, QUITADO
  final String observacoes;
  final String tipoPedido; // BORDADO, ARTESANATO

  PedidoModel({
    required this.id,
    required this.cliente,
    required this.dataPedido,
    required this.dataEntrega,
    required this.tema,
    required this.textoBordar,
    required this.tejido,
    required this.larguraPontos,
    required this.alturaPontos,
    required this.linhas,
    required this.valorCobrado,
    required this.valorPago,
    required this.statusProducao,
    required this.statusPagamento,
    required this.observacoes,
    this.tipoPedido = 'BORDADO',
  });

  double get valorRestante => valorCobrado - valorPago;

  int get diasParaEntrega {
    final hoje = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final entrega = DateTime(dataEntrega.year, dataEntrega.month, dataEntrega.day);
    return entrega.difference(hoje).inDays;
  }

  bool get entregaProxima => diasParaEntrega <= 5 && diasParaEntrega >= 0;
  bool get isArtesanato => tipoPedido == 'ARTESANATO';
}