// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pedido_model.dart';
import '../services/firestore_service.dart';
import 'cadastro_pedido_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filtroAtivo = 'TODOS';
  String _busca = '';

  List<PedidoModel> _filtrar(List<PedidoModel> pedidos) {
    return pedidos.where((p) {
      if (p.statusProducao == 'ENTREGUE') return false;
      final buscaOk = p.cliente.nome.toLowerCase().contains(_busca.toLowerCase()) ||
          p.tema.toLowerCase().contains(_busca.toLowerCase());
      if (!buscaOk) return false;
      switch (_filtroAtivo) {
        case 'NA_FILA':
          return p.statusProducao == 'NA_FILA';
        case 'EM_PRODUCAO':
          return p.statusProducao == 'EM_PRODUCAO';
        case 'PENDENTE':
          return p.statusPagamento != 'QUITADO';
        default:
          return true;
      }
    }).toList()
      ..sort((a, b) => a.dataEntrega.compareTo(b.dataEntrega));
  }

  // ── MENU 3 PONTINHOS CENTRALIZADO ─────────────────────────────────
  void _abrirMenuPerfil() {
    showDialog(
      context: context,
      barrierDismissible: true, // Permite fechar se clicar fora do modal
      builder: (_) => const AlertDialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24), // Margem nas laterais da tela
        content: _PerfilBottomSheet(), // Mantemos o seu componente aqui dentro
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9EFE1),
      body: SafeArea(
        child: StreamBuilder<List<PedidoModel>>(
          stream: FirestoreService.streamPedidos(),
          builder: (context, snapshot) {
            final pedidos = snapshot.data ?? [];
            final filtrados = _filtrar(pedidos);

            return RefreshIndicator(
              color: const Color(0xFFF39AA5),
              onRefresh: () async => setState(() {}),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _cabecalho(pedidos)),
                  SliverToBoxAdapter(child: _barraBusca()),
                  SliverToBoxAdapter(child: _filtrosRapidos()),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: Color(0xFFF39AA5)),
                        ),
                      ),
                    )
                  else if (filtrados.isEmpty)
                    SliverToBoxAdapter(child: _estadoVazio())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _cardPedido(filtrados[index]),
                          childCount: filtrados.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF39AA5),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CadastroPedidoScreen()),
          );
          if (!mounted) return;
          setState(() {});
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _cabecalho(List<PedidoModel> pedidos) {
    final totalRecebido = pedidos.fold(0.0, (s, p) => s + p.valorPago);
    final aReceber = pedidos.fold(0.0, (s, p) => s + p.valorRestante);
    final bordandoAgora = pedidos.where((p) => p.statusProducao == 'EM_PRODUCAO').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3C6246), Color(0xFF5A8A68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🪷 Flor de Luna',
                      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat("MMMM 'de' yyyy", 'pt_BR').format(DateTime.now()),
                      style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // ── 3 PONTINHOS ──
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: _abrirMenuPerfil,
                tooltip: 'Menu',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _cardResSummary('Recebido', 'R\$ ${totalRecebido.toStringAsFixed(2)}', const Color(0xFFF39AA5)),
              const SizedBox(width: 10),
              _cardResSummary('A Receber', 'R\$ ${aReceber.toStringAsFixed(2)}', const Color(0xFFF4C47C)),
              const SizedBox(width: 10),
              _cardResSummary('Bordando', '$bordandoAgora peças', const Color(0xFF63C1E2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardResSummary(String titulo, String valor, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10)),
            const SizedBox(height: 4),
            Text(valor, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _barraBusca() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        onChanged: (v) => setState(() => _busca = v),
        style: GoogleFonts.montserrat(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar cliente ou descrição...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF3C6246)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _filtrosRapidos() {
    final filtros = [
      ('TODOS', 'Todos'),
      ('NA_FILA', 'Na Fila'),
      ('EM_PRODUCAO', 'Bordando'),
      ('PENDENTE', 'Pendentes'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: filtros.map((f) {
          final ativo = _filtroAtivo == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _filtroAtivo = f.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: ativo ? const Color(0xFF3C6246) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ativo ? const Color(0xFF3C6246) : Colors.grey.shade300),
              ),
              child: Text(
                f.$2,
                style: GoogleFonts.montserrat(
                  color: ativo ? Colors.white : const Color(0xFF1C2321),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _cardPedido(PedidoModel pedido) {
    final formatData = DateFormat('dd/MMM', 'pt_BR');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Color(0xFF1C2321)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pedido.cliente.nome,
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1C2321)),
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF3C6246)),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar Pedido')),
                  const PopupMenuItem(value: 'concluir', child: Text('Status de Produção')),
                  const PopupMenuItem(value: 'pagamento', child: Text('Registrar Pagamento')),
                  const PopupMenuItem(value: 'excluir', child: Text('Excluir Pedido')),
                ],
                onSelected: (v) => _acaoMenu(v.toString(), pedido),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pedido.tema, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                    if (pedido.textoBordar.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(pedido.textoBordar, style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 13, color: pedido.entregaProxima ? Colors.red : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Entrega: ${formatData.format(pedido.dataEntrega)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: pedido.entregaProxima ? Colors.red : Colors.grey,
                          fontWeight: pedido.entregaProxima ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pedido.statusProducao == 'ENTREGUE'
                        ? 'Concluído ✓'
                        : pedido.diasParaEntrega >= 0
                            ? 'Faltam ${pedido.diasParaEntrega} dias'
                            : 'Atrasado!',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: pedido.statusProducao == 'ENTREGUE'
                          ? const Color(0xFF3C6246)
                          : pedido.entregaProxima
                              ? Colors.red
                              : Colors.grey.shade600,
                      fontWeight: pedido.statusProducao == 'ENTREGUE' || pedido.entregaProxima ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _tagStatus(pedido.statusProducao, _corStatusProducao(pedido.statusProducao)),
              const SizedBox(width: 8),
              _tagPagamento(pedido),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pedido.isArtesanato ? const Color(0xFFF4C47C).withOpacity(0.2) : const Color(0xFF3C6246).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  pedido.isArtesanato ? 'Artesanal' : 'Bordado',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: pedido.isArtesanato ? const Color(0xFF7A5C00) : const Color(0xFF3C6246),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tagStatus(String status, Color cor) {
    final labels = {'NA_FILA': 'Na Fila', 'EM_PRODUCAO': 'Em Produção', 'CONCLUIDO': 'Concluído', 'ENTREGUE': 'Entregue'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(labels[status] ?? status, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: cor)),
    );
  }

  Widget _tagPagamento(PedidoModel pedido) {
    final cor = _corStatusPagamento(pedido.statusPagamento);
    String label;
    switch (pedido.statusPagamento) {
      case 'QUITADO': label = 'Pago'; break;
      case 'PAGO_PARCIAL':
        final pct = ((pedido.valorPago / pedido.valorCobrado) * 100).round();
        label = 'Pago $pct%';
        break;
      default: label = 'Pendente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text('R\$ ${pedido.valorCobrado.toStringAsFixed(0)} · $label', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: cor)),
    );
  }

  Widget _estadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Nenhum pedido ativo!\nClique no + para começar.', textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Color _corStatusProducao(String status) {
    switch (status) {
      case 'EM_PRODUCAO': return const Color(0xFFF4C47C);
      case 'CONCLUIDO': return const Color(0xFF3C6246);
      case 'ENTREGUE': return const Color(0xFF63C1E2);
      default: return Colors.grey;
    }
  }

  Color _corStatusPagamento(String status) {
    switch (status) {
      case 'QUITADO': return const Color(0xFF3C6246);
      case 'PAGO_PARCIAL': return const Color(0xFF63C1E2);
      default: return Colors.red;
    }
  }

  Future<void> _acaoMenu(String acao, PedidoModel pedido) async {
    switch (acao) {
      case 'concluir': _modalMudarStatus(pedido); break;
      case 'pagamento': _modalRegistrarPagamento(pedido); break;
      case 'excluir': _confirmarExclusao(pedido); break;
      case 'editar':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => CadastroPedidoScreen(pedido: pedido)));
        if (!mounted) return;
        setState(() {});
        break;
    }
  }

  void _modalMudarStatus(PedidoModel pedido) {
    final statusOpcoes = [
      ('NA_FILA', 'Na Fila'),
      ('EM_PRODUCAO', 'Em Produção'),
      ('CONCLUIDO', 'Concluído'),
      ('ENTREGUE', 'Entregue'),
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF9EFE1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Status de Produção', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF3C6246))),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: statusOpcoes.map((s) {
              final ativo = pedido.statusProducao == s.$1;
              return GestureDetector(
                onTap: () async {
                  if (s.$1 == 'ENTREGUE' && pedido.statusPagamento != 'QUITADO') {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('⚠️ Quite o pagamento antes de marcar como Entregue. Falta R\$ ${pedido.valorRestante.toStringAsFixed(2)}.', style: GoogleFonts.montserrat(fontSize: 13)),
                      backgroundColor: Colors.orange.shade700,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                    ));
                    return;
                  }
                  final updated = PedidoModel(
                    id: pedido.id, cliente: pedido.cliente, dataPedido: pedido.dataPedido,
                    dataEntrega: pedido.dataEntrega, tema: pedido.tema, textoBordar: pedido.textoBordar,
                    tejido: pedido.tejido, larguraPontos: pedido.larguraPontos, alturaPontos: pedido.alturaPontos,
                    linhas: pedido.linhas, valorCobrado: pedido.valorCobrado, valorPago: pedido.valorPago,
                    statusProducao: s.$1, statusPagamento: pedido.statusPagamento,
                    observacoes: pedido.observacoes, tipoPedido: pedido.tipoPedido,
                  );
                  await FirestoreService.salvarPedido(updated);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ativo ? const Color(0xFF3C6246).withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ativo ? const Color(0xFF3C6246) : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(s.$2, style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF1C2321)))),
                      if (ativo) const Icon(Icons.check_circle, color: Color(0xFF3C6246), size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _modalRegistrarPagamento(PedidoModel pedido) {
    final valorCtrl = TextEditingController(text: pedido.valorRestante.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF9EFE1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Registrar Pagamento', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF3C6246))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Devedor: R\$ ${pedido.valorRestante.toStringAsFixed(2)}', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
            const SizedBox(height: 16),
            TextField(
              controller: valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.montserrat(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Valor recebido (R\$)',
                prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF3C6246)),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () { valorCtrl.dispose(); Navigator.pop(context); }, child: Text('Cancelar', style: GoogleFonts.montserrat(color: Colors.grey.shade700))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF39AA5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final valorRecebido = double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0.0;
              final novoTotal = pedido.valorPago + valorRecebido;
              final novoStatus = novoTotal >= pedido.valorCobrado ? 'QUITADO' : 'PAGO_PARCIAL';
              final updated = PedidoModel(
                id: pedido.id, cliente: pedido.cliente, dataPedido: pedido.dataPedido,
                dataEntrega: pedido.dataEntrega, tema: pedido.tema, textoBordar: pedido.textoBordar,
                tejido: pedido.tejido, larguraPontos: pedido.larguraPontos, alturaPontos: pedido.alturaPontos,
                linhas: pedido.linhas, valorCobrado: pedido.valorCobrado, valorPago: novoTotal,
                statusProducao: pedido.statusProducao, statusPagamento: novoStatus,
                observacoes: pedido.observacoes, tipoPedido: pedido.tipoPedido,
              );
              await FirestoreService.salvarPedido(updated);
              valorCtrl.dispose();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: Text('Confirmar', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmarExclusao(PedidoModel pedido) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF9EFE1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Excluir Pedido', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: Text('Deseja mesmo excluir o pedido de ${pedido.cliente.nome}?', style: GoogleFonts.montserrat(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: GoogleFonts.montserrat(color: const Color(0xFF3C6246)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await FirestoreService.excluirPedido(pedido.id);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: Text('Excluir', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── BOTTOM SHEET DE PERFIL ────────────────────────────────────────
// ── BOTTOM SHEET DE PERFIL ATUALIZADO E CENTRALIZADO ────────────────────────────────────────
class _PerfilBottomSheet extends StatefulWidget {
  const _PerfilBottomSheet();

  @override
  State<_PerfilBottomSheet> createState() => _PerfilBottomSheetState();
}

class _PerfilBottomSheetState extends State<_PerfilBottomSheet> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _editando = false;
  bool _senhaVisivel = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nomeCtrl.text = user?.displayName ?? '';
    _emailCtrl.text = user?.email ?? '';
    _senhaCtrl.text = ''; // Senha começa limpa por segurança
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final novoNome = _nomeCtrl.text.trim();
    final novoEmail = _emailCtrl.text.trim();
    final novaSenha = _senhaCtrl.text.trim();

    if (novoNome.isEmpty || novoEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Nome e E-mail não podem ficar vazios.', style: GoogleFonts.montserrat()),
        backgroundColor: Colors.orange.shade700,
      ));
      return;
    }

    setState(() => _salvando = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Atualiza Nome de Exibição no Auth
      if (novoNome != user.displayName) {
        await user.updateDisplayName(novoNome);
      }

      // 2. Atualiza E-mail no Auth
      if (novoEmail != user.email) {
        await user.verifyBeforeUpdateEmail(novoEmail);
      }

      // 3. Atualiza Senha no Auth (Se digitada)
      if (novaSenha.isNotEmpty) {
        if (novaSenha.length < 6) {
          throw FirebaseAuthException(
            code: 'weak-password',
            message: 'A senha deve ter pelo menos 6 caracteres.',
          );
        }
        await user.updatePassword(novaSenha);
      }

      if (!mounted) return;
      setState(() {
        _editando = false;
        _salvando = false;
        _senhaCtrl.text = '';
      });
      
      Navigator.pop(context); // Fecha o bottom sheet para atualizar o cabeçalho da Home
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Perfil atualizado com sucesso! 🎉', style: GoogleFonts.montserrat()),
        backgroundColor: const Color(0xFF3C6246),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      String msg = 'Erro ao salvar alterações.';
      if (e.code == 'requires-recent-login') {
        msg = 'Ação sensível. Faça login novamente antes de alterar as credenciais.';
      } else if (e.code == 'weak-password') {
        msg = 'Senha muito fraca. Mínimo de 6 caracteres.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.montserrat()),
        backgroundColor: Colors.red.shade600,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
    }
  }

  Future<void> _sair() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF9EFE1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sair', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: const Color(0xFF1C2321))),
        content: Text('Deseja realmente sair do Flor de Luna?', style: GoogleFonts.montserrat(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.montserrat(color: const Color(0xFF3C6246))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C6246),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sair', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      Navigator.pop(context); // Fecha o BottomSheet
      await FirebaseAuth.instance.signOut(); // Desloga (o AuthWrapper cuida do redirecionamento)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFFF9EFE1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle visual do modal
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            // Cabeçalho do modal
            Row(
              children: [
                const Text('🪷', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text('Configurações de Perfil', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3C6246))),
              ],
            ),
            const SizedBox(height: 20),

            // Campo Nome de Usuário
            _construirCampo(
              controller: _nomeCtrl,
              label: 'Nome de Usuária',
              hint: 'Seu nome completo',
              icone: Icons.person_outline,
              enabled: _editando,
            ),
            const SizedBox(height: 14),

            // Campo E-mail
            _construirCampo(
              controller: _emailCtrl,
              label: 'E-mail cadastrado',
              hint: 'exemplo@email.com',
              icone: Icons.email_outlined,
              enabled: _editando,
              teclado: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            // Campo Senha (Com visibilidade alternável por olhinho)
            TextField(
              controller: _senhaCtrl,
              enabled: _editando,
              obscureText: !_senhaVisivel,
              style: GoogleFonts.montserrat(fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Nova Senha',
                hintText: _editando ? 'Digite para alterar (mín. 6 caract.)' : '••••••••',
                labelStyle: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF3C6246)),
                hintStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF3C6246), size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
                  onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                ),
                filled: true,
                fillColor: _editando ? Colors.white : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 28),

            // Fluxo Dinâmico de Botões de Ação
            if (!_editando) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3C6246)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => setState(() => _editando = true),
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF3C6246), size: 18),
                      label: Text('Editar', style: GoogleFonts.montserrat(color: const Color(0xFF3C6246), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _sair,
                      icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                      label: Text('Sair', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final user = FirebaseAuth.instance.currentUser;
                        setState(() {
                          _editando = false;
                          _nomeCtrl.text = user?.displayName ?? '';
                          _emailCtrl.text = user?.email ?? '';
                          _senhaCtrl.text = '';
                        });
                      },
                      icon: Icon(Icons.close, color: Colors.grey.shade600, size: 18),
                      label: Text('Descartar', style: GoogleFonts.montserrat(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3C6246),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _salvando ? null : _salvar,
                      icon: _salvando
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check, color: Colors.white, size: 18),
                      label: Text('Salvar', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirCampo({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icone,
    required bool enabled,
    TextInputType teclado = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: teclado,
      style: GoogleFonts.montserrat(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF3C6246)),
        hintStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade400),
        prefixIcon: Icon(icone, color: const Color(0xFF3C6246), size: 20),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}