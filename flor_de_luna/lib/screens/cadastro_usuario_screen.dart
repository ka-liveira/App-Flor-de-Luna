// screens/cadastro_usuario_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _carregando = false;
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final confirmar = _confirmarSenhaController.text.trim();

    if (nome.isEmpty || email.isEmpty || senha.isEmpty || confirmar.isEmpty) {
      _mostrarErro('Preencha todos os campos.');
      return;
    }

    if (senha != confirmar) {
      _mostrarErro('As senhas não coincidem.');
      return;
    }

    if (senha.length < 6) {
      _mostrarErro('A senha deve ter pelo menos 6 caracteres.');
      return;
    }

    setState(() => _carregando = true);

    try {
      // Cria o usuário no Firebase Auth
      final credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      // Atualiza o nome de exibição no Auth
      await credencial.user?.updateDisplayName(nome);

      // Salva o usuário também no Firestore (tabela "usuarios")
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .set({
        'nome': nome,
        'email': email,
        'dataCadastro': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conta criada com sucesso! 🎉', style: GoogleFonts.montserrat()),
          backgroundColor: const Color(0xFF3C6246),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Volta para o login (o StreamBuilder no main.dart vai redirecionar)
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mensagem;
      switch (e.code) {
        case 'email-already-in-use':
          mensagem = 'Este e-mail já está cadastrado.';
          break;
        case 'invalid-email':
          mensagem = 'E-mail inválido.';
          break;
        case 'weak-password':
          mensagem = 'Senha muito fraca. Use pelo menos 6 caracteres.';
          break;
        default:
          mensagem = 'Erro ao cadastrar. Tente novamente.';
      }
      _mostrarErro(mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.montserrat(fontSize: 13)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Criar Conta',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF3C6246),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Ícone
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF39AA5).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF39AA5), width: 2),
                ),
                child: const Center(
                  child: Text('🪷', style: TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Bem-vinda ao Flor de Luna',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3C6246),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Preencha os dados para criar sua conta',
                style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 36),

              // Nome
              _campo(
                controller: _nomeController,
                hint: 'Nome completo',
                icone: Icons.person_outline,
              ),
              const SizedBox(height: 14),

              // E-mail
              _campo(
                controller: _emailController,
                hint: 'E-mail',
                icone: Icons.email_outlined,
                teclado: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Senha
              _campoSenha(
                controller: _senhaController,
                hint: 'Senha (mínimo 6 caracteres)',
                visivel: _senhaVisivel,
                onToggle: () => setState(() => _senhaVisivel = !_senhaVisivel),
              ),
              const SizedBox(height: 14),

              // Confirmar senha
              _campoSenha(
                controller: _confirmarSenhaController,
                hint: 'Confirmar senha',
                visivel: _confirmarSenhaVisivel,
                onToggle: () => setState(() => _confirmarSenhaVisivel = !_confirmarSenhaVisivel),
              ),
              const SizedBox(height: 32),

              // Botão cadastrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF39AA5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: _carregando ? null : _cadastrar,
                  child: _carregando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Criar Conta',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Link voltar login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Já tem uma conta? ',
                    style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Fazer login',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3C6246),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    TextInputType teclado = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      style: GoogleFonts.montserrat(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 13),
        prefixIcon: Icon(icone, color: const Color(0xFF3C6246), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _campoSenha({
    required TextEditingController controller,
    required String hint,
    required bool visivel,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visivel,
      style: GoogleFonts.montserrat(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF3C6246), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            visivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}