import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class MeuPerfilPage extends StatefulWidget {
  const MeuPerfilPage({super.key});

  @override
  State<MeuPerfilPage> createState() => _MeuPerfilPageState();
}

class _MeuPerfilPageState extends State<MeuPerfilPage> {
  String _nome = '';
  int _level = 1;
  int _xp = 0;
  int _moedas = 0;
  int _fase = 1;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (snapshot.exists) {
          final data = snapshot.data();
          setState(() {
            _nome = data?['nome'] ?? 'Aventureiro';
            _level = data?['level'] ?? 1;
            _xp = data?['xp'] ?? 0;
            _moedas = data?['moedas'] ?? 0;
            _fase = data?['fase'] ?? 1;
            _carregando = false;
          });
        } else {
          setState(() => _carregando = false);
          print('Documento do usuário não encontrado.');
        }
      }
    } catch (e) {
      setState(() => _carregando = false);
      print('Erro ao carregar dados do usuário: $e');
    }
  }

  int _calcularXPProximoLevel() {
    return (_level * _level * 100);
  }

  double _calcularProgressoXP() {
    final xpProximoLevel = _calcularXPProximoLevel();
    final xpLevelAtual = ((_level - 1) * (_level - 1) * 100);
    final xpNecessario = xpProximoLevel - xpLevelAtual;
    final xpConquistado = _xp - xpLevelAtual;
    
    return (xpConquistado / xpNecessario).clamp(0.0, 1.0);
  }

  String _calcularTitulo() {
    if (_level >= 20) return 'Lenda Viva 🐉';
    if (_level >= 15) return 'Mestre Guerreiro ⚔️';
    if (_level >= 10) return 'Cavaleiro Real 🏰';
    if (_level >= 5) return 'Aventureiro Experiente 🛡️';
    return 'Novato Destemido 🎯';
  }

  // ⭐⭐ ESTILO IGUAL AOS CARDS DE TAREFAS ⭐⭐
  BoxDecoration _estiloPainel() {
    return BoxDecoration(
      color: const Color(0xFF2C1F14).withOpacity(0.7),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFD4AF37), width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.amber.shade700.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(3, 3),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.6),
          blurRadius: 5,
          offset: const Offset(-2, -2),
        ),
      ],
    );
  }

  // ⭐⭐ ESTILO DOS TÍTULOS DOS CARDS ⭐⭐
  TextStyle _tituloCard() {
    return const TextStyle(
      fontFamily: 'MedievalSharp',
      fontSize: 20,
      color: Color(0xFFF3E5AB),
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: Color(0xFF6B4C2A),
          offset: Offset(2, 2),
          blurRadius: 3,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressoXP = _calcularProgressoXP();
    final xpProximoLevel = _calcularXPProximoLevel();
    final xpLevelAtual = ((_level - 1) * (_level - 1) * 100);
    final xpRestante = xpProximoLevel - _xp;

    return Scaffold(
      body: Stack(
        children: [
          // Imagem de fundo
          Positioned.fill(
            child: Image.asset(
              'assets/images/biblioteca.png',
              fit: BoxFit.cover,
            ),
          ),

          // Overlay escuro
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ⭐⭐ NAVBAR NO ESTILO MEDIEVAL ⭐⭐
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C1F14).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // BOTÃO VOLTAR COM TEXTO
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'VOLTAR',
                          style: TextStyle(
                            fontFamily: 'MedievalSharp',
                            fontSize: 16,
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text(
                        '🧙‍♂️ Meu Perfil',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 22,
                          color: Color(0xFFF3E5AB),
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                      // BOTÃO EDITAR COM TEXTO
                      TextButton(
                        onPressed: () {
                          // Lógica para editar perfil
                        },
                        child: const Text(
                          'EDITAR',
                          style: TextStyle(
                            fontFamily: 'MedievalSharp',
                            fontSize: 16,
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _carregando
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFFD4AF37),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Carregando perfil...',
                                style: TextStyle(
                                  fontFamily: 'MedievalSharp',
                                  color: Color(0xFFF3E5AB),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            children: [
                              // ⭐⭐ CARD DO PERFIL ⭐⭐
                              Container(
                                decoration: _estiloPainel(),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    // Avatar e informações básicas
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFFD4AF37),
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.amber.withOpacity(0.3),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/images/perfil.png',
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD4AF37),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Lv.$_level',
                                            style: const TextStyle(
                                              fontFamily: 'MedievalSharp',
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _nome.isNotEmpty ? _nome : 'Aventureiro',
                                      style: const TextStyle(
                                        fontFamily: 'MedievalSharp',
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _calcularTitulo(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFFD4AF37),
                                        fontFamily: 'MedievalSharp',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Fase $_fase • $_moedas Moedas',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontFamily: 'MedievalSharp',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ⭐⭐ CARD DE PROGRESSO DO HERÓI ⭐⭐
                              Container(
                                decoration: _estiloPainel(),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('✨ Progresso do Herói', style: _tituloCard()),
                                    const SizedBox(height: 20),
                                    
                                    // Barra de XP
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Experiência:',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'MedievalSharp',
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              '$_xp/$xpProximoLevel XP',
                                              style: const TextStyle(
                                                color: Color(0xFFD4AF37),
                                                fontFamily: 'MedievalSharp',
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2D1F0B),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFF8B6C1F)),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: progressoXP.clamp(0.0, 1.0),
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB)],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          xpRestante > 0 
                                              ? '$xpRestante XP para o próximo nível'
                                              : '🏆 Level máximo alcançado!',
                                          style: const TextStyle(
                                            color: Colors.amberAccent,
                                            fontSize: 12,
                                            fontFamily: 'MedievalSharp',
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    const Divider(color: Color(0xFF8B6C1F)),
                                    const SizedBox(height: 10),
                                    
                                    // Estatísticas rápidas
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildEstatistica('🏆', 'Level', _level.toString()),
                                        _buildEstatistica('⚔️', 'Fase', _fase.toString()),
                                        _buildEstatistica('🪙', 'Moedas', _moedas.toString()),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ⭐⭐ CARD DE CONQUISTAS ⭐⭐
                              Container(
                                decoration: _estiloPainel(),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('🏆 Conquistas de Level', style: _tituloCard()),
                                    const SizedBox(height: 16),
                                    _buildConquistaLevel('Level 5 - Cavaleiro Real 🏰', _level >= 5, 'Desbloqueia novas habilidades'),
                                    _buildConquistaLevel('Level 10 - Mestre Guerreiro ⚔️', _level >= 10, 'Acesso a missões épicas'),
                                    _buildConquistaLevel('Level 15 - Lenda Viva 🐉', _level >= 15, 'Título lendário desbloqueado'),
                                    _buildConquistaLevel('Level 20 - Mito Imortal 🌟', _level >= 20, 'Conquista máxima alcançada'),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ⭐⭐ CARD DE MEDALHAS ⭐⭐
                              Container(
                                decoration: _estiloPainel(),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('🎖️ Medalhas Conquistadas', style: _tituloCard()),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 145,
                                      child: PageView(
                                        controller: PageController(viewportFraction: 0.6),
                                        children: [
                                          _buildMedalCard(
                                            image: 'assets/images/medalha.png',
                                            titulo: 'Conquistador',
                                            descricao: 'Level $_level',
                                            desbloqueada: _level >= 3,
                                          ),
                                          _buildMedalCard(
                                            image: 'assets/images/medalha.png',
                                            titulo: 'Dedicado',
                                            descricao: 'Fase $_fase',
                                            desbloqueada: _fase >= 2,
                                          ),
                                          _buildMedalCard(
                                            image: 'assets/images/medalha2.png',
                                            titulo: 'Iniciante',
                                            descricao: '${_xp} XP',
                                            desbloqueada: _xp >= 100,
                                          ),
                                          _buildMedalCard(
                                            image: 'assets/images/medalha3.png',
                                            titulo: 'Mago da Rotina',
                                            descricao: '${_moedas}🪙',
                                            desbloqueada: _moedas >= 50,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ⭐⭐ CARD DE ESTATÍSTICAS DETALHADAS ⭐⭐
                              Container(
                                decoration: _estiloPainel(),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('📊 Estatísticas Detalhadas', style: _tituloCard()),
                                    const SizedBox(height: 16),
                                    _buildInfoEstatistica('XP Total Conquistado', '$_xp XP'),
                                    _buildInfoEstatistica('Próximo Level em', '$xpRestante XP'),
                                    _buildInfoEstatistica('Moedas Acumuladas', '$_moedas 🪙'),
                                    _buildInfoEstatistica('Fase Atual', '$_fase'),
                                    _buildInfoEstatistica('Título Atual', _calcularTitulo().replaceAll(RegExp(r'[^\w\s]'), '')),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                ),

                // ⭐⭐ FOOTER NO ESTILO MEDIEVAL ⭐⭐
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C1F14).withOpacity(0.8),
                    border: Border(
                      top: BorderSide(color: const Color(0xFFD4AF37), width: 2),
                    ),
                  ),
                  child: const Text(
                    '© 2025 Guilda dos Conquistadores',
                    style: TextStyle(
                      color: Color(0xFFF3E5AB),
                      fontFamily: 'MedievalSharp',
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstatistica(String emoji, String label, String valor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3E2F16).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4AF37)),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'MedievalSharp',
            fontSize: 12,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            color: Color(0xFFF3E5AB),
            fontFamily: 'MedievalSharp',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConquistaLevel(String level, bool desbloqueada, String descricao) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: desbloqueada 
            ? const Color(0xFF2A4D2A).withOpacity(0.3)
            : const Color(0xFF3E2F16).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: desbloqueada ? Colors.greenAccent : Colors.grey,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: desbloqueada ? Colors.greenAccent : Colors.grey,
            ),
            child: Center(
              child: Text(
                desbloqueada ? '✓' : '○',
                style: TextStyle(
                  color: desbloqueada ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    color: desbloqueada ? Colors.white : Colors.grey,
                    fontFamily: 'MedievalSharp',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: TextStyle(
                    color: desbloqueada ? Colors.white70 : Colors.grey,
                    fontSize: 12,
                    fontFamily: 'MedievalSharp',
                  ),
                ),
              ],
            ),
          ),
          if (desbloqueada)
            const Text(
              '🎉',
              style: TextStyle(fontSize: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoEstatistica(String label, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'MedievalSharp',
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontFamily: 'MedievalSharp',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedalCard({
    required String image,
    required String titulo,
    required String descricao,
    required bool desbloqueada,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: desbloqueada
              ? [
                  const Color(0xFF3E2F16),
                  const Color(0xFF2C1F14),
                ]
              : [
                  Colors.grey.shade800,
                  Colors.grey.shade600,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: desbloqueada ? const Color(0xFFD4AF37) : Colors.grey,
          width: 2,
        ),
        boxShadow: desbloqueada
            ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                image,
                width: 60,
                height: 60,
                color: desbloqueada ? null : Colors.grey,
              ),
              if (!desbloqueada)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'BLOQ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MedievalSharp',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: TextStyle(
              fontFamily: 'MedievalSharp',
              fontSize: 14,
              color: desbloqueada ? const Color(0xFFF3E5AB) : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            descricao,
            style: TextStyle(
              fontSize: 11,
              color: desbloqueada ? Colors.white70 : Colors.grey,
              fontFamily: 'MedievalSharp',
            ),
          ),
        ],
      ),
    );
  }

  String get _titulo => _calcularTitulo();
}