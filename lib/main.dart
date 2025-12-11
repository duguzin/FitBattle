import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'cadastro_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitBattle',
      theme: ThemeData.dark(),
      home: const AuthWrapper(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/cadastro': (_) => const CadastroPage(),
      },
    );
  }
}

// Verifica se o usuário já está logado
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Usuário já logado → vai direto para Home
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }
}
