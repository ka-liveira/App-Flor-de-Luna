// services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido_model.dart';
import '../models/linha_model.dart';
import '../models/cliente_model.dart';
import '../models/linha_resumida_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── PEDIDOS ────────────────────────────────────────────────────

  static Stream<List<PedidoModel>> streamPedidos() {
    return _db
        .collection('pedidos')
        .orderBy('dataEntrega')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => _pedidoFromDoc(doc)).toList());
  }

  static Future<void> salvarPedido(PedidoModel pedido) async {
    await _db.collection('pedidos').doc(pedido.id).set(_pedidoToMap(pedido));
  }

  static Future<void> excluirPedido(String id) async {
    await _db.collection('pedidos').doc(id).delete();
  }

  // ─── CLIENTES ───────────────────────────────────────────────────

  static Stream<List<ClienteModel>> streamClientes() {
    return _db.collection('clientes').snapshots().map((snap) =>
        snap.docs.map((doc) => ClienteModel(
              id: doc.id,
              nome: doc['nome'] ?? '',
              whatsapp: doc['observacao'] ?? '',
            )).toList());
  }

  static Future<List<ClienteModel>> buscarClientes() async {
    final snap = await _db.collection('clientes').get();
    return snap.docs.map((doc) => ClienteModel(
          id: doc.id,
          nome: doc['nome'] ?? '',
          whatsapp: doc['observacao'] ?? '',
        )).toList();
  }

  static Future<void> salvarCliente(ClienteModel cliente) async {
    await _db.collection('clientes').doc(cliente.id).set({
      'nome': cliente.nome,
      'observacao': cliente.whatsapp,
      'dataCadastro': FieldValue.serverTimestamp(),
    });
  }

  // ─── ESTOQUE ────────────────────────────────────────────────────

  static Stream<List<LinhaModel>> streamEstoque() {
    return _db.collection('estoque_linhas').snapshots().map((snap) =>
        snap.docs.map((doc) => LinhaModel(
              id: doc.id,
              marca: doc['marca'] ?? 'Sem Marca',
              codigo: doc['codigo'],
              nomeCor: doc['nomeCor'] ?? '',
              quantidade: (doc['quantidade'] as num? ?? 0).toDouble(),
              statusEstoque: doc['statusEstoque'] ?? 'DISPONIVEL',
            )).toList());
  }

  static Future<List<LinhaModel>> buscarEstoque() async {
    final snap = await _db.collection('estoque_linhas').get();
    return snap.docs.map((doc) => LinhaModel(
          id: doc.id,
          marca: doc['marca'] ?? 'Sem Marca',
          codigo: doc['codigo'] ?? '',
          nomeCor: doc['nomeCor'] ?? '',
          quantidade: (doc['quantidade'] as num? ?? 0).toDouble(),
          statusEstoque: doc['statusEstoque'] ?? 'DISPONIVEL',
        )).toList();
  }

  static Future<void> salvarLinha(LinhaModel linha) async {
    await _db.collection('estoque_linhas').doc(linha.id).set({
      'marca': linha.marca.isEmpty ? 'Sem Marca' : linha.marca,
      'codigo': linha.codigo,
      'nomeCor': linha.nomeCor,
      'quantidade': linha.quantidade,
      'statusEstoque': linha.statusEstoque,
    });
  }

  static Future<void> excluirLinha(String id) async {
    await _db.collection('estoque_linhas').doc(id).delete();
  }

  // ─── CONVERSORES ─────────────────────────────────────────────────

  static Map<String, dynamic> _pedidoToMap(PedidoModel p) {
    return {
      'clienteId': p.cliente.id,
      'clienteNome': p.cliente.nome,
      'clienteWhatsapp': p.cliente.whatsapp,
      'dataPedido': Timestamp.fromDate(p.dataPedido),
      'dataEntrega': Timestamp.fromDate(p.dataEntrega),
      'tema': p.tema,
      'textoBordar': p.textoBordar,
      'tecido': p.tejido,
      'larguraPontos': p.larguraPontos,
      'alturaPontos': p.alturaPontos,
      'linhas': p.linhas.map((l) => {
        'marca': l.marca,
        'codigo': l.codigo,
        'nomeCor': l.nomeCor,
      }).toList(),
      'valorCobrado': p.valorCobrado,
      'valorPago': p.valorPago,
      'statusProducao': p.statusProducao,
      'statusPagamento': p.statusPagamento,
      'observacoes': p.observacoes,
      'tipoPedido': p.tipoPedido,
    };
  }

  static PedidoModel _pedidoFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PedidoModel(
      id: doc.id,
      cliente: ClienteModel(
        id: data['clienteId'] ?? '',
        nome: data['clienteNome'] ?? 'Cliente sem nome',
        whatsapp: data['clienteWhatsapp'] ?? '',
      ),
      dataPedido: (data['dataPedido'] as Timestamp? ?? Timestamp.now()).toDate(),
      dataEntrega: (data['dataEntrega'] as Timestamp? ?? Timestamp.now()).toDate(),
      tema: data['tema'] ?? 'Sem tema',
      textoBordar: data['textoBordar'] ?? '',
      tejido: data['tecido'] ?? '',
      larguraPontos: data['larguraPontos'] ?? 0,
      alturaPontos: data['alturaPontos'] ?? 0,
      linhas: (data['linhas'] as List? ?? []).map((l) => LinhaResumida(
            marca: l['marca'] ?? 'Sem Marca',
            codigo: l['codigo'] ?? '',
            nomeCor: l['nomeCor'] ?? '',
          )).toList(),
      valorCobrado: (data['valorCobrado'] as num? ?? 0.0).toDouble(),
      valorPago: (data['valorPago'] as num? ?? 0.0).toDouble(),
      statusProducao: data['statusProducao'] ?? 'NA_FILA',
      statusPagamento: data['statusPagamento'] ?? 'PENDENTE',
      observacoes: data['observacoes'] ?? '',
      tipoPedido: data['tipoPedido'] ?? 'BORDADO',
    );
  }
}