import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DesafiosPage extends StatefulWidget {
  const DesafiosPage({super.key});

  @override
  State<DesafiosPage> createState() => _DesafiosPageState();
}

class _DesafiosPageState extends State<DesafiosPage> {
  final List<DesafioSemanal> _desafiosSemanais = [
    DesafioSemanal('🏃 Caminhada Heroica', 'Caminhe por 30 minutos seguidos', 30, 50, 25, 0.3),
    DesafioSemanal('💪 Força do Guerreiro', 'Faça 50 flexões de braço', 50, 75, 40, 0.4),
    DesafioSemanal('🏋️ Treino do Campeão', 'Vá à academia 3 vezes', 3, 100, 60, 0.5),
    DesafioSemanal('🧘 Elasticidade Élfica', 'Faça 15 minutos de alongamento', 15, 30, 20, 0.2),
    DesafioSemanal('🏃‍♂️ Resistência do Anão', 'Corra 5km', 5, 80, 45, 0.35),
    DesafioSemanal('💥 Poder do Mago', 'Faça 100 abdominais', 100, 120, 70, 0.6),
  ];

  late List<DesafioSemanal> _desafiosAtuais;
  String _semanaId = '';
  bool _carregando = true;
  int _danoBonus = 0;

  @override
  void initState() {
    super.initState();
    _carregarDesafiosSemanais();
  }

  Future<void> _carregarDesafiosSemanais() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Obter a semana atual (ano + número da semana)
        final agora = DateTime.now();
        final inicioAno = DateTime(agora.year, 1, 1);
        final diasDesdeInicio = agora.difference(inicioAno).inDays;
        final numeroSemana = ((diasDesdeInicio + inicioAno.weekday + 6) / 7).floor();
        _semanaId = '${agora.year}-$numeroSemana';

        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final dadosDesafios = userDoc.data()?['desafiosSemanais'] ?? {};
        final desafiosDaSemana = dadosDesafios[_semanaId] ?? {};

        // Inicializar desafios com progresso salvo
        _desafiosAtuais = _desafiosSemanais.map((desafio) {
          final dados = desafiosDaSemana[desafio.nome] ?? {};
          return DesafioSemanal(
            desafio.nome,
            desafio.descricao,
            desafio.total,
            desafio.recompensaMoedas,
            desafio.recompensaXP,
            desafio.danoBonus,
            progresso: dados['progresso'] ?? 0,
            concluido: dados['concluido'] ?? false,
            dataConclusao: dados['dataConclusao'] != null 
                ? (dados['dataConclusao'] as Timestamp).toDate() 
                : null,
          );
        }).toList();

        // Calcular dano bônus total
        _danoBonus = _desafiosAtuais
            .where((d) => d.concluido)
            .fold(0, (total, d) => total + (d.danoBonus * 100).toInt());

        setState(() => _carregando = false);
      }
    } catch (e) {
      print('Erro ao carregar desafios: $e');
      setState(() => _carregando = false);
    }
  }

  Future<void> _concluirDesafio(DesafioSemanal desafio) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final hoje = DateTime.now();
        
        // Verificar se já concluiu hoje
        if (desafio.dataConclusao != null &&
            desafio.dataConclusao!.year == hoje.year &&
            desafio.dataConclusao!.month == hoje.month &&
            desafio.dataConclusao!.day == hoje.day) {
          _mostrarDialogoErro('Você já concluiu este desafio hoje!\nVolte amanhã para mais.');
          return;
        }

        // Atualizar progresso
        final novoProgresso = desafio.progresso + 1;
        final concluido = novoProgresso >= desafio.total;

        // Atualizar no Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'desafiosSemanais.$_semanaId.${desafio.nome}': {
            'progresso': novoProgresso,
            'concluido': concluido,
            'dataConclusao': Timestamp.now(),
          },
          if (concluido) ...{
            'moedas': FieldValue.increment(desafio.recompensaMoedas),
            'xp': FieldValue.increment(desafio.recompensaXP),
          }
        });

        // Atualizar estado local
        setState(() {
          desafio.progresso = novoProgresso;
          desafio.concluido = concluido;
          desafio.dataConclusao = hoje;
          
          if (concluido) {
            _danoBonus += (desafio.danoBonus * 100).toInt();
          }
        });

        if (concluido) {
          _mostrarDialogoRecompensa(desafio);
        } else {
          _mostrarDialogoProgresso(desafio);
        }
      }
    } catch (e) {
      print('Erro ao concluir desafio: $e');
      _mostrarDialogoErro('Erro ao concluir desafio. Tente novamente.');
    }
  }

  void _mostrarDialogoRecompensa(DesafioSemanal desafio) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1F3D0F),
                const Color(0xFF15280A),
                const Color(0xFF0F1A06),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4ADE80),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Banner superior
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4ADE80),
                        const Color(0xFF86EFAC),
                        const Color(0xFF4ADE80),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '🎉 MISSÃO CUMPRIDA! 🎉',
                      style: TextStyle(
                        color: const Color(0xFF052E16),
                        fontFamily: 'MedievalSharp',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Conteúdo
              Padding(
                padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      desafio.nome,
                      style: TextStyle(
                        color: const Color(0xFF86EFAC),
                        fontFamily: 'MedievalSharp',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Recompensas
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4ADE80)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildItemRecompensa('🪙', '${desafio.recompensaMoedas} Moedas', Colors.amber),
                              _buildItemRecompensa('⭐', '${desafio.recompensaXP} XP', Colors.blue),
                              _buildItemRecompensa('⚔️', '+${(desafio.danoBonus * 100).toInt()}% Dano', Colors.red),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    Text(
                      'Bônus de dano ativo até o final da semana!',
                      style: TextStyle(
                        color: const Color(0xFF4ADE80),
                        fontFamily: 'MedievalSharp',
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Botão
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4ADE80),
                            const Color(0xFF16A34A),
                            const Color(0xFF4ADE80),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFF052E16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'CONTINUAR AVENTURA',
                          style: TextStyle(
                            fontFamily: 'MedievalSharp',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRecompensa(String emoji, String texto, Color cor) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          texto,
          style: TextStyle(
            color: cor,
            fontFamily: 'MedievalSharp',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _mostrarDialogoProgresso(DesafioSemanal desafio) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1E3A5F),
                const Color(0xFF152A4A),
                const Color(0xFF0F1F3A),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3B82F6),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Banner superior decorativo
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6),
                        const Color(0xFF60A5FA),
                        const Color(0xFF3B82F6),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'PROGRESSO REAL',
                      style: TextStyle(
                        color: const Color(0xFF1E3A5F),
                        fontFamily: 'MedievalSharp',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Conteúdo principal
              Padding(
                padding: const EdgeInsets.only(top: 60, bottom: 20, left: 25, right: 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone e título
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        
                        const SizedBox(width: 10),
                        Text(
                          'Progresso Registrado!',
                          style: TextStyle(
                            color: const Color(0xFFE0F2FE),
                            fontFamily: 'MedievalSharp',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.8),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Mensagem principal
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF60A5FA),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            desafio.nome,
                            style: TextStyle(
                              color: const Color(0xFFE0F2FE),
                              fontFamily: 'MedievalSharp',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Progresso atual: ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'MedievalSharp',
                                    fontSize: 15,
                                  ),
                                ),
                                TextSpan(
                                  text: '${desafio.progresso}/${desafio.total}',
                                  style: TextStyle(
                                    color: const Color(0xFF60A5FA),
                                    fontFamily: 'MedievalSharp',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: '\n\nContinua tua jornada, bravo aventureiro!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'MedievalSharp',
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Barra de progresso visual
                    Container(
                      width: 200,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF60A5FA),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: desafio.progresso / desafio.total,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF3B82F6),
                                      const Color(0xFF60A5FA),
                                      const Color(0xFF3B82F6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    Text(
                      'Cada passo te aproxima da glória...',
                      style: TextStyle(
                        color: const Color(0xFF93C5FD),
                        fontFamily: 'MedievalSharp',
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Botão de confirmação
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3B82F6),
                            const Color(0xFF2563EB),
                            const Color(0xFF3B82F6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(-1, -1),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFFE0F2FE),
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            
                            const SizedBox(width: 10),
                            Text(
                              'CONTINUAR JORNADA',
                              style: TextStyle(
                                fontFamily: 'MedievalSharp',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoErro(String mensagem) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF4C1D1D),
                const Color(0xFF3A1515),
                const Color(0xFF2A0F0F),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFDC2626),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFFDC2626).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Banner superior decorativo
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFDC2626),
                        const Color(0xFFEF4444),
                        const Color(0xFFDC2626),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'ALERTA DO REINO',
                      style: TextStyle(
                        color: const Color(0xFF450A0A),
                        fontFamily: 'MedievalSharp',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Conteúdo principal
              Padding(
                padding: const EdgeInsets.only(top: 60, bottom: 20, left: 25, right: 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone e título
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        
                        const SizedBox(width: 10),
                        Text(
                          'Atenção, Guerreiro!',
                          style: TextStyle(
                            color: const Color(0xFFFECACA),
                            fontFamily: 'MedievalSharp',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.8),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Mensagem principal
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEF4444),
                          width: 1,
                        ),
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'O conselho sábio avisa:\n\n',
                              style: TextStyle(
                                color: const Color(0xFFFECACA),
                                fontFamily: 'MedievalSharp',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: mensagem,
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'MedievalSharp',
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Indicador visual
                    Container(
                      width: 200,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4C1D1D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFEF4444),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFDC2626),
                                  const Color(0xFFEF4444),
                                  const Color(0xFFDC2626),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    Text(
                      'A paciência é a armadura do sábio...',
                      style: TextStyle(
                        color: const Color(0xFFEF4444),
                        fontFamily: 'MedievalSharp',
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Botão de confirmação
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFDC2626),
                            const Color(0xFFB91C1C),
                            const Color(0xFFDC2626),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                          BoxShadow(
                            color: const Color(0xFFDC2626).withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(-1, -1),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFFFECACA),
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            
                            const SizedBox(width: 10),
                            Text(
                              'ENTENDIDO',
                              style: TextStyle(
                                fontFamily: 'MedievalSharp',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              

            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo medieval
          Positioned.fill(
            child: Image.asset(
              'assets/images/pergaminho.jpg',
              fit: BoxFit.cover,
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Cabeçalho
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        '⚔️ Desafios da Semana ⚔️',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 26,
                          color: Color(0xFFF3E5AB),
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 4,
                              color: Colors.black87,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bônus de Dano Ativo: +$_danoBonus%',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 16,
                          color: Colors.red.shade300,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reset: Domingo às 00:00',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de desafios
                Expanded(
                  child: _carregando
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _desafiosAtuais.length,
                          itemBuilder: (context, index) {
                            final desafio = _desafiosAtuais[index];
                            final podeConcluir = !desafio.concluido && 
                                (desafio.dataConclusao == null || 
                                 desafio.dataConclusao!.day != DateTime.now().day);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: desafio.concluido 
                                      ? Colors.green 
                                      : const Color(0xFFD4AF37), 
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Cabeçalho do desafio
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          desafio.nome,
                                          style: TextStyle(
                                            fontFamily: 'MedievalSharp',
                                            fontSize: 18,
                                            color: const Color(0xFFF3E5AB),
                                            decoration: desafio.concluido 
                                                ? TextDecoration.lineThrough 
                                                : TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                      if (desafio.concluido)
                                        Text(
                                          '✅ CONCLUÍDO',
                                          style: TextStyle(
                                            fontFamily: 'MedievalSharp',
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 4),
                                  
                                  Text(
                                    desafio.descricao,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontFamily: 'MedievalSharp',
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Barra de progresso
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: desafio.progresso / desafio.total,
                                      minHeight: 14,
                                      backgroundColor: Colors.brown[900],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        desafio.concluido ? Colors.green : Colors.greenAccent,
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 10),
                                  
                                  // Rodapé do desafio
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${desafio.progresso}/${desafio.total}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'MedievalSharp',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '+${(desafio.danoBonus * 100).toInt()}% Dano',
                                            style: TextStyle(
                                              color: Colors.red.shade300,
                                              fontFamily: 'MedievalSharp',
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      ElevatedButton(
                                        onPressed: podeConcluir ? () => _concluirDesafio(desafio) : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: podeConcluir 
                                              ? const Color(0xFFD4AF37) 
                                              : Colors.grey,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          desafio.concluido ? 'Concluído' : 'Concluir',
                                          style: TextStyle(fontFamily: 'MedievalSharp'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Recompensas
                                  if (desafio.concluido) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '🎉 Recompensa: 🪙 ${desafio.recompensaMoedas} | ⭐ ${desafio.recompensaXP} XP',
                                      style: TextStyle(
                                        fontFamily: 'MedievalSharp',
                                        color: Colors.amber,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DesafioSemanal {
  final String nome;
  final String descricao;
  final int total;
  final int recompensaMoedas;
  final int recompensaXP;
  final double danoBonus;
  int progresso;
  bool concluido;
  DateTime? dataConclusao;

  DesafioSemanal(
    this.nome,
    this.descricao,
    this.total,
    this.recompensaMoedas,
    this.recompensaXP,
    this.danoBonus, {
    this.progresso = 0,
    this.concluido = false,
    this.dataConclusao,
  });
}