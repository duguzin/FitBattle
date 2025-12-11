import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'cadastro_page.dart';
import 'esqueci_senha.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🔐 Função de login
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final senha = _passwordController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      _showErrorDialog('Preencha todos os campos.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: senha);

      User? usuario = userCredential.user;

      if (usuario != null) {
        final userDoc =
            FirebaseFirestore.instance.collection('users').doc(usuario.uid);
        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          await userDoc.set({
            'nome': usuario.email!.split('@')[0],
            'level': 1,
            'moedas': 0,
            'xp': 0,
            'fase': 1,
            'faseAtual': 1,
            'vidaMonstro': 1.0,
            'xpHoje': 0,
            'moedasHoje': 0,
            'ultimaData': Timestamp.now(),
            'desafiosSemanais': {},
          });
          print('Novo usuário criado no Firestore!');
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print("Erro no login: ${e.code}");
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'O formato do email é inválido.';
          break;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'Email ou senha incorretos.';
          break;
        case 'user-disabled':
          errorMessage = 'Esta conta foi desativada.';
          break;
        case 'network-request-failed':
          errorMessage = 'Erro de conexão. Verifique sua internet.';
          break;
        default:
          errorMessage = 'Erro desconhecido. Tente novamente.';
      }
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ⚠️ Diálogo de erro
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Poção Errada!',
          style: TextStyle(
            color: Colors.amber,
            fontFamily: 'MedievalSharp',
            fontSize: 20,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Entendido', style: TextStyle(color: Colors.amber)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // 🎨 Interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/biblioteca.png', 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.grey[900]);
              },
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🧙 Bem-vindo de volta!',
                      style: TextStyle(
                        fontFamily: 'MedievalSharp',
                        fontSize: 28,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'E-mail',
                      icon: Icons.email,
                      obscureText: false,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: 'Senha',
                      icon: Icons.lock,
                      obscureText: _obscurePassword,
                      isPassword: true,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EsqueciSenhaPage()),
                          );
                        },
                        child: const Text(
                          'Esqueceu sua senha?',
                          style: TextStyle(
                            color: Colors.amber,
                            fontFamily: 'MedievalSharp',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'MedievalSharp',
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const CadastroPage()),
                        );
                      },
                      child: const Text(
                        'Ainda não tem uma conta? Cadastre-se',
                        style: TextStyle(
                          color: Colors.amber,
                          fontFamily: 'MedievalSharp',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ⚒️ Campo de texto estilizado
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool obscureText,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: null,
        suffixIcon: isPassword
            ? TextButton(
                onPressed: () => setState(() {
                  _obscurePassword = !_obscurePassword;
                }),
                child: Text(
                  _obscurePassword ? 'VER' : 'OCULTAR',
                  style: TextStyle(
                    color: Colors.amber,
                    fontFamily: 'MedievalSharp',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.amber.withOpacity(0.7),
          fontFamily: 'MedievalSharp',
        ),
        filled: true,
        fillColor: Colors.black54,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.amber.shade400, width: 3),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}