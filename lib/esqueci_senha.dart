import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EsqueciSenhaPage extends StatefulWidget {
  const EsqueciSenhaPage({super.key});

  @override
  State<EsqueciSenhaPage> createState() => _EsqueciSenhaPageState();
}

class _EsqueciSenhaPageState extends State<EsqueciSenhaPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _mostrarDialogo(
        titulo: 'Pergaminho Incompleto!',
        mensagem: 'Digite seu e-mail para enviarmos a mensagem mágica de recuperação.',
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _mostrarDialogo(
        titulo: '🕊️ Corvo Enviado!',
        mensagem:
            'Um corvo mágico levou o pergaminho de redefinição para $email.\nVerifique sua caixa de entrada!',
        sucesso: true,
      );
    } on FirebaseAuthException catch (e) {
      String mensagem;
      switch (e.code) {
        case 'user-not-found':
          mensagem = 'Nenhum mago foi encontrado com este e-mail.';
          break;
        case 'invalid-email':
          mensagem = 'Formato de e-mail inválido.';
          break;
        default:
          mensagem = 'Erro ao enviar a mensagem. Tente novamente.';
      }

      _mostrarDialogo(
        titulo: 'Poção Falhou!',
        mensagem: mensagem,
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _mostrarDialogo({
    required String titulo,
    required String mensagem,
    bool sucesso = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          titulo,
          style: TextStyle(
            color: sucesso ? Colors.greenAccent : Colors.amber,
            fontFamily: 'MedievalSharp',
            fontSize: 22,
          ),
        ),
        content: Text(
          mensagem,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (sucesso) Navigator.pop(context); // volta pra tela de login
            },
            child: Text(
              sucesso ? 'Voltar ao login' : 'Entendido',
              style: const TextStyle(color: Colors.amber, fontFamily: 'MedievalSharp'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo temático
          Positioned.fill(
            child: Image.asset('assets/images/biblioteca.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🔮 Esqueceu a Senha?',
                      style: TextStyle(
                        fontFamily: 'MedievalSharp',
                        fontSize: 28,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Digite seu e-mail e enviaremos um pergaminho mágico para redefinir sua senha.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontFamily: 'MedievalSharp'),
                    ),
                    const SizedBox(height: 30),

                    // Campo de e-mail
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: null,
                        hintText: 'Digite seu e-mail',
                        hintStyle: TextStyle(color: Colors.amber.withOpacity(0.7)),
                        filled: true,
                        fillColor: Colors.black54,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.amber.shade400, width: 3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Botão
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
                        onPressed: _isSending ? null : _enviarLink,
                        child: _isSending
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text(
                                'Enviar Pergaminho',
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Voltar ao Login',
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
}
