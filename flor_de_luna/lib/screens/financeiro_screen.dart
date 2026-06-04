// screens/financeiro_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/pedido_model.dart';
import '../services/firestore_service.dart';
import 'cadastro_pedido_screen.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  String? _mesSelecionado;

  @override
  void initState() {
    super.initState();
    // Inicializa focando estritamente no mês atual (ex: "jun") de forma limpa.
    _mesSelecionado = DateFormat('MMM', 'pt_BR').format(DateTime.now()).replaceAll('.', '').trim().toLowerCase();
  }

  Future<void> _acaoMenu(String acao, PedidoModel pedido) async {
    switch (acao) {
      case 'quitar':
        _confirmarQuitacao(pedido);
        break;
      case 'parcial':
        _modalPagamentoParcial(pedido);
        break;
      case 'editar':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CadastroPedidoScreen(pedido: pedido)),
        );
        break;
    }
  }

  void _confirmarQuitacao(PedidoModel pedido) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF9EFE1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Dar Baixa no Pedido', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: const Color(0xFF1C2321))),
        content: Text(
          'Confirmar que ${pedido.cliente.nome} pagou o valor restante de R\$ ${pedido.valorRestante.toStringAsFixed(2)}?',
          style: GoogleFonts.montserrat(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.montserrat(color: const Color(0xFF3C6246))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3C6246), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final pedidoQuitado = PedidoModel(
                id: pedido.id,
                cliente: pedido.cliente,
                dataPedido: pedido.dataPedido,
                dataEntrega: pedido.dataEntrega,
                tema: pedido.tema,
                textoBordar: pedido.textoBordar,
                tejido: pedido.tejido,
                larguraPontos: pedido.larguraPontos,
                alturaPontos: pedido.alturaPontos,
                linhas: pedido.linhas,
                valorCobrado: pedido.valorCobrado,
                valorPago: pedido.valorCobrado,
                statusProducao: pedido.statusProducao,
                statusPagamento: 'QUITADO',
                observacoes: pedido.observacoes,
                tipoPedido: pedido.tipoPedido,
              );
              await FirestoreService.salvarPedido(pedidoQuitado);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pedido quitado com sucesso!'), backgroundColor: Color(0xFF3C6246)),
              );
            },
            child: Text('Confirmar', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _modalPagamentoParcial(PedidoModel pedido) {
    final valorCtrl = TextEditingController();
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
            Text(pedido.cliente.nome, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1C2321))),
            const SizedBox(height: 6),
            Text('Saldo devedor: R\$ ${pedido.valorRestante.toStringAsFixed(2)}', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
            const SizedBox(height: 16),
            TextField(
              controller: valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: GoogleFonts.montserrat(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Valor recebido (R\$)',
                prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF3C6246)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { valorCtrl.dispose(); Navigator.pop(context); },
            child: Text('Cancelar', style: GoogleFonts.montserrat(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF39AA5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final valorRecebido = double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0.0;
              final novoTotal = pedido.valorPago + valorRecebido;
              final novoStatus = novoTotal >= pedido.valorCobrado ? 'QUITADO' : 'PAGO_PARCIAL';
              final pedidoAtualizado = PedidoModel(
                id: pedido.id, cliente: pedido.cliente, dataPedido: pedido.dataPedido,
                dataEntrega: pedido.dataEntrega, tema: pedido.tema, textoBordar: pedido.textoBordar,
                tejido: pedido.tejido, larguraPontos: pedido.larguraPontos, alturaPontos: pedido.alturaPontos,
                linhas: pedido.linhas, valorCobrado: pedido.valorCobrado, valorPago: novoTotal,
                statusProducao: pedido.statusProducao, statusPagamento: novoStatus,
                observacoes: pedido.observacoes, tipoPedido: pedido.tipoPedido,
              );
              await FirestoreService.salvarPedido(pedidoAtualizado);
              valorCtrl.dispose();
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(novoStatus == 'QUITADO' ? 'Pedido quitado!' : 'Pagamento registrado!'), backgroundColor: const Color(0xFF3C6246)),
              );
            },
            child: Text('Confirmar', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PedidoModel>>(
      stream: FirestoreService.streamPedidos(),
      builder: (context, snapshot) {
        // SOLUÇÃO DO NAVEGADOR: Só mostra loading na primeira carga. Se já tem dados na memória, não pisca mais!
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9EFE1),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF3C6246))),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9EFE1),
            body: Center(child: Text('Erro ao carregar dados financeiros: ${snapshot.error}')),
          );
        }

        final pedidosReal = snapshot.data ?? [];

        // FILTRAGEM UNIFICADA POR DATA DE ENTREGA (Isola o mês sem acumular anteriores)
        final pedidosFiltrados = pedidosReal.where((p) {
          if (_mesSelecionado == null) return true;
          final mesPedido = DateFormat('MMM', 'pt_BR').format(p.dataEntrega).replaceAll('.', '').trim().toLowerCase();
          return mesPedido == _mesSelecionado;
        }).toList();

        final double faturamentoBruto = pedidosFiltrados.fold(0, (s, p) => s + p.valorCobrado);
        final double totalRecebido = pedidosFiltrados.fold(0, (s, p) => s + p.valorPago);
        final double aReceber = pedidosFiltrados.fold(0, (s, p) => s + p.valorRestante);

        final List<PedidoModel> devedores = pedidosReal
            .where((p) => p.statusPagamento != 'QUITADO')
            .toList()
          ..sort((a, b) => a.dataEntrega.compareTo(b.dataEntrega));

        return Scaffold(
          backgroundColor: const Color(0xFFF9EFE1),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cabecalho(faturamentoBruto, totalRecebido, aReceber),
                  const SizedBox(height: 20),
                  GraficoMesesDinamico(
                    pedidos: pedidosReal, // Passa a lista bruta para renderizar MAI, JUN, JUL de uma vez
                    mesSelecionadoInicial: _mesSelecionado,
                    onMesAlterado: (novoMes) {
                      setState(() {
                        _mesSelecionado = novoMes;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  _tituloSecao(_mesSelecionado == null ? 'Valores a Receber' : 'Valores a Receber de ${_mesSelecionado!.toUpperCase()}'),
                  const SizedBox(height: 12),
                  ...devedores.where((p) {
                    if (_mesSelecionado == null) return true;
                    final mesPedido = DateFormat('MMM', 'pt_BR').format(p.dataEntrega).replaceAll('.', '').trim().toLowerCase();
                    return mesPedido == _mesSelecionado;
                  }).map(_cardDevedor),
                  if (devedores.where((p) {
                    if (_mesSelecionado == null) return true;
                    final mesPedido = DateFormat('MMM', 'pt_BR').format(p.dataEntrega).replaceAll('.', '').trim().toLowerCase();
                    return mesPedido == _mesSelecionado;
                  }).isEmpty) _estadoVazio(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cabecalho(double faturamento, double totalRecebido, double pendente) {
    String sufixoVisual = _mesSelecionado != null ? ' (${_mesSelecionado!.toUpperCase()})' : ' (GERAL)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3C6246), Color(0xFF5A8A68)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Financeiro$sufixoVisual', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(_mesSelecionado == null ? 'Balanço Geral acumulado' : 'Exibindo faturamento estrito deste mês', style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: [
              _blocoValor('Faturamento Bruto', faturamento, const Color(0xFFF39AA5)),
              const SizedBox(width: 12),
              _blocoValor('Já Recebido', totalRecebido, const Color(0xFF63C1E2)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF4C47C).withOpacity(0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('A Receber', style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 13)),
                Text('R\$ ${pendente.toStringAsFixed(2)}', style: GoogleFonts.montserrat(color: const Color(0xFFF4C47C), fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoValor(String titulo, double valor, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 6),
            Text('R\$ ${valor.toStringAsFixed(2)}', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _tituloSecao(String titulo) {
    return Text(titulo, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1C2321)));
  }

  Widget _cardDevedor(PedidoModel pedido) {
    final formatData = DateFormat('dd/MMM', 'pt_BR');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👤', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(pedido.cliente.nome, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1C2321))),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF3C6246)),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'quitar', child: Text('Dar Baixa / Quitar')),
                  const PopupMenuItem(value: 'parcial', child: Text('Registrar Pagamento Parcial')),
                  const PopupMenuItem(value: 'editar', child: Text('Editar Pedido')),
                ],
                onSelected: (v) => _acaoMenu(v.toString(), pedido),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('Entrega: ${formatData.format(pedido.dataEntrega)}', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              Text('Total: R\$ ${pedido.valorCobrado.toStringAsFixed(2)}', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Já pago: R\$ ${pedido.valorPago.toStringAsFixed(2)}', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text('Falta: R\$ ${pedido.valorRestante.toStringAsFixed(2)}', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _estadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text('Nenhum valor pendente neste filtro.', style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey)),
      ),
    );
  }
}

// --- GRÁFICO ATUALIZADO POR DATA DE ENTREGA ---
class GraficoMesesDinamico extends StatefulWidget {
  final List<PedidoModel> pedidos;
  final String? mesSelecionadoInicial;
  final Function(String?) onMesAlterado;

  const GraficoMesesDinamico({
    super.key,
    required this.pedidos,
    required this.mesSelecionadoInicial,
    required this.onMesAlterado,
  });

  @override
  State<GraficoMesesDinamico> createState() => _GraficoMesesDinamicoState();
}

class _GraficoMesesDinamicoState extends State<GraficoMesesDinamico> {
  String? _mesSelecionado;

  @override
  void initState() {
    super.initState();
    _mesSelecionado = widget.mesSelecionadoInicial;
  }

  @override
  void didUpdateWidget(covariant GraficoMesesDinamico oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mesSelecionadoInicial != oldWidget.mesSelecionadoInicial) {
      setState(() {
        _mesSelecionado = widget.mesSelecionadoInicial;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mesAtualStr = DateFormat('MMM', 'pt_BR').format(DateTime.now()).replaceAll('.', '').trim().toLowerCase();
    final os12Meses = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
    
    final Map<String, double> faturamentoPorMes = {};

    // UNIFICAÇÃO DO CORPO DO GRÁFICO: Varre usando dataEntrega de forma limpa para a Web
    for (var p in widget.pedidos) {
      String stringMes = DateFormat('MMM', 'pt_BR').format(p.dataEntrega).toLowerCase();
      stringMes = stringMes.replaceAll('.', '').trim(); 
      
      if (os12Meses.contains(stringMes)) {
        faturamentoPorMes[stringMes] = (faturamentoPorMes[stringMes] ?? 0.0) + p.valorCobrado;
      }
    }

    if (!faturamentoPorMes.containsKey(mesAtualStr)) {
      faturamentoPorMes[mesAtualStr] = 0.0;
    }

    final listaMesesOrdenada = faturamentoPorMes.entries.toList()
      ..sort((a, b) => os12Meses.indexOf(a.key).compareTo(os12Meses.indexOf(b.key)));

    final double maximo = faturamentoPorMes.values.isNotEmpty
        ? faturamentoPorMes.values.reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolução Mensal',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF3C6246)),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: listaMesesOrdenada.map((entry) {
              final nomeMes = entry.key;
              final valorFaturamento = entry.value;
              final altura = maximo > 0 ? (valorFaturamento / maximo) * 120 : 0.0;
              
              final bool isMesAtual = nomeMes == mesAtualStr;
              final bool isSelecionado = _mesSelecionado == nomeMes;

              return GestureDetector(
                onTap: () {
                  final novoMes = isSelecionado ? null : nomeMes;
                  setState(() {
                    _mesSelecionado = novoMes;
                  });
                  widget.onMesAlterado(novoMes);
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 48,
                      height: altura < 6 ? 6 : altura,
                      decoration: BoxDecoration(
                        color: isSelecionado
                            ? const Color(0xFFF39AA5)
                            : isMesAtual
                                ? const Color.fromARGB(255, 248, 193, 239)
                                : const Color.fromARGB(255, 178, 249, 197).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelecionado
                            ? Border.all(color: const Color(0xFFF39AA5), width: 2)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nomeMes.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: isSelecionado || isMesAtual ? FontWeight.bold : FontWeight.normal,
                        color: isSelecionado
                            ? const Color(0xFFF39AA5)
                            : isMesAtual
                                ? const Color(0xFF3C6246)
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}