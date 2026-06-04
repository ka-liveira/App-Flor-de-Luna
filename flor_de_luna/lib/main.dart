// main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/estoque_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/financeiro_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FlorDeLunaApp());
}

class FlorDeLunaApp extends StatelessWidget {
  const FlorDeLunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flor de Luna',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF39AA5),
          primary: const Color(0xFFF39AA5),
          secondary: const Color(0xFF3C6246),
          surface: const Color(0xFFF9EFE1),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9EFE1),
        textTheme: GoogleFonts.montserratTextTheme(),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Verifica se há usuário logado e redireciona para a tela correta.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Aguardando resposta do Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9EFE1),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF3C6246)),
            ),
          );
        }

        // Usuário logado → vai para o app
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigation();
        }

        // Não logado → vai para o login
        return const LoginScreen();
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _indiceAtual = 0;

  final List<Widget> _telas = const [
    HomeScreen(),
    EstoqueScreen(),
    HistoricoScreen(),
    FinanceiroScreen(),
  ];
@override
  Widget build(BuildContext context) {
    return Scaffold(
      // Trocamos o acesso direto por IndexedStack para reter o estado das telas
      body: IndexedStack(
        index: _indiceAtual,
        children: _telas,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFF39AA5).withOpacity(0.3),
        selectedIndex: _indiceAtual,
        onDestinationSelected: (indice) {
          setState(() => _indiceAtual = indice);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF3C6246)),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.texture_outlined),
            selectedIcon: Icon(Icons.texture, color: Color(0xFF3C6246)),
            label: 'Estoque',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFF3C6246)),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF3C6246)),
            label: 'Financeiro',
          ),
        ],
      ),
    );
  }
}