import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math'; 

class EstatisticasPage extends StatefulWidget {
  const EstatisticasPage({super.key});

  @override
  State<EstatisticasPage> createState() => _EstatisticasPageState();
}

class _EstatisticasPageState extends State<EstatisticasPage> {
  final frasesMotivacionais = [
    "⚔️ A vitória pertence aos perseverantes!",
    "🏰 Cada passo é um tijolo na construção do teu castelo.",
    "🛡️ Não é o destino, mas a jornada que forja o herói.",
  ];

  int _indiceFrase = 0;
  
  // Dados do usuário
  Map<String, dynamic> _dadosUsuario = {};
  bool _carregando = true;
  
  // Estatísticas reais do Firebase
  int _missoesConcluidas = 0;
  int _missoesPendentes = 0;
  int _missoesAtraso = 0;
  int _totalMissoes = 0;
  double _percentualConclusao = 0.0;
  int _vitorias = 0;
  int _derrotas = 0;
  int _totalBatalhas = 0;
  double _taxaVitoria = 0.0;
  int _diasConsecutivos = 0;
  int _monstrosDerrotados = 0;
  int _maiorSequenciaVitorias = 0;
  int _tempoTotalTreino = 0;

  // Novas variáveis para atividades
  int _atividadesRealizadasHoje = 0;
  int _limiteAtividadesDiarias = 5;
  double _progressoAtividades = 0.0;

  @override
  void initState() {
    super.initState();
    _indiceFrase = DateTime.now().second % frasesMotivacionais.length;
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
          final data = snapshot.data()!;
          setState(() {
            _dadosUsuario = data;
            _carregando = false;
          });

          // Calcular estatísticas baseadas nos dados reais do Firebase
          _calcularEstatisticasReais();
        }
      }
    } catch (e) {
      print('Erro ao carregar dados do usuário: $e');
      setState(() => _carregando = false);
    }
  }

  void _calcularEstatisticasReais() {
  // ⭐⭐ USA DADOS REAIS DO FIREBASE ⭐⭐
  final estatisticas = _dadosUsuario['estatisticas'] ?? {};
  
  // Dados das atividades - COM CASTING CORRETO
  final atividadesRealizadasHoje = (_dadosUsuario['atividadesRealizadasHoje'] ?? 0) as int;
  final limiteAtividadesDiarias = 5;
  
  // ⭐⭐ NOVO: Calcular missões baseadas nas atividades ⭐⭐
  final atividadesDoDia = List<Map<String, dynamic>>.from(
    _dadosUsuario['atividadesDoDia'] ?? []
  );
  final atividadesEmAndamento = Map<String, bool>.from(
    _dadosUsuario['atividadesEmAndamento'] ?? {}
  );
  
  // Calcular estatísticas em tempo real
  final totalAtividades = atividadesDoDia.length;
  final atividadesConcluidas = atividadesRealizadasHoje;
  
  // ⭐⭐ CORREÇÃO: Calcular pendentes corretamente ⭐⭐
  // Pendentes = Total - Concluídas - Em Andamento
  final emAndamentoCount = atividadesEmAndamento.values.where((estaAtiva) => estaAtiva == true).length;
  
  // Cálculo com casting para int
  final atividadesPendentes = (totalAtividades - atividadesConcluidas - emAndamentoCount) > 0 
      ? (totalAtividades - atividadesConcluidas - emAndamentoCount) 
      : 0;
  
  setState(() {
    // ⭐⭐ CASTING CORRETO PARA TODOS OS VALORES DO FIREBASE ⭐⭐
    _vitorias = (estatisticas['vitorias'] ?? 0) as int;
    _derrotas = (estatisticas['derrotas'] ?? 0) as int;
    _totalBatalhas = (estatisticas['totalBatalhas'] ?? 0) as int;
    
    // ⭐⭐ ATUALIZADO: Usar dados reais das atividades ⭐⭐
    _missoesConcluidas = atividadesConcluidas;
    _missoesPendentes = atividadesPendentes;
    _missoesAtraso = 0;
    _totalMissoes = totalAtividades;
    
    _diasConsecutivos = (estatisticas['diasConsecutivos'] ?? 0) as int;
    _monstrosDerrotados = (estatisticas['monstrosDerrotados'] ?? 0) as int;
    _maiorSequenciaVitorias = (estatisticas['maiorSequenciaVitorias'] ?? 0) as int;
    _tempoTotalTreino = (estatisticas['tempoTotalTreino'] ?? 0) as int;

    _taxaVitoria = _totalBatalhas > 0 ? _vitorias / _totalBatalhas : 0.0;
    _percentualConclusao = _totalMissoes > 0 ? _missoesConcluidas / _totalMissoes : 0.0;

    // Novas estatísticas de atividades
    _atividadesRealizadasHoje = atividadesRealizadasHoje;
    _limiteAtividadesDiarias = limiteAtividadesDiarias;
    _progressoAtividades = atividadesRealizadasHoje / limiteAtividadesDiarias;
  });
  
  print('📊 Estatísticas calculadas:');
  print('   ✅ Missões concluídas: $_missoesConcluidas');
  print('   🔄 Em andamento: $emAndamentoCount');
  print('   ⏳ Missões pendentes: $_missoesPendentes');
  print('   🏆 Vitórias: $_vitorias');
  print('   💪 Atividades hoje: $_atividadesRealizadasHoje/$_limiteAtividadesDiarias');
  print('   📋 Total de atividades: $totalAtividades');
  print('   🧮 Cálculo: $totalAtividades - $_missoesConcluidas - $emAndamentoCount = $_missoesPendentes');
}

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/biblioteca.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFD4AF37),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Carregando estatísticas...',
                    style: TextStyle(
                      fontFamily: 'MedievalSharp',
                      fontSize: 18,
                      color: Color(0xFFF3E5AB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Fundo com imagem
          Positioned.fill(
            child: Image.asset(
              'assets/images/biblioteca.png',
              fit: BoxFit.cover,
            ),
          ),

          // Sobreposição escura para legibilidade
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // Título fixo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Text(
                  'Estatísticas do Herói',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'MedievalSharp',
                    fontSize: 28,
                    color: Colors.amberAccent,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 4,
                        color: Colors.black87,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Botão de atualizar
          // Positioned(
          //   top: 70,
          //   right: 20,
          //   child: GestureDetector(
          //     onTap: () {
          //       setState(() => _carregando = true);
          //       _carregarDadosUsuario();
          //     },
          //     child: Container(
          //       padding: const EdgeInsets.all(12),
          //       decoration: BoxDecoration(
          //         color: const Color(0xFFD4AF37).withOpacity(0.8),
          //         borderRadius: BorderRadius.circular(12),
          //         border: Border.all(color: Colors.amberAccent),
          //       ),
          //       child: const Icon(Icons.refresh, color: Colors.black),
          //     ),
          //   ),
          // ),

          // Conteúdo rolável
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 110),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Frase motivacional
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _estiloPainel(),
                      child: Text(
                        frasesMotivacionais[_indiceFrase],
                        style: const TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 18,
                          color: Colors.amberAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Painel de progresso geral
                    _cardProgressoGeral(),
                    const SizedBox(height: 28),
                    
                    // ⭐⭐ NOVO: Status em tempo real ⭐⭐
                    _cardAtividadesTempoReal(),
                    const SizedBox(height: 28),
                    
                    // Atividades do dia
                    _cardAtividadesDoDia(),
                    const SizedBox(height: 28),
                    
                    // Status das tarefas
                    _cardPainelStatus(),
                    const SizedBox(height: 28),
                    
                    // Gráfico de distribuição
                    _cardGraficoPizza(),
                    const SizedBox(height: 28),
                    
                    // Estatísticas de batalha
                    _cardEstatisticasBatalha(),
                    const SizedBox(height: 28),
                    
                    // Progresso semanal
                    _cardGraficoBarras(),
                    const SizedBox(height: 28),
                    
                    // Medalhas
                    _cardMedalhas(),
                    const SizedBox(height: 28),
                    
                    // Ranking Multiplayer
                    _cardRankingMultiplayer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ⭐⭐ CARD: PROGRESSO GERAL ⭐⭐
  Widget _cardProgressoGeral() {
    final level = _dadosUsuario['level'] ?? 1;
    final xp = _dadosUsuario['xp'] ?? 0;
    final xpProximoLevel = (level * level * 100);
    final progressoLevel = xp / xpProximoLevel;

    return Container(
      decoration: _estiloPainel(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('🎯 Progresso do Herói', style: _tituloCard()),
          const SizedBox(height: 16),
          
          // Level e XP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('🏆', 'Level', level.toString()),
              _buildInfoItem('✨', 'XP', xp.toString()),
              _buildInfoItem('🪙', 'Moedas', (_dadosUsuario['moedas'] ?? 0).toString()),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Barra de progresso do level
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progresso para Level ${level + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'MedievalSharp',
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${(progressoLevel * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontFamily: 'MedievalSharp',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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
                    widthFactor: progressoLevel.clamp(0.0, 1.0),
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
              const SizedBox(height: 4),
              Text(
                '$xp / $xpProximoLevel XP',
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'MedievalSharp',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ⭐⭐ CARD: STATUS EM TEMPO REAL ⭐⭐
  Widget _cardAtividadesTempoReal() {
    final atividadesDoDia = List<Map<String, dynamic>>.from(
      _dadosUsuario['atividadesDoDia'] ?? []
    );
    final atividadesEmAndamento = Map<String, bool>.from(
      _dadosUsuario['atividadesEmAndamento'] ?? {}
    );
    final atividadesParaConfirmar = Map<String, bool>.from(
      _dadosUsuario['atividadesParaConfirmar'] ?? {}
    );

    final emAndamentoCount = atividadesEmAndamento.values.where((estaAtiva) => estaAtiva == true).length;
    final paraConfirmarCount = atividadesParaConfirmar.values.where((paraConfirmar) => paraConfirmar == true).length;

    return Container(
      decoration: _estiloPainel(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('⏰ Status em Tempo Real', style: _tituloCard()),
          const SizedBox(height: 16),
          
          // Grid de status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem('🔄', 'Em Andamento', emAndamentoCount, Colors.blue),
              _buildStatusItem('✅', 'Para Confirmar', paraConfirmarCount, Colors.orange),
              _buildStatusItem('📊', 'Concluídas Hoje', _atividadesRealizadasHoje, Colors.green),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Lista de atividades em andamento
          if (emAndamentoCount > 0) ...[
            const Text(
              'Atividades em Andamento:',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'MedievalSharp',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...atividadesDoDia.where((atividade) {
              final id = atividade['id'] ?? '';
              return atividadesEmAndamento[id] == true;
            }).map((atividade) {
              final emoji = atividade['emoji'] ?? '💪';
              final titulo = atividade['titulo'] ?? 'Atividade';
              final tempo = atividade['tempo'] ?? 300;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'MedievalSharp',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // const Icon(Icons.timer, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${(tempo / 60).ceil()}min',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontFamily: 'MedievalSharp',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          
          // Lista de atividades para confirmar
          if (paraConfirmarCount > 0) ...[
            const SizedBox(height: 12),
            const Text(
              'Aguardando Confirmação:',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'MedievalSharp',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...atividadesDoDia.where((atividade) {
              final id = atividade['id'] ?? '';
              return atividadesParaConfirmar[id] == true;
            }).map((atividade) {
              final emoji = atividade['emoji'] ?? '💪';
              final titulo = atividade['titulo'] ?? 'Atividade';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'MedievalSharp',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // const Icon(Icons.check_circle, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'Confirmar',
                      style: TextStyle(
                        color: Colors.orange,
                        fontFamily: 'MedievalSharp',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          
          if (emAndamentoCount == 0 && paraConfirmarCount == 0) ...[
            const SizedBox(height: 12),
            const Text(
              'Nenhuma atividade em andamento no momento',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'MedievalSharp',
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ⭐⭐ CARD: ATIVIDADES DO DIA ⭐⭐
  Widget _cardAtividadesDoDia() {
    final atividadesDoDia = List<Map<String, dynamic>>.from(
      _dadosUsuario['atividadesDoDia'] ?? []
    );
    final realizadas = _dadosUsuario['atividadesRealizadasHoje'] ?? 0;
    final limite = 5;

    return Container(
      decoration: _estiloPainel(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('📅 Atividades de Hoje', style: _tituloCard()),
          const SizedBox(height: 12),
          
          // Barra de progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso: $realizadas/$limite',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'MedievalSharp',
                  fontSize: 14,
                ),
              ),
              Text(
                '${(realizadas / limite * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontFamily: 'MedievalSharp',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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
                widthFactor: (realizadas / limite).clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF37D46B), Color(0xFF4CAF50)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de atividades
          Column(
            children: atividadesDoDia.map((atividade) {
              final id = atividade['id'] ?? '';
              final emoji = atividade['emoji'] ?? '💪';
              final titulo = atividade['titulo'] ?? 'Atividade';
              final realizada = realizadas > atividadesDoDia.indexOf(atividade);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: realizada 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: realizada ? Colors.green : Colors.grey,
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          color: realizada ? Colors.green : Colors.white,
                          fontFamily: 'MedievalSharp',
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Icon(
                    //   realizada ? Icons.check_circle : Icons.access_time,
                    //   color: realizada ? Colors.green : Colors.grey,
                    // ),
                  ],
                ),
              );
            }).toList(),
          ),
          
          if (realizadas >= limite) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: const Text(
                '🎉 Todas as atividades de hoje concluídas!',
                style: TextStyle(
                  color: Colors.amber,
                  fontFamily: 'MedievalSharp',
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'MedievalSharp',
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.amberAccent,
            fontFamily: 'MedievalSharp',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ⭐⭐ CARD: PAINEL DE STATUS ATUALIZADO ⭐⭐
  Widget _cardPainelStatus() {
    final atividadesEmAndamento = Map<String, bool>.from(
      _dadosUsuario['atividadesEmAndamento'] ?? {}
    );
    final emAndamentoCount = atividadesEmAndamento.values.where((estaAtiva) => estaAtiva == true).length;

    return Container(
      decoration: _estiloPainel(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚒️ Progresso das Missões', style: _tituloCard()),
          const SizedBox(height: 12),
          _LinhaStatus('✅ Concluídas', _missoesConcluidas, Colors.greenAccent),
          _LinhaStatus('🔄 Em Andamento', emAndamentoCount, Colors.blueAccent),
          _LinhaStatus('🕒 Pendentes', _missoesPendentes, Colors.amber),
          _LinhaStatus('❌ Em Atraso', _missoesAtraso, Colors.redAccent),
          const SizedBox(height: 12),
          Divider(color: Colors.amber.withOpacity(0.3)),
          const SizedBox(height: 8),
          _LinhaStatus('📊 Total de Missões', _totalMissoes, Colors.purpleAccent),
          _LinhaStatus('🎯 Taxa de Conclusão', 
            (_percentualConclusao * 100), 
            Colors.cyanAccent,
            isPercent: true
          ),
        ],
      ),
    );
  }

  // ⭐⭐ CARD: ESTATÍSTICAS DE BATALHA ⭐⭐
  Widget _cardEstatisticasBatalha() {
    return Container(
      decoration: _estiloPainel(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('⚔️ Estatísticas de Batalha', style: _tituloCard()),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBatalhaItem('🏆', 'Vitórias', _vitorias.toString(), Colors.green),
              _buildBatalhaItem('💀', 'Derrotas', _derrotas.toString(), Colors.red),
              _buildBatalhaItem('⚔️', 'Total', _totalBatalhas.toString(), Colors.blue),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF8B6C1F)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Taxa de Vitória:',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'MedievalSharp',
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${(_taxaVitoria * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _taxaVitoria > 0.7 ? Colors.green : 
                           _taxaVitoria > 0.4 ? Colors.amber : Colors.red,
                    fontFamily: 'MedievalSharp',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatalhaItem(String emoji, String label, String value, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'MedievalSharp',
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontFamily: 'MedievalSharp',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ⭐⭐ CARD: GRÁFICO DE PIZZA ATUALIZADO ⭐⭐
  Widget _cardGraficoPizza() {
    final atividadesEmAndamento = Map<String, bool>.from(
      _dadosUsuario['atividadesEmAndamento'] ?? {}
    );
    final emAndamentoCount = atividadesEmAndamento.values.where((estaAtiva) => estaAtiva == true).length;

    return Container(
      decoration: _estiloPainel(),
      padding: const EdgeInsets.all(16),
      height: 350,
      child: Column(
        children: [
          Text('📊 Distribuição das Missões', style: _tituloCard()),
          const SizedBox(height: 20),
          
          // Gráfico e legenda lado a lado
          Expanded(
            child: Row(
              children: [
                // Gráfico
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: _missoesConcluidas.toDouble(),
                          title: '${_missoesConcluidas}',
                          radius: 40,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'MedievalSharp',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.blue,
                          value: emAndamentoCount.toDouble(),
                          title: '$emAndamentoCount',
                          radius: 40,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'MedievalSharp',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.amber,
                          value: _missoesPendentes.toDouble(),
                          title: '${_missoesPendentes}',
                          radius: 40,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontFamily: 'MedievalSharp',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_missoesAtraso > 0)
                        PieChartSectionData(
                          color: Colors.redAccent,
                          value: _missoesAtraso.toDouble(),
                          title: '${_missoesAtraso}',
                          radius: 40,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'MedievalSharp',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                
                // Legenda
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildItemLegenda('🟢', 'Concluídas', _missoesConcluidas),
                      const SizedBox(height: 12),
                      _buildItemLegenda('🔵', 'Em Andamento', emAndamentoCount),
                      const SizedBox(height: 12),
                      _buildItemLegenda('🟡', 'Pendentes', _missoesPendentes),
                      if (_missoesAtraso > 0) ...[
                        const SizedBox(height: 12),
                        _buildItemLegenda('🔴', 'Atraso', _missoesAtraso),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Total: $_totalMissoes',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontFamily: 'MedievalSharp',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⭐⭐ MÉTODO PARA CADA ITEM DA LEGENDA ⭐⭐
  Widget _buildItemLegenda(String emoji, String label, int valor) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'MedievalSharp',
                  fontSize: 12,
                ),
              ),
              Text(
                '$valor',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontFamily: 'MedievalSharp',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ⭐⭐ WIDGET AUXILIAR PARA ITENS DE STATUS ⭐⭐
  Widget _buildStatusItem(String emoji, String label, int valor, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'MedievalSharp',
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          valor.toString(),
          style: TextStyle(
            color: color,
            fontFamily: 'MedievalSharp',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _cardGraficoBarras() {
  final atividadesSemana = _getAtividadesDaSemana();
  
  // DEBUG: Verificar se há dados
  final temDados = atividadesSemana.any((element) => element > 0);
  print('📈 STATUS DO GRÁFICO: $temDados - Dados: $atividadesSemana');

  return Container(
    decoration: _estiloPainel(),
    padding: const EdgeInsets.all(16),
    height: 320,
    child: Column(
      children: [
        Text('📅 Atividade Semanal', style: _tituloCard()),
        const SizedBox(height: 10),
        
        // ⭐⭐ INDICADOR VISUAL DE STATUS ⭐⭐
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: temDados ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: temDados ? Colors.green : Colors.orange,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon(
              //   temDados ? Icons.check_circle : Icons.info,
              //   color: temDados ? Colors.green : Colors.orange,
              //   size: 16,
              // ),
              const SizedBox(width: 8),
              Text(
                temDados ? 'Dados carregados' : 'Usando dados de exemplo',
                style: TextStyle(
                  color: temDados ? Colors.green : Colors.orange,
                  fontFamily: 'MedievalSharp',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 15),
        Expanded(
          child: temDados
              ? BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
                            final hoje = DateTime.now().weekday - 1;
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                dias[value.toInt()],
                                style: TextStyle(
                                  color: value.toInt() == hoje ? Colors.amber : Colors.amberAccent,
                                  fontFamily: 'MedievalSharp',
                                  fontSize: 12,
                                  fontWeight: value.toInt() == hoje ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontFamily: 'MedievalSharp',
                                fontSize: 12,
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.black.withOpacity(0.8),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final dia = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'][group.x];
                          return BarTooltipItem(
                            '$dia\n${rod.toY.toInt()} atividades',
                            const TextStyle(
                              color: Colors.white,
                              fontFamily: 'MedievalSharp',
                            ),
                          );
                        },
                      ),
                    ),
                    barGroups: List.generate(7, (index) {
                      final isHoje = index == (DateTime.now().weekday - 1);
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: atividadesSemana[index].toDouble(),
                            color: isHoje ? Colors.amber : Colors.amber.withOpacity(0.7),
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                  ),
                )
              : // Mensagem de fallback
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '📊',
                    style: TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sem dados históricos',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontFamily: 'MedievalSharp',
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Complete algumas missões para ver o gráfico!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontFamily: 'MedievalSharp',
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
        ),
      ],
    ),
  );
}
  // ⭐⭐ MÉTODO CORRIGIDO - COM FALLBACKS E DEBUG ⭐⭐
List<int> _getAtividadesDaSemana() {
  final atividadesSemana = List<int>.filled(7, 0);
  
  try {
    final estatisticas = _dadosUsuario['estatisticas'] ?? {};
    final atividadesPorDia = estatisticas['atividadesPorDia'] ?? {};
    
    print('📊 ANALISANDO DADOS DO FIREBASE:');
    print('   - Estatísticas: $estatisticas');
    print('   - AtividadesPorDia: $atividadesPorDia');
    print('   - Tipo: ${atividadesPorDia.runtimeType}');
    
    // Verificar se é um Map válido
    if (atividadesPorDia is Map && atividadesPorDia.isNotEmpty) {
      print('   ✅ Estrutura válida encontrada');
      
      // Para cada dia dos últimos 7 dias
      for (int i = 0; i < 7; i++) {
        final data = DateTime.now().subtract(Duration(days: 6 - i));
        
        // ⭐⭐ TENTAR DIFERENTES FORMATOS DE DATA ⭐⭐
        final formatosData = [
          '${data.day}_${data.month}_${data.year}',  // formato atual
          '${data.day}/${data.month}/${data.year}', // formato alternativo
          '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}', // formato ISO
          data.millisecondsSinceEpoch.toString(),   // timestamp
        ];
        
        int atividadesDoDia = 0;
        
        // Tentar cada formato
        for (final formato in formatosData) {
          final valor = atividadesPorDia[formato];
          if (valor != null) {
            print('   📅 Encontrado para $formato: $valor');
            
            // Converter para int independente do tipo
            if (valor is int) {
              atividadesDoDia = valor;
            } else if (valor is double) {
              atividadesDoDia = valor.toInt();
            } else if (valor is String) {
              atividadesDoDia = int.tryParse(valor) ?? 0;
            }
            break;
          }
        }
        
        atividadesSemana[i] = atividadesDoDia;
        
        // Debug detalhado
        print('   → Dia ${i + 1} (${_getNomeDia(data.weekday)}): $atividadesDoDia atividades');
      }
    } else {
      print('   ⚠️  Nenhum dado histórico encontrado ou estrutura inválida');
      
      // ⭐⭐ FALLBACK: Gerar dados de exemplo para teste ⭐⭐
      final random = Random();
      for (int i = 0; i < 7; i++) {
        atividadesSemana[i] = random.nextInt(4); // 0-3 atividades por dia
      }
      print('   🎲 Dados de exemplo gerados: $atividadesSemana');
    }
    
    final totalAtividades = atividadesSemana.reduce((a, b) => a + b);
    print('🎯 TOTAL de atividades na semana: $totalAtividades');
    
  } catch (e) {
    print('❌ ERRO em _getAtividadesDaSemana: $e');
    print('   StackTrace: ${e.toString()}');
    
    // Fallback em caso de erro
    final random = Random();
    for (int i = 0; i < 7; i++) {
      atividadesSemana[i] = random.nextInt(4);
    }
  }
  
  return atividadesSemana;
}

// Método auxiliar para nome dos dias
String _getNomeDia(int weekday) {
  final dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  return dias[weekday - 1];
}

  Widget _cardMedalhas() {
    // Medalhas baseadas no progresso real
    final medalhas = [
      {'nome': '1ª Missão', 'imagem': 'assets/images/medalha.png', 'conquistada': _missoesConcluidas >= 1},
      {'nome': '7 Dias Ativo', 'imagem': 'assets/images/medalha2.png', 'conquistada': _diasConsecutivos >= 7},
      {'nome': '10 Vitórias', 'imagem': 'assets/images/medalha3.png', 'conquistada': _vitorias >= 10},
      {'nome': 'Mestre Fit', 'imagem': 'assets/images/medalha.png', 'conquistada': _dadosUsuario['level'] >= 5},
    ];

    return Container(
      decoration: _estiloPainel(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('🏅 Conquistas', style: _tituloCard()),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: medalhas.map((medalha) => _medalhaItem(
              medalha['nome'] as String, 
              medalha['imagem'] as String, 
              medalha['conquistada'] as bool
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _cardRankingMultiplayer() {
    return Container(
      decoration: _estiloPainel(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('🏆 Ranking da Guilda', style: _tituloCard()),
          const SizedBox(height: 12),
          
          // Stream para buscar todos os usuários em tempo real
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('xp', descending: true)
                .limit(10) // Top 10 jogadores
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFFD4AF37)),
                    SizedBox(height: 10),
                    Text(
                      'Carregando ranking...',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontFamily: 'MedievalSharp',
                      ),
                    ),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Column(
                  children: [
                    const Text('❌', style: TextStyle(fontSize: 30)),
                    const SizedBox(height: 10),
                    Text(
                      'Erro ao carregar ranking',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontFamily: 'MedievalSharp',
                      ),
                    ),
                  ],
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Column(
                  children: [
                    const Text('👥', style: TextStyle(fontSize: 30)),
                    const SizedBox(height: 10),
                    const Text(
                      'Nenhum aventureiro encontrado',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontFamily: 'MedievalSharp',
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Seja o primeiro no ranking!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'MedievalSharp',
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }

              final users = snapshot.data!.docs;
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;

              return Column(
                children: [
                  // Cabeçalho do ranking
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD4AF37)),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '🏅',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'Aventureiro',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontFamily: 'MedievalSharp',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Level',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontFamily: 'MedievalSharp',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'XP',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontFamily: 'MedievalSharp',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Lista de usuários
                  ...users.asMap().entries.map((entry) {
                    final index = entry.key;
                    final userDoc = entry.value;
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final isCurrentUser = userDoc.id == currentUserId;
                    
                    final nome = userData['nomeExibicao'] ?? userData['nome'] ?? 'Aventureiro';
                    final level = userData['level'] ?? 1;
                    final xp = userData['xp'] ?? 0;
                    final foto = userData['fotoPerfil'] ?? 'assets/images/perfil.png';
                    
                    return _buildRankingItem(
                      posicao: index + 1,
                      nome: nome,
                      level: level,
                      xp: xp,
                      foto: foto,
                      isCurrentUser: isCurrentUser,
                    );
                  }).toList(),
                  
                  // Botão para ver ranking completo
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        _mostrarRankingCompleto();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3E2F16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'VER RANKING COMPLETO',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem({
    required int posicao,
    required String nome,
    required int level,
    required int xp,
    required String foto,
    required bool isCurrentUser,
  }) {
    // Emojis para as primeiras posições
    final String emojiPosicao = posicao == 1 ? '👑' 
                              : posicao == 2 ? '🥈' 
                              : posicao == 3 ? '🥉' 
                              : '${posicao}°';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? const Color(0xFFD4AF37).withOpacity(0.3)
            : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentUser ? const Color(0xFFD4AF37) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Posição
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              emojiPosicao,
              style: TextStyle(
                fontSize: posicao <= 3 ? 16 : 14,
                color: isCurrentUser ? Colors.amberAccent : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Foto do perfil
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCurrentUser ? Colors.amberAccent : Colors.grey,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                foto,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Nome
          Expanded(
            flex: 3,
            child: Text(
              nome.length > 12 ? '${nome.substring(0, 12)}...' : nome,
              style: TextStyle(
                fontFamily: 'MedievalSharp',
                fontSize: 14,
                color: isCurrentUser ? Colors.amberAccent : Colors.white,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          
          // Level
          Expanded(
            flex: 2,
            child: Text(
              'Lv.$level',
              style: TextStyle(
                fontFamily: 'MedievalSharp',
                fontSize: 12,
                color: isCurrentUser ? Colors.amberAccent : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // XP
          Expanded(
            flex: 2,
            child: Text(
              _formatarXP(xp),
              style: TextStyle(
                fontFamily: 'MedievalSharp',
                fontSize: 12,
                color: isCurrentUser ? Colors.amberAccent : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Método para formatar XP (1K, 1M, etc)
  String _formatarXP(int xp) {
    if (xp >= 1000000) {
      return '${(xp / 1000000).toStringAsFixed(1)}M';
    } else if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}K';
    }
    return xp.toString();
  }

  void _mostrarRankingCompleto() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2D1F0B),
                Color(0xFF1A1307),
                Color(0xFF0F0A03),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Cabeçalho
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFD4AF37),
                      Color(0xFFF3E5AB),
                      Color(0xFFD4AF37),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Center(
                  child: Text(
                    '🏆 RANKING COMPLETO 🏆',
                    style: TextStyle(
                      color: Color(0xFF3E2F16),
                      fontFamily: 'MedievalSharp',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Lista de ranking
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('xp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFFD4AF37)),
                            SizedBox(height: 10),
                            Text(
                              'Carregando heróis...',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontFamily: 'MedievalSharp',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🏰', style: TextStyle(fontSize: 40)),
                            SizedBox(height: 10),
                            Text(
                              'Nenhum herói encontrado',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontFamily: 'MedievalSharp',
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final users = snapshot.data!.docs;
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userDoc = users[index];
                        final userData = userDoc.data() as Map<String, dynamic>;
                        final isCurrentUser = userDoc.id == currentUserId;
                        
                        final nome = userData['nomeExibicao'] ?? userData['nome'] ?? 'Aventureiro';
                        final level = userData['level'] ?? 1;
                        final xp = userData['xp'] ?? 0;
                        final foto = userData['fotoPerfil'] ?? 'assets/images/perfil.png';
                        
                        return _buildRankingItem(
                          posicao: index + 1,
                          nome: nome,
                          level: level,
                          xp: xp,
                          foto: foto,
                          isCurrentUser: isCurrentUser,
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Rodapé
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final totalHerois = snapshot.data?.docs.length ?? 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total de heróis: $totalHerois',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'MedievalSharp',
                            fontSize: 12,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: const Color(0xFF3E2F16),
                          ),
                          child: const Text(
                            'FECHAR',
                            style: TextStyle(
                              fontFamily: 'MedievalSharp',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ⭐⭐ CLASSE _LinhaStatus ⭐⭐
class _LinhaStatus extends StatelessWidget {
  final String label;
  final dynamic valor;
  final Color color;
  final bool isPercent;

  const _LinhaStatus(this.label, this.valor, this.color, {
    super.key, 
    this.isPercent = false
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 17,
                color: Colors.white,
                fontFamily: 'MedievalSharp',
              )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPercent ? '${valor.toStringAsFixed(1)}%' : valor.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'MedievalSharp',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ⭐⭐ WIDGET MEDALHA ⭐⭐
Widget _medalhaItem(String nome, String caminhoImagem, bool conquistada) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Opacity(
        opacity: conquistada ? 1.0 : 0.3,
        child: Image.asset(
          caminhoImagem,
          width: 64,
          height: 64,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        nome,
        style: TextStyle(
          fontFamily: 'MedievalSharp',
          color: conquistada ? Colors.amberAccent : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      if (!conquistada)
        const Text(
          '🔒',
          style: TextStyle(fontSize: 12),
        ),
    ],
  );
}

// Estilos
BoxDecoration _estiloPainel() {
  return BoxDecoration(
    color: const Color(0xFF2C1F14).withOpacity(0.5),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFD4AF37), width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.amber.shade700.withOpacity(0.5),
        blurRadius: 10,
        offset: const Offset(3, 3),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.6),
        blurRadius: 5,
        offset: const Offset(-3, -3),
      ),
    ],
  );
}

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