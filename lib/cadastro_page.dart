import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'login_page.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();

  bool _isLoading = false;
  bool _obscureSenha = true;
  bool _obscureConfirmar = true;

  double _forcaSenha = 0.0;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  // 🧙‍♂️ Função principal de cadastro
  Future<void> _cadastrar() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final confirmar = _confirmarSenhaController.text.trim();

    if (nome.isEmpty || email.isEmpty || senha.isEmpty || confirmar.isEmpty) {
      _mostrarDialogo('Poção Incompleta!', 'Preencha todos os campos.');
      return;
    }

    if (!email.contains('@')) {
      _mostrarDialogo('Poção Incorreta!', 'Digite um e-mail válido.');
      return;
    }

    if (senha != confirmar) {
      _mostrarDialogo('Poções Diferentes!', 'As senhas não coincidem.');
      return;
    }

    if (!_senhaForte(senha)) {
      _mostrarDialogo(
        'Senha Fraca!',
        'A senha deve conter pelo menos 8 caracteres, uma letra maiúscula, um número e um caractere especial.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final user = cred.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'nome': nome,
          'email': email,
          'level': 1,
          'xp': 0,
          'moedas': 0,
          'criadoEm': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bem-vindo, $nome! Sua jornada começa agora 🏰'),
              backgroundColor: Colors.amber.shade700,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensagem;
      switch (e.code) {
        case 'email-already-in-use':
          mensagem = 'Este e-mail já está em uso.';
          break;
        case 'invalid-email':
          mensagem = 'Formato de e-mail inválido.';
          break;
        case 'weak-password':
          mensagem = 'A senha é muito fraca.';
          break;
        default:
          mensagem = 'Erro inesperado. Tente novamente.';
      }
      _mostrarDialogo('Poção Errada!', mensagem);
    } catch (e) {
      _mostrarDialogo('Erro!', 'Ocorreu um erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🧩 Verifica se a senha é forte
  bool _senhaForte(String senha) {
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).{8,}$');
    return regex.hasMatch(senha);
  }

  // 🧠 Avalia força da senha (0 a 1)
  double _calcularForca(String senha) {
    double forca = 0;
    if (senha.length >= 8) forca += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(senha)) forca += 0.25;
    if (RegExp(r'\d').hasMatch(senha)) forca += 0.25;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(senha)) forca += 0.25;
    return forca.clamp(0, 1);
  }

  // 🪄 Diálogo estilizado
  void _mostrarDialogo(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          titulo,
          style: const TextStyle(
            color: Colors.amber,
            fontFamily: 'MedievalSharp',
            fontSize: 22,
          ),
        ),
        content: Text(
          mensagem,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Entendido', style: TextStyle(color: Colors.amber)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  // 🖼️ Interface principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/biblioteca.png', fit: BoxFit.cover),
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
                      '🧙 Cadastre-se Agora!',
                      style: TextStyle(
                        fontFamily: 'MedievalSharp',
                        fontSize: 28,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildTextField(_nomeController, 'Nome completo', Icons.person, false),
                    const SizedBox(height: 20),
                    _buildTextField(_emailController, 'E-mail', Icons.email, false),
                    const SizedBox(height: 20),
                    _buildSenhaField(),
                    const SizedBox(height: 20),
                    _buildTextField(_confirmarSenhaController, 'Confirmar senha', Icons.lock, true, isConfirm: true),
                    const SizedBox(height: 30),
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
                        onPressed: _isLoading ? null : _cadastrar,
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
                                'Cadastrar',
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
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        'Já tem uma conta? Faça login',
                        style: TextStyle(color: Colors.amber, fontFamily: 'MedievalSharp'),
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

  // ⚒️ Campo de senha com força e lista medieval aprimorada
  Widget _buildSenhaField() {
    final senha = _senhaController.text;

    final requisitos = {
      'Mínimo de 8 caracteres': senha.length >= 8,
      'Letra maiúscula': RegExp(r'[A-Z]').hasMatch(senha),
      'Número': RegExp(r'\d').hasMatch(senha),
      'Caractere especial': RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(senha),
    };

    // Título de força
    String status;
    if (_forcaSenha < 0.25) {
      status = 'Fraca ⚙️';
    } else if (_forcaSenha < 0.5) {
      status = 'Média 🔮';
    } else if (_forcaSenha < 0.75) {
      status = 'Forte 🛡️';
    } else {
      status = 'Lendária ⚔️';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_senhaController, 'Senha', Icons.lock, true, isPassword: true),
        const SizedBox(height: 14),

        // Texto animado de força
        AnimatedOpacity(
          opacity: _senhaController.text.isEmpty ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 500),
          child: Text(
            'Força da senha: $status',
            style: TextStyle(
              color: _getBarColor(_forcaSenha),
              fontFamily: 'MedievalSharp',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 🧙‍♂️ Barra medieval estilizada
        Stack(
          children: [
            Container(
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [Colors.brown.shade900, Colors.black87],
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 18,
              width: MediaQuery.of(context).size.width * 0.85 * _forcaSenha,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    _getBarColor(_forcaSenha).withOpacity(0.9),
                    Colors.amberAccent.withOpacity(0.6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getBarColor(_forcaSenha).withOpacity(0.8),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _forcaSenha > 0.5 ? 0.8 : 0.2,
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white24,
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Lista de requisitos
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: requisitos.entries.map((e) {
            return Row(
              children: [
                // Icon(
                //   e.value ? Icons.check_circle : Icons.circle,
                //   color: e.value ? Colors.amberAccent : Colors.grey,
                //   size: 18,
                // ),
                const SizedBox(width: 6),
                Text(
                  e.key,
                  style: TextStyle(
                    color: e.value ? Colors.amberAccent : Colors.grey,
                    fontFamily: 'MedievalSharp',
                    fontSize: 14,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // 🔮 Cor da barra (tema medieval aprimorado)
  Color _getBarColor(double strength) {
    if (strength < 0.25) return const Color(0xFF6B0000); // Vermelho sangue
    if (strength < 0.5) return const Color(0xFF8B4513); // Marrom madeira
    if (strength < 0.75) return const Color(0xFFD4AF37); // Dourado nobre
    return const Color(0xFF00C853); // Verde místico
  }

  // ⚒️ Campo de texto medieval
  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    IconData icon,
    bool obscureText, {
    bool isPassword = false,
    bool isConfirm = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword
          ? _obscureSenha
          : isConfirm
              ? _obscureConfirmar
              : false,
      onChanged: isPassword
          ? (value) {
              setState(() {
                _forcaSenha = _calcularForca(value);
              });
            }
          : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: null,
        suffixIcon: isPassword
            ? TextButton(
                onPressed: () => setState(() {
                  _obscureSenha = !_obscureSenha;
                }),
                child: Text(
                  _obscureSenha ? 'VER' : 'OCULTAR',
                  style: TextStyle(
                    color: Colors.amber,
                    fontFamily: 'MedievalSharp',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : isConfirm
                ? TextButton(
                    onPressed: () => setState(() {
                      _obscureConfirmar = !_obscureConfirmar;
                    }),
                    child: Text(
                      _obscureConfirmar ? 'VER' : 'OCULTAR',
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
        hintStyle: TextStyle(color: Colors.amber.withOpacity(0.7)),
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
      ),
    );
  }
}