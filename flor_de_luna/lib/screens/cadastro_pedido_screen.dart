// screens/cadastro_pedido_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/linha_model.dart';
import '../models/pedido_model.dart';
import '../models/cliente_model.dart';
import '../models/linha_resumida_model.dart';
import '../services/firestore_service.dart';

class CadastroPedidoScreen extends StatefulWidget {
  final PedidoModel? pedido;

  const CadastroPedidoScreen({super.key, this.pedido});

  @override
  State<CadastroPedidoScreen> createState() => _CadastroPedidoScreenState();
}

class _CadastroPedidoScreenState extends State<CadastroPedidoScreen> {
  final _temaController = TextEditingController();
  final _textoController = TextEditingController();
  final _tecidoController = TextEditingController();
  final _larguraController = TextEditingController();
  final _alturaController = TextEditingController();
  final _valorController = TextEditingController();
  final _entradaController = TextEditingController();
  final _observacoesController = TextEditingController();

  ClienteModel? _clienteSelecionado;
  DateTime? _dataEntrega;
  List<LinhaResumida> _linhasSelecionadas = [];
  String _statusProducao = 'NA_FILA';
  String _tipoPedidoAtivo = 'BORDADO';

  List<LinhaModel> _estoqueLinhas = [];
  bool _carregandoEstoque = true;

  static const double _pontosPorCm = 5.0;
  static const double _margemTecido = 10.0;
  static const double _pontosPorHora = 100.0;
  static const double _valorHora = 5.0;
  static const double _materialFixo = 10.0;

  @override
  void initState() {
    super.initState();
    if (widget.pedido != null) {
      final p = widget.pedido!;
      _clienteSelecionado = p.cliente;
      _dataEntrega = p.dataEntrega;
      _linhasSelecionadas = List.from(p.linhas);
      _statusProducao = p.statusProducao;
      _tipoPedidoAtivo = p.tipoPedido;
      _temaController.text = p.tema;
      _textoController.text = p.textoBordar;
      _tecidoController.text = p.tejido;
      _larguraController.text = p.larguraPontos > 0 ? p.larguraPontos.toString() : '';
      _alturaController.text = p.alturaPontos > 0 ? p.alturaPontos.toString() : '';
      _valorController.text = p.valorCobrado > 0 ? p.valorCobrado.toStringAsFixed(2) : '';
      _entradaController.text = p.valorPago > 0 ? p.valorPago.toStringAsFixed(2) : '';
      _observacoesController.text = p.observacoes;
    }
    _carregarEstoque();
  }

  Future<void> _carregarEstoque() async {
    try {
      final resultado = await FirestoreService.buscarEstoque();
      if (!mounted) return;
      setState(() {
        _estoqueLinhas = resultado;
        _carregandoEstoque = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregandoEstoque = false);
    }
  }

  double get _larguraCm => (double.tryParse(_larguraController.text) ?? 0) / _pontosPorCm;
  double get _alturaCm => (double.tryParse(_alturaController.text) ?? 0) / _pontosPorCm;
  double get _totalPontos => (double.tryParse(_larguraController.text) ?? 0) * (double.tryParse(_alturaController.text) ?? 0);
  double get _horasEstimadas => _totalPontos / _pontosPorHora;
  double get _precoSugerido => (_horasEstimadas * _valorHora) + _materialFixo;
  bool get _temCalculo => _larguraController.text.trim().isNotEmpty && _alturaController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _temaController.dispose();
    _textoController.dispose();
    _tecidoController.dispose();
    _larguraController.dispose();
    _alturaController.dispose();
    _valorController.dispose();
    _entradaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdicao = widget.pedido != null;
    final bool isArtesanato = _tipoPedidoAtivo == 'ARTESANATO';

    return Scaffold(
      backgroundColor: const Color(0xFFF9EFE1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9EFE1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3C6246)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdicao
              ? (isArtesanato ? 'Editar Pedido Artesanal' : 'Editar Pedido')
              : (isArtesanato ? 'Novo Pedido Artesanal' : 'Novo Pedido'),
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF3C6246)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isEdicao) ...[
              const SizedBox(height: 12),
              _seletorTipoPedido(),
              const SizedBox(height: 16),
            ],
            if (isEdicao) ...[
              _blocoStatus(),
              const SizedBox(height: 16),
            ],
            _blocoCliente(),
            const SizedBox(height: 16),
            isArtesanato ? _blocoDetalhesArtesanato() : _blocoDetalhesBordado(),
            const SizedBox(height: 16),
            if (!isArtesanato) ...[
              _blocoCalculadora(),
              const SizedBox(height: 16),
            ],
            _blocoFinanceiroEPagamento(isArtesanato),
            const SizedBox(height: 24),
            _botaoSalvar(),
          ],
        ),
      ),
    );
  }

  Widget _seletorTipoPedido() {
    final bool bordadoAtivo = _tipoPedidoAtivo == 'BORDADO';
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tipoPedidoAtivo = 'BORDADO'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: bordadoAtivo ? const Color(0xFF3C6246) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: bordadoAtivo ? null : Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  'Bordado',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: bordadoAtivo ? FontWeight.bold : FontWeight.w600,
                    color: bordadoAtivo ? Colors.white : const Color(0xFF1C2321),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tipoPedidoAtivo = 'ARTESANATO'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: !bordadoAtivo ? const Color(0xFF3C6246) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: !bordadoAtivo ? null : Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  'Artesanato',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: !bordadoAtivo ? FontWeight.bold : FontWeight.w600,
                    color: !bordadoAtivo ? Colors.white : const Color(0xFF1C2321),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _blocoStatus() {
    final statusOpcoes = [
      ('NA_FILA', 'Na Fila'),
      ('EM_PRODUCAO', 'Em Produção'),
      ('CONCLUIDO', 'Concluído'),
      ('ENTREGUE', 'Entregue'),
    ];
    return _blocoContainer(
      titulo: 'Status do Pedido',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: statusOpcoes.map((s) {
          final ativo = _statusProducao == s.$1;
          return GestureDetector(
            onTap: () => setState(() => _statusProducao = s.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: ativo ? const Color(0xFF3C6246) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ativo ? const Color(0xFF3C6246) : Colors.grey.shade300),
              ),
              child: Text(
                s.$2,
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: ativo ? Colors.white : const Color(0xFF1C2321)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _blocoCliente() {
    return _blocoContainer(
      titulo: 'Cliente e Entrega',
      child: Column(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF3C6246)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _modalNovoCliente,
            icon: const Icon(Icons.person_add_outlined, color: Color(0xFF3C6246), size: 18),
            label: Text(
              _clienteSelecionado == null ? 'Cadastrar Cliente' : 'Cliente: ${_clienteSelecionado!.nome}',
              style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF3C6246), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _selecionarData,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF3C6246), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _dataEntrega == null ? 'Data de Entrega' : DateFormat('dd/MM/yyyy').format(_dataEntrega!),
                    style: GoogleFonts.montserrat(fontSize: 13, color: _dataEntrega == null ? Colors.grey : const Color(0xFF1C2321)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoDetalhesBordado() {
    return _blocoContainer(
      titulo: 'Detalhes do Bordado',
      child: Column(
        children: [
          _campo(_temaController, 'Descrição', Icons.auto_stories_outlined),
          const SizedBox(height: 10),
          _campo(_textoController, 'Observação', Icons.text_fields_outlined),
        ],
      ),
    );
  }

  Widget _blocoDetalhesArtesanato() {
    return _blocoContainer(
      titulo: 'Detalhes do Produto',
      child: Column(
        children: [
          _campo(_temaController, 'Tipo do Produto', Icons.auto_stories_outlined),
          const SizedBox(height: 10),
          _campo(_textoController, 'Observação', Icons.text_fields_outlined),
        ],
      ),
    );
  }

  Widget _blocoCalculadora() {
    return _blocoContainer(
      titulo: 'Calculadora de Gráfico',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _campo(_larguraController, 'Largura (pontos)', Icons.width_normal_outlined, teclado: TextInputType.number, aoMudar: () => setState(() {})),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('✕', style: TextStyle(fontSize: 18, color: Color(0xFF3C6246))),
              ),
              Expanded(
                child: _campo(_alturaController, 'Altura (pontos)', Icons.height_outlined, teclado: TextInputType.number, aoMudar: () => setState(() {})),
              ),
            ],
          ),
          if (_temCalculo) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3C6246).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3C6246).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _linhaCalculo('Tamanho:', '${_larguraCm.toStringAsFixed(1)} cm × ${_alturaCm.toStringAsFixed(1)} cm'),
                  _linhaCalculo('Corte sugerido tecido:', '${(_larguraCm + _margemTecido).toStringAsFixed(1)} cm × ${(_alturaCm + _margemTecido).toStringAsFixed(1)} cm'),
                  _linhaCalculo('Total de pontos:', '${_totalPontos.toStringAsFixed(0)} pts'),
                  _linhaCalculo('Tempo estimado:', '${_horasEstimadas.toStringAsFixed(1)} horas'),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Preço sugerido:', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF3C6246))),
                      Text('R\$ ${_precoSugerido.toStringAsFixed(2)}', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF3C6246))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _blocoFinanceiroEPagamento(bool isArtesanato) {
    return _blocoContainer(
      titulo: 'Materiais e Pagamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isArtesanato) ...[
            GestureDetector(
              onTap: _modalAdicionarLinhas,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.colorize_outlined, color: Color(0xFF3C6246), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _carregandoEstoque
                            ? 'Carregando estoque...'
                            : _linhasSelecionadas.isEmpty
                                ? 'Adicionar Linhas do Projeto'
                                : '${_linhasSelecionadas.length} linha(s) selecionada(s)',
                        style: GoogleFonts.montserrat(fontSize: 13, color: _linhasSelecionadas.isEmpty ? Colors.grey : const Color(0xFF1C2321)),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            if (_linhasSelecionadas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _linhasSelecionadas.map((l) {
                  return Chip(
                    label: Text('${l.marca} ${l.codigo}', style: GoogleFonts.montserrat(fontSize: 11)),
                    backgroundColor: const Color(0xFFF39AA5).withOpacity(0.15),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _linhasSelecionadas.remove(l)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 10),
          ],
          _campo(_valorController, 'Valor Cobrado (R\$)', Icons.attach_money, teclado: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 10),
          _campo(_entradaController, 'Valor Recebido / Entrada (R\$)', Icons.payments_outlined, teclado: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 10),
          TextField(
            controller: _observacoesController,
            maxLines: 3,
            style: GoogleFonts.montserrat(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Observações gerais...',
              hintStyle: GoogleFonts.montserrat(fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoSalvar() {
    final bool isEdicao = widget.pedido != null;
    final bool isArtesanato = _tipoPedidoAtivo == 'ARTESANATO';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEdicao ? const Color(0xFF3C6246) : (isArtesanato ? const Color(0xFFF4C47C) : const Color(0xFFF39AA5)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _salvarPedido,
        child: Text(
          isEdicao ? 'Salvar Alterações' : 'Criar Pedido',
          style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget _blocoContainer({required String titulo, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF3C6246))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _campo(TextEditingController controller, String hint, IconData icone, {TextInputType teclado = TextInputType.text, VoidCallback? aoMudar}) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      onChanged: aoMudar != null ? (_) => aoMudar() : null,
      style: GoogleFonts.montserrat(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 13),
        prefixIcon: Icon(icone, color: const Color(0xFF3C6246), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _linhaCalculo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade700)),
          Text(valor, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1C2321))),
        ],
      ),
    );
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataEntrega ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF3C6246), onPrimary: Colors.white)),
        child: child!,
      ),
    );
    if (data != null) setState(() => _dataEntrega = data);
  }

  void _modalNovoCliente() {
    final nomeCtrl = TextEditingController(text: _clienteSelecionado?.nome);
    final whatsappCtrl = TextEditingController(text: _clienteSelecionado?.whatsapp);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF9EFE1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Dados do Cliente', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3C6246))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeCtrl, style: GoogleFonts.montserrat(fontSize: 13), decoration: InputDecoration(hintText: 'Nome completo', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 12),
            TextField(controller: whatsappCtrl, style: GoogleFonts.montserrat(fontSize: 13), decoration: InputDecoration(hintText: 'Observação', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              nomeCtrl.dispose();
              whatsappCtrl.dispose();
              Navigator.pop(context);
            },
            child: Text('Cancelar', style: GoogleFonts.montserrat(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3C6246), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              if (nomeCtrl.text.trim().isNotEmpty) {
                final clie = ClienteModel(
                  id: _clienteSelecionado?.id ?? const Uuid().v4(),
                  nome: nomeCtrl.text.trim(),
                  whatsapp: whatsappCtrl.text.trim(),
                );
                await FirestoreService.salvarCliente(clie);
                if (!mounted) return;
                setState(() => _clienteSelecionado = clie);
                nomeCtrl.dispose();
                whatsappCtrl.dispose();
                Navigator.pop(context);
              }
            },
            child: Text('Confirmar', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _modalAdicionarLinhas() {
    if (_estoqueLinhas.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFFF9EFE1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Selecionar Linhas', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3C6246))),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.4,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _estoqueLinhas.length,
              itemBuilder: (_, i) {
                final l = _estoqueLinhas[i];
                final selecionada = _linhasSelecionadas.any((s) => s.codigo == l.codigo && s.marca == l.marca);
                return CheckboxListTile(
                  value: selecionada,
                  activeColor: const Color(0xFF3C6246),
                  contentPadding: EdgeInsets.zero,
                  title: Text('${l.marca} — ${l.codigo ?? l.nomeCor}', style: GoogleFonts.montserrat(fontSize: 13)),
                  onChanged: (v) {
                    setModalState(() {
                      setState(() {
                        if (v == true) {
                          _linhasSelecionadas.add(LinhaResumida(marca: l.marca, codigo: l.codigo ?? '', nomeCor: l.nomeCor));
                        } else {
                          _linhasSelecionadas.removeWhere((s) => s.codigo == l.codigo && s.marca == l.marca);
                        }
                      });
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: GoogleFonts.montserrat(color: Colors.grey.shade700, fontWeight: FontWeight.w500))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3C6246), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(context),
              child: Text('Confirmar', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
  
Future<void> _salvarPedido() async {
    if (_clienteSelecionado == null || _dataEntrega == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha o cliente e a data de entrega!', style: GoogleFonts.montserrat()), backgroundColor: Colors.red),
      );
      return;
    }

    final isArtesanato = _tipoPedidoAtivo == 'ARTESANATO';
    final valorCobrado = double.tryParse(_valorController.text.replaceAll(',', '.')) ?? (isArtesanato ? 0.0 : _precoSugerido);
    final valorPago = double.tryParse(_entradaController.text.replaceAll(',', '.')) ?? 0.0;
    final statusPagamento = valorPago <= 0 ? 'PENDENTE' : (valorPago >= valorCobrado ? 'QUITADO' : 'PAGO_PARCIAL');

    final pedido = PedidoModel(
      id: widget.pedido?.id ?? const Uuid().v4(),
      cliente: _clienteSelecionado!,
      // CORREÇÃO CRÍTICA: Se for um pedido novo, a data de registro herda a mesma data selecionada para a entrega.
      // Se for edição, mantém a data original em que o pedido foi criado.
      dataPedido: widget.pedido?.dataPedido ?? _dataEntrega!,
      dataEntrega: _dataEntrega!,
      tema: _temaController.text.trim().isEmpty ? 'Sem tema' : _temaController.text.trim(),
      textoBordar: _textoController.text.trim(),
      tejido: isArtesanato ? '' : _tecidoController.text.trim(),
      larguraPontos: isArtesanato ? 0 : (int.tryParse(_larguraController.text) ?? 0),
      alturaPontos: isArtesanato ? 0 : (int.tryParse(_alturaController.text) ?? 0),
      linhas: isArtesanato ? [] : _linhasSelecionadas,
      valorCobrado: valorCobrado,
      valorPago: valorPago,
      statusProducao: _statusProducao,
      statusPagamento: statusPagamento,
      observacoes: _observacoesController.text.trim(),
      tipoPedido: _tipoPedidoAtivo,
    );

    await FirestoreService.salvarPedido(pedido);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.pedido != null ? '✅ Pedido atualizado!' : '🎉 Pedido criado!'),
        backgroundColor: const Color(0xFF3C6246),
      ),
    );
  }
}