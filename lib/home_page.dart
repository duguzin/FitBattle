import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:async';
import 'desafio_page.dart';
import 'loja_page.dart';
import 'statistic_page.dart';
import 'meu_perfil.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String nome = '';
  int level = 1;
  int moedas = 0;
  int xp = 0;
  bool carregando = true;

  // Sistema de fases
  int _faseAtual = 1;
  double _vidaMonstro = 1.0;
  int _xpGanho = 0;

  // Sistema Anti-Spam
  DateTime? _ultimoExercicio;
  final Duration _cooldown = const Duration(seconds: 1);
  int _xpHoje = 0;
  int _moedasHoje = 0;
  DateTime? _ultimaData;
  final int _limiteDiarioXP = 2500;
  final int _limiteDiarioMoedas = 100;
  int _stamina = 200;
  final int _staminaMaxima = 200;
  final int _custoStaminaExercicio = 10;
  final Duration _tempoRecargaStamina = const Duration(minutes: 5);
  Timer? _timerRecargaStamina;

  // Sistema de Baú Diário
  bool _premioDiarioDisponivel = false;
  bool _carregandoBau = true;
  DateTime? _ultimoPremioDiario;
  int _premioXP = 0;
  int _premioMoedas = 0;
  Timer? _timerBau;

  // Sistema de atividades aleatórias
  List<Map<String, dynamic>> _atividadesDoDia = [];
  int _atividadesRealizadasHoje = 0;
  final int _limiteAtividadesDiarias = 5;
  Map<String, Timer> _timersAtividades = {};
  Map<String, bool> _atividadesEmAndamento = {};
  Map<String, int> _tempoRestanteAtividades = {};
  Map<String, dynamic> _dadosUsuario = {};
  // Sistema de confirmação de atividades
  Map<String, bool> _atividadesParaConfirmar = {};

  // NOVO: Sistema de reset a cada 3 horas
  /*final Duration _tempoResetAtividades = const Duration(
    minutes: 180,
  ); 
  DateTime? _ultimoResetAtividades;
  Timer? _timerResetAtividades;
  Duration _tempoRestanteReset = const Duration();*/

  bool _aguardandoReset = false;
  Duration _tempoRestanteReset = const Duration();
  Timer? _timerResetManual;

  // Lista de monstros, cenários e trilhas sonoras por fase (FitBattle)
  final List<Map<String, dynamic>> _fases = [
    {
      'fase': 1,
      'monstro': 'assets/images/monstros/troll_teste2.png',
      'cenario': 'assets/images/pantano.png',
      'nome': 'Goblin Sombrio',
      'vidaMaxima': 1.0,
      'xpRecompensa': 10,
      'moedasRecompensa': 5,
      'descricao':
          'Pequeno e astuto, o Goblin Sombrio ataca em emboscadas nas florestas. Uma boa luta para iniciantes!',
      'width': 200.0,
      'height': 280.0,
    },
    {
      'fase': 2,
      'monstro': 'assets/images/PERSONAGENS/gnomos_sombrio.png',
      'cenario': 'assets/images/CENARIOS/morada_goblins.png',
      'nome': 'Gnomo Sombrio',
      'vidaMaxima': 1.3,
      'xpRecompensa': 15,
      'moedasRecompensa': 8,
      'descricao':
          'Os Gnomos Sombrios habitam os pântanos e dominam magias antigas. Não subestime sua inteligência!',
      'height': 260.0,
    },
    {
      'fase': 3,
      'monstro': 'assets/images/PERSONAGENS/esqueleto_sombrio.png',
      'cenario': 'assets/images/CENARIOS/cripta_esqueleto.png',
      'nome': 'Esqueleto Sombrio',
      'vidaMaxima': 1.6,
      'xpRecompensa': 20,
      'moedasRecompensa': 12,
      'descricao':
          'Restos amaldiçoados de guerreiros caídos, o Esqueleto Sombrio luta sem medo da morte.',
      'height': 280.0,
    },
    {
      'fase': 4,
      'monstro': 'assets/images/PERSONAGENS/lobisomi_sombrio.png',
      'cenario': 'assets/images/CENARIOS/luacheia_lobisomi.png',
      'nome': 'Lobisomem Sombrio',
      'vidaMaxima': 2.0,
      'xpRecompensa': 30,
      'moedasRecompensa': 18,
      'descricao':
          'Sob a luz da lua, o Lobisomem Sombrio desperta sua fúria primal. Um verdadeiro teste de coragem!',
      'height': 280.0,
    },
    {
      'fase': 5,
      'monstro': 'assets/images/PERSONAGENS/alquimista_sombrio.png',
      'cenario': 'assets/images/CENARIOS/laboratorio.jpeg',
      'nome': 'Alquimista Sombrio',
      'vidaMaxima': 2.4,
      'xpRecompensa': 40,
      'moedasRecompensa': 22,
      'descricao':
          'Mestre das poções proibidas, o Alquimista Sombrio transforma venenos em armas devastadoras.',
      'height': 280.0,
    },
    {
      'fase': 6,
      'monstro': 'assets/images/PERSONAGENS/diacono_sombrio.png',
      'cenario': 'assets/images/CENARIOS/igreja_diacono.png',
      'nome': 'Diácono Sombrio',
      'vidaMaxima': 2.8,
      'xpRecompensa': 50,
      'moedasRecompensa': 25,
      'descricao':
          'Antigo sacerdote corrompido pelas trevas. Seus rituais drenam a energia vital de quem se aproxima.',
      'height': 280.0,
    },
    {
      'fase': 7,
      'monstro': 'assets/images/PERSONAGENS/principe_sombrio.png',
      'cenario': 'assets/images/CENARIOS/trono_principe.png',
      'nome': 'Príncipe Sombrio',
      'vidaMaxima': 3.2,
      'xpRecompensa': 70,
      'moedasRecompensa': 30,
      'descricao':
          'Herdeiro amaldiçoado do trono perdido. O Príncipe Sombrio comanda as trevas com poder e elegância mortal.',
      'height': 280.0,
    },
    {
      'fase': 8,
      'monstro': 'assets/images/PERSONAGENS/troll_sombrio.png',
      'cenario': 'assets/images/CENARIOS/floresta_troll.png',
      'nome': 'Troll Sombrio',
      'vidaMaxima': 3.8,
      'xpRecompensa': 90,
      'moedasRecompensa': 40,
      'descricao':
          'Imenso e brutal, o Troll Sombrio é quase invencível. Dizem que o chão treme quando ele se ergue.',
      'height': 280.0,
    },
    {
      'fase': 9,
      'monstro': 'assets/images/PERSONAGENS/dragao_sombrio.png',
      'cenario': 'assets/images/CENARIOS/vulcao_dragao.png',
      'nome': 'Dragão Sombrio',
      'vidaMaxima': 5.0,
      'xpRecompensa': 150,
      'moedasRecompensa': 75,
      'descricao':
          'O lendário Dragão Sombrio reina sobre os abismos ardentes. Sua fúria destrói tudo que ousa desafiar o seu domínio.',
      'height': 280.0,
    },
  ];

  // Lista completa de atividades
  final List<Map<String, dynamic>> _todasAtividades = [
    {
      'id': 'caminhada_10min',
      'emoji': '🚶‍♂️',
      'titulo': 'Caminhada 10min',
      'dano': 0.1,
      'energia': 10,
      'tempo': 10, // 10 minutos em segundos
      'categoria': 'cardio',
    },
    {
      'id': 'flexoes_20',
      'emoji': '💪',
      'titulo': '20 Flexões',
      'dano': 0.15,
      'energia': 15,
      'tempo': 10, // 3 minutos
      'categoria': 'forca',
    },
    {
      'id': 'agachamentos_30',
      'emoji': '🦵',
      'titulo': '30 Agachamentos',
      'dano': 0.12,
      'energia': 12,
      'tempo': 10, // 4 minutos
      'categoria': 'pernas',
    },
    {
      'id': 'abdominais_25',
      'emoji': '🔥',
      'titulo': '25 Abdominais',
      'dano': 0.13,
      'energia': 13,
      'tempo': 10, // 5 minutos
      'categoria': 'core',
    },
    {
      'id': 'corrida_5min',
      'emoji': '🏃‍♂️',
      'titulo': 'Corrida 5min',
      'dano': 0.18,
      'energia': 20,
      'tempo': 10, // 5 minutos
      'categoria': 'cardio',
    },
    {
      'id': 'prancha_1min',
      'emoji': '🛡️',
      'titulo': 'Prancha 1min',
      'dano': 1.1,
      'energia': 8,
      'tempo': 10, // 1 minuto
      'categoria': 'core',
    },
    {
      'id': 'alongamento_5min',
      'emoji': '🧘‍♂️',
      'titulo': 'Alongamento 5min',
      'dano': 0.05,
      'energia': 5,
      'tempo': 10,
      'categoria': 'flexibilidade',
    },
    {
      'id': 'polichinelos_50',
      'emoji': '🌟',
      'titulo': '50 Polichinelos',
      'dano': 0.14,
      'energia': 14,
      'tempo': 10,
      'categoria': 'cardio',
    },
    {
      'id': 'barra_fixa_5',
      'emoji': '🦍',
      'titulo': '5 Barras Fixas',
      'dano': 0.25,
      'energia': 25,
      'tempo': 10,
      'categoria': 'forca',
    },
    {
      'id': 'yoga_15min',
      'emoji': '☮️',
      'titulo': 'Yoga 15min',
      'dano': 0.1,
      'energia': 10,
      'tempo': 10,
      'categoria': 'flexibilidade',
    },
  ];

  // NOVO: Método para formatar tempo de reset
  String _formatarTempoReset(Duration duration) {
    final horas = duration.inHours.toString().padLeft(2, '0');
    final minutos = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final segundos = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$horas:$minutos:$segundos';
  }

  // Métodos do Baú Diário
  Future<void> _carregarDadosBau() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final snapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (snapshot.exists) {
          final data = snapshot.data();
          final ultimoPremio = data?['ultimoPremioDiario'] as Timestamp?;

          setState(() {
            _ultimoPremioDiario = ultimoPremio?.toDate();
            _premioDiarioDisponivel =
                !_verificarSeColetouHoje(_ultimoPremioDiario);
            _carregandoBau = false;
          });

          _gerarPremiosDiarios();

          if (!_premioDiarioDisponivel) {
            _iniciarContagemRegressivaBau();
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar dados do baú: $e');
      setState(() => _carregandoBau = false);
    }
  }

  bool _verificarSeColetouHoje(DateTime? ultimoPremio) {
    if (ultimoPremio == null) return false;

    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final ultimoPremioDia = DateTime(
      ultimoPremio.year,
      ultimoPremio.month,
      ultimoPremio.day,
    );

    return hoje.isAtSameMomentAs(ultimoPremioDia);
  }

  void _gerarPremiosDiarios() {
    final random = Random();
    setState(() {
      _premioXP = 30 + random.nextInt(40); // 30-70 XP
      _premioMoedas = 5 + random.nextInt(10); // 5-15 moedas
    });
  }

  void _iniciarContagemRegressivaBau() {
    _timerBau = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _calcularTempoRestanteBau() {
    if (_ultimoPremioDiario == null) return '';

    final agora = DateTime.now();
    final proximoReset = DateTime(
      agora.year,
      agora.month,
      agora.day + 1,
      0,
      0,
      0,
    );

    final diferenca = proximoReset.difference(agora);

    final horas = diferenca.inHours.toString().padLeft(2, '0');
    final minutos = (diferenca.inMinutes % 60).toString().padLeft(2, '0');
    final segundos = (diferenca.inSeconds % 60).toString().padLeft(2, '0');

    return '$horas:$minutos:$segundos';
  }

  Future<void> _coletarPremioDiario() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'xp': FieldValue.increment(_premioXP),
          'moedas': FieldValue.increment(_premioMoedas),
          'ultimoPremioDiario': Timestamp.now(),
        });

        setState(() {
          xp += _premioXP;
          moedas += _premioMoedas;
          _premioDiarioDisponivel = false;
          _ultimoPremioDiario = DateTime.now();
        });

        _iniciarContagemRegressivaBau();
        _mostrarDialogoPremioColetado();
      }
    } catch (e) {
      print('Erro ao coletar prêmio diário: $e');
    }
  }

  void _mostrarModalBauDiario() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2D1F0B), Color(0xFF1A1307)],
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎁 Baú do Tesouro Diário',
                  style: TextStyle(
                    fontFamily: 'MedievalSharp',
                    fontSize: 24,
                    color: Color(0xFFF3E5AB),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _premioDiarioDisponivel ? _coletarPremioDiario : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:
                          _premioDiarioDisponivel
                              ? const Color(0xFFD4AF37).withOpacity(0.9)
                              : Colors.grey.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color:
                            _premioDiarioDisponivel
                                ? const Color(0xFFD4AF37)
                                : Colors.grey,
                        width: 2,
                      ),
                      boxShadow:
                          _premioDiarioDisponivel
                              ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withOpacity(0.5),
                                  blurRadius: 15,
                                  offset: const Offset(0, 0),
                                ),
                              ]
                              : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _premioDiarioDisponivel ? '🎁' : '🔒',
                          style: const TextStyle(fontSize: 60),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _premioDiarioDisponivel
                              ? 'Toque para Coletar!'
                              : 'Já Coletado Hoje',
                          style: TextStyle(
                            fontFamily: 'MedievalSharp',
                            fontSize: 16,
                            color:
                                _premioDiarioDisponivel
                                    ? Colors.black
                                    : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF8B6C1F),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildItemPremioModal('⚡', 'XP', '$_premioXP'),
                      _buildItemPremioModal('🪙', 'Moedas', '$_premioMoedas'),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      _premioDiarioDisponivel
                          ? const Text(
                            '🎯 Colete seu prêmio diário!',
                            style: TextStyle(
                              fontFamily: 'MedievalSharp',
                              fontSize: 14,
                              color: Color(0xFFF3E5AB),
                            ),
                            textAlign: TextAlign.center,
                          )
                          : Column(
                            children: [
                              const Text(
                                '⏰ Próximo prêmio em:',
                                style: TextStyle(
                                  fontFamily: 'MedievalSharp',
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _calcularTempoRestanteBau(),
                                style: const TextStyle(
                                  fontFamily: 'MedievalSharp',
                                  fontSize: 18,
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                ),

                const SizedBox(height: 15),

                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B6C1F),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(fontFamily: 'MedievalSharp'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemPremioModal(String emoji, String tipo, String valor) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 5),
        Text(
          tipo,
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _iniciarRecargaStamina();
    _carregarDadosBau();
    // Primeiro carrega os dados do usuário, depois inicializa as atividades
    _carregarDadosUsuario().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inicializarAtividades();
      });
    });
  }

  // NOVO: Método para inicializar atividades
  Future<void> _inicializarAtividades() async {
    print('🎯 Inicializando atividades...');
    await _garantirAtividadesParaNovoUsuario();
    await _gerarAtividadesDoDia();

    // Verificar se as atividades foram carregadas
    if (_atividadesDoDia.isEmpty) {
      print('⚠️ Nenhuma atividade carregada, forçando reset...');
      await _resetarAtividadesDoDia();
    } else {
      print('✅ Atividades carregadas: ${_atividadesDoDia.length}');
    }
  }

  @override
  void dispose() {
    _timerRecargaStamina?.cancel();
    _timerBau?.cancel();
    // Cancelar todos os timers de atividades
    _timerResetManual?.cancel(); // NOVO: Cancelar timer do reset manual
    _timersAtividades.forEach((key, timer) => timer.cancel());
    super.dispose();
  }

  void _iniciarRecargaStamina() {
    _timerRecargaStamina = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          if (_stamina < _staminaMaxima) {
            _stamina += 5;
            if (_stamina > _staminaMaxima) {
              _stamina = _staminaMaxima;
            }
          }
        });
      }
    });
  }

  // Variável para controlar o efeito de dano
  bool _estaLevandoDano = false;

  // Métodos dos estados
  String _getEstadoMonstro(double porcentagemVida) {
    if (porcentagemVida <= 0) return '💀 DERROTADO';
    if (porcentagemVida <= 0.15) return '⚡ CRÍTICO';
    if (porcentagemVida <= 0.4) return '💢 FERIDO';
    if (porcentagemVida <= 0.7) return '🛡️ RESISTINDO';
    return '💪 SAUDÁVEL';
  }

  Color _getCorEstado(double porcentagemVida) {
    if (porcentagemVida <= 0) return Colors.grey;
    if (porcentagemVida <= 0.15) return Colors.red;
    if (porcentagemVida <= 0.4) return Colors.orange;
    if (porcentagemVida <= 0.7) return Colors.yellow.shade700;
    return Colors.green;
  }

  // Método para garantir campos no Firebase
  Future<void> _garantirCamposFirebase() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final snapshot = await userRef.get();

        if (snapshot.exists) {
          final data = snapshot.data()!;
          Map<String, dynamic> updateData = {};
          bool needsUpdate = false;

          if (data['estatisticas'] == null) {
            updateData['estatisticas'] = {
              'vitorias': 0,
              'derrotas': 0,
              'totalBatalhas': 0,
              'missoesConcluidas': 0,
              'missoesPendentes': 0,
              'missoesAtraso': 0,
              'totalMissoes': 0,
              'diasConsecutivos': 0,
              'dataUltimaAtividade': Timestamp.now(),
              'maiorSequenciaVitorias': 0,
              'monstrosDerrotados': 0,
              'tempoTotalTreino': 0,
              'desafiosCompletos': 0,
              'sequenciaAtualVitorias': 0,
            };
            needsUpdate = true;
          }

          if (data['historicoAtividades'] == null) {
            updateData['historicoAtividades'] = [];
            needsUpdate = true;
          }

          if (data['faseAtual'] == null) {
            updateData['faseAtual'] = data['fase'] ?? 1;
            needsUpdate = true;
          }

          if (data['vidaMonstro'] == null) {
            final faseInicial = data['faseAtual'] ?? data['fase'] ?? 1;
            final vidaMaxima =
                (_fases[faseInicial - 1]['vidaMaxima'] as num).toDouble();
            updateData['vidaMonstro'] = vidaMaxima;
            needsUpdate = true;
          }

          if (data['xpHoje'] == null) {
            updateData['xpHoje'] = 0;
            needsUpdate = true;
          }

          if (data['moedasHoje'] == null) {
            updateData['moedasHoje'] = 0;
            needsUpdate = true;
          }

          if (data['ultimaData'] == null) {
            updateData['ultimaData'] = Timestamp.now();
            needsUpdate = true;
          }

          if (data['nome'] == null) {
            updateData['nome'] = 'Aventureiro';
            needsUpdate = true;
          }

          if (data['nomeExibicao'] == null) {
            updateData['nomeExibicao'] = data['nome'] ?? 'Aventureiro';
            needsUpdate = true;
          }

          if (data['fotoPerfil'] == null) {
            updateData['fotoPerfil'] = 'assets/images/perfil.png';
            needsUpdate = true;
          }

          // Campos para atividades
          if (data['atividadesDoDia'] == null) {
            updateData['atividadesDoDia'] = [];
            needsUpdate = true;
          }

          if (data['atividadesRealizadasHoje'] == null) {
            updateData['atividadesRealizadasHoje'] = 0;
            needsUpdate = true;
          }

          if (data['ultimaDataAtividades'] == null) {
            updateData['ultimaDataAtividades'] = Timestamp.now();
            needsUpdate = true;
          }

          if (data['atividadesEmAndamento'] == null) {
            updateData['atividadesEmAndamento'] = {};
            needsUpdate = true;
          }

          if (data['tempoRestanteAtividades'] == null) {
            updateData['tempoRestanteAtividades'] = {};
            needsUpdate = true;
          }

          if (data['atividadesParaConfirmar'] == null) {
            updateData['atividadesParaConfirmar'] = {};
            needsUpdate = true;
          }

          if (data['aguardandoReset'] == null) {
            updateData['aguardandoReset'] = false;
            needsUpdate = true;
          }

          if (data['tempoRestanteReset'] == null) {
            updateData['tempoRestanteReset'] = 0;
            needsUpdate = true;
          }

          if (needsUpdate) {
            await userRef.update(updateData);
            print('🎉 TODOS OS CAMPOS FORAM CRIADOS/ATUALIZADOS NO FIREBASE!');
          }
        }
      }
    } catch (e) {
      print('❌ Erro ao verificar/criar campos: $e');
    }
  }

  // Método para atualizar estatísticas de vitória
  Future<void> _atualizarEstatisticasVitoria() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

        await _garantirCamposFirebase();

        final snapshot = await userRef.get();
        final estatisticasAtuais = snapshot.data()?['estatisticas'] ?? {};

        final sequenciaAtual =
            (estatisticasAtuais['sequenciaAtualVitorias'] ?? 0) + 1;
        final maiorSequencia =
            estatisticasAtuais['maiorSequenciaVitorias'] ?? 0;
        final novaMaiorSequencia =
            sequenciaAtual > maiorSequencia ? sequenciaAtual : maiorSequencia;

        await userRef.update({
          'estatisticas.vitorias': FieldValue.increment(1),
          'estatisticas.totalBatalhas': FieldValue.increment(1),
          'estatisticas.monstrosDerrotados': FieldValue.increment(1),
          'estatisticas.missoesConcluidas': FieldValue.increment(1),
          'estatisticas.sequenciaAtualVitorias': sequenciaAtual,
          'estatisticas.maiorSequenciaVitorias': novaMaiorSequencia,
          'estatisticas.dataUltimaAtividade': Timestamp.now(),
        });

        await _atualizarDiasConsecutivos();

        await _adicionarHistoricoAtividade(
          'vitoria',
          'Derrotou ${_fases[_faseAtual - 1]['nome']} na Fase $_faseAtual',
        );

        print('✅ Estatísticas de vitória atualizadas!');
      }
    } catch (e) {
      print('❌ Erro ao atualizar estatísticas de vitória: $e');
    }
  }

  // Método para atualizar estatísticas de exercício
  Future<void> _atualizarEstatisticasExercicio(
    String tipoExercicio,
    double dano,
  ) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _garantirCamposFirebase();

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'estatisticas.tempoTotalTreino': FieldValue.increment(10),
          'estatisticas.missoesConcluidas': FieldValue.increment(1),
          'estatisticas.dataUltimaAtividade': Timestamp.now(),
        });

        await _adicionarHistoricoAtividade(
          'exercicio',
          '$tipoExercicio - Dano: ${(dano * 100).toInt()}%',
        );

        print('✅ Estatísticas de exercício atualizadas!');
      }
    } catch (e) {
      print('❌ Erro ao atualizar estatísticas de exercício: $e');
    }
  }

  // Método para atualizar dias consecutivos
  Future<void> _atualizarDiasConsecutivos() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final snapshot = await userRef.get();

        final dataUltimaAtividade =
            snapshot.data()?['estatisticas']?['dataUltimaAtividade']?.toDate();
        final diasAtuais =
            snapshot.data()?['estatisticas']?['diasConsecutivos'] ?? 0;
        final agora = DateTime.now();

        if (dataUltimaAtividade != null) {
          final diferencaDias = agora.difference(dataUltimaAtividade).inDays;

          if (diferencaDias == 1) {
            await userRef.update({
              'estatisticas.diasConsecutivos': FieldValue.increment(1),
            });
          } else if (diferencaDias > 1) {
            await userRef.update({'estatisticas.diasConsecutivos': 1});
          }
        } else {
          await userRef.update({'estatisticas.diasConsecutivos': 1});
        }
      }
    } catch (e) {
      print('❌ Erro ao atualizar dias consecutivos: $e');
    }
  }

  // Método para adicionar histórico
  Future<void> _adicionarHistoricoAtividade(
    String tipo,
    String detalhes,
  ) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final atividade = {
          'data': Timestamp.now(),
          'tipo': tipo,
          'detalhes': detalhes,
        };

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'historicoAtividades': FieldValue.arrayUnion([atividade]),
        });

        print('📝 Histórico atualizado: $tipo - $detalhes');
      }
    } catch (e) {
      print('❌ Erro ao adicionar histórico: $e');
    }
  }

  // Método para atualizar atividades por dia
  Future<void> _atualizarAtividadesPorDia() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final hoje = DateTime.now();
        final diaKey = '${hoje.day}_${hoje.month}_${hoje.year}';

        await _garantirCamposFirebase();

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'estatisticas.atividadesPorDia.$diaKey': FieldValue.increment(1),
        });

        print('✅ Atividade registrada para o dia: $diaKey');
      }
    } catch (e) {
      print('❌ Erro ao atualizar atividades por dia: $e');
    }
  }

  // Método para carregar dados do usuário
  Future<void> _carregarDadosUsuario() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final snapshot = await userRef.get();

        if (snapshot.exists) {
          final data = snapshot.data()!;

          await _garantirCamposFirebase();

          final newSnapshot = await userRef.get();
          final newData = newSnapshot.data()!;

          final xpFirestore = newData['xp'] ?? 0;
          final levelFirestore = newData['level'] ?? 1;

          setState(() {
            _dadosUsuario = newData;
            nome = newData['nome'] ?? '';
            level = levelFirestore;
            moedas = newData['moedas'] ?? 0;
            xp = xpFirestore;
            _faseAtual = newData['faseAtual'] ?? 1;
            _vidaMonstro = (newData['vidaMonstro'] ?? 1.0).toDouble();
            _xpHoje = newData['xpHoje'] ?? 0;
            _moedasHoje = newData['moedasHoje'] ?? 0;
            _ultimaData = (newData['ultimaData'] as Timestamp?)?.toDate();
            carregando = false;
          });

          _verificarLimiteDiario();

          print('🎯 Dados carregados com SUCESSO');
          print(
            '📊 Atividades disponíveis: ${newData['atividadesDoDia'] != null ? (newData['atividadesDoDia'] as List).length : 0}',
          );
        } else {
          final initialData = {
            'nome': nome.isEmpty ? 'Aventureiro' : nome,
            'level': 1,
            'xp': 0,
            'moedas': 0,
            'fase': 1,
            'faseAtual': 1,
            'vidaMonstro': 1.0,
            'xpHoje': 0,
            'moedasHoje': 0,
            'ultimaData': Timestamp.now(),
            'desafiosSemanais': {},
            'estatisticas': {
              'vitorias': 0,
              'derrotas': 0,
              'totalBatalhas': 0,
              'missoesConcluidas': 0,
              'missoesPendentes': 0,
              'missoesAtraso': 0,
              'totalMissoes': 0,
              'diasConsecutivos': 0,
              'dataUltimaAtividade': Timestamp.now(),
              'maiorSequenciaVitorias': 0,
              'monstrosDerrotados': 0,
              'tempoTotalTreino': 0,
              'desafiosCompletos': 0,
              'sequenciaAtualVitorias': 0,
            },
            'historicoAtividades': [],
            'atividadesDoDia': [],
            'atividadesRealizadasHoje': 0,
            'ultimaDataAtividades': Timestamp.now(),
            'atividadesEmAndamento': {},
            'tempoRestanteAtividades': {},
            'atividadesParaConfirmar': {},
          };

          await userRef.set(initialData);

          setState(() {
            nome = initialData['nome'] as String;
            level = 1;
            moedas = 0;
            xp = 0;
            _faseAtual = 1;
            _vidaMonstro = 1.0;
            _xpHoje = 0;
            _moedasHoje = 0;
            _ultimaData = DateTime.now();
            carregando = false;
          });

          print('🎉 NOVO USUÁRIO CRIADO COM TODOS OS CAMPOS!');
          print('👤 Criando usuário novo - garantindo atividades...');
          await _garantirAtividadesParaNovoUsuario();
        }
      }
    } catch (e) {
      setState(() => carregando = false);
      print('❌ Erro ao carregar dados do usuário: $e');
    }
  }

  // Método para atualizar dados do usuário
  Future<void> _atualizarDadosUsuario(Map<String, dynamic> dados) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(dados);
      }
    } catch (e) {
      print('Erro ao atualizar dados do usuário: $e');
    }
  }

  // Método para salvar estado do monstro
  Future<void> _salvarEstadoMonstro() async {
    await _atualizarDadosUsuario({
      'faseAtual': _faseAtual,
      'vidaMonstro': _vidaMonstro,
    });
  }

  // Método para verificar limite diário
  Future<void> _verificarLimiteDiario() async {
    final hoje = DateTime.now();
    final hojeFormatado = DateTime(hoje.year, hoje.month, hoje.day);

    if (_ultimaData == null || _ultimaData!.isBefore(hojeFormatado)) {
      _xpHoje = 0;
      _moedasHoje = 0;
      _ultimaData = hojeFormatado;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'ultimaData': Timestamp.now(),
          'xpHoje': 0,
          'moedasHoje': 0,
        });
      }
    }
  }

  // Método para calcular level
  int _calcularLevel(int xpTotal) {
    return (sqrt(xpTotal / 100) + 1).floor();
  }

  // Método para calcular XP do próximo level
  int _calcularXPProximoLevel() {
    return (level * level * 100);
  }

  // NOVO: Método para resetar atividades a cada 3 horas
 
  Future<void> _resetarAtividadesDoDia() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Gerar 5 atividades aleatórias
        final random = Random();
        final atividadesSorteadas = <Map<String, dynamic>>[];
        final indicesSorteados = <int>{};

        while (atividadesSorteadas.length < _limiteAtividadesDiarias &&
            indicesSorteados.length < _todasAtividades.length) {
          final index = random.nextInt(_todasAtividades.length);
          if (!indicesSorteados.contains(index)) {
            indicesSorteados.add(index);
            atividadesSorteadas.add(_todasAtividades[index]);
          }
        }

        final agora = DateTime.now();

        // Salvar no Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'atividadesDoDia': atividadesSorteadas,
          'atividadesRealizadasHoje': 0,
          'ultimaDataAtividades': Timestamp.now(),
          'ultimoResetAtividades': Timestamp.now(),
          'atividadesEmAndamento': {},
          'tempoRestanteAtividades': {},
          'atividadesParaConfirmar': {},
          'aguardandoReset': false, // Reset concluído
          'tempoRestanteReset': 0,
        });

        setState(() {
          _atividadesDoDia = atividadesSorteadas;
          _atividadesRealizadasHoje = 0;
          _atividadesEmAndamento = {};
          _tempoRestanteAtividades = {};
          _atividadesParaConfirmar = {};
          _aguardandoReset = false;
          _tempoRestanteReset = const Duration();
        });

        // Cancelar timer de reset
        _timerResetManual?.cancel();

        print(
          '🔄 Novas atividades disponíveis! ${_atividadesDoDia.length} missões',
        );
      }
    } catch (e) {
      print('❌ Erro ao resetar atividades: $e');
    }
  }

  // Método para gerar atividades do dia
  Future<void> _gerarAtividadesDoDia() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final snapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = snapshot.data() ?? {};

        final agora = DateTime.now();
        final ultimoReset = data['ultimoResetAtividades'] as Timestamp?;

        // VERIFICAÇÃO 1: É um novo usuário ou não tem atividades?
        final ehNovoUsuario =
            ultimoReset == null || data['atividadesDoDia'] == null;

        // VERIFICAÇÃO 2: Se está aguardando reset, verificar se já passou o tempo
        final aguardandoReset = data['aguardandoReset'] ?? false;
        final tempoRestanteReset =
            data['tempoRestanteReset'] != null
                ? Duration(seconds: data['tempoRestanteReset'] as int)
                : const Duration();

        if (ehNovoUsuario) {
          print('🔄 Novo usuário - criando atividades iniciais');
          await _resetarAtividadesDoDia();
        } else if (aguardandoReset && tempoRestanteReset.inSeconds <= 0) {
          print('🔄 Tempo de reset esgotado - criando novas atividades');
          await _resetarAtividadesDoDia();
        } else {
          // CARREGAR ATIVIDADES EXISTENTES
          final atividadesSalvas = List<Map<String, dynamic>>.from(
            data['atividadesDoDia'] ?? [],
          );
          final realizadas = data['atividadesRealizadasHoje'] ?? 0;
          final emAndamento = Map<String, bool>.from(
            data['atividadesEmAndamento'] ?? {},
          );
          final tempoRestante = Map<String, int>.from(
            data['tempoRestanteAtividades'] ?? {},
          );

          // Carregar atividades para confirmar
          final paraConfirmar = data['atividadesParaConfirmar'];
          Map<String, bool> atividadesParaConfirmar = {};

          if (paraConfirmar != null && paraConfirmar is Map) {
            atividadesParaConfirmar = Map<String, bool>.from(
              paraConfirmar.map(
                (key, value) =>
                    MapEntry(key.toString(), value is bool ? value : false),
              ),
            );
          }

          setState(() {
            _atividadesDoDia = atividadesSalvas;
            _atividadesRealizadasHoje = realizadas;
            _atividadesEmAndamento = emAndamento;
            _tempoRestanteAtividades = tempoRestante;
            _atividadesParaConfirmar = atividadesParaConfirmar;
            _aguardandoReset = aguardandoReset;
            _tempoRestanteReset = tempoRestanteReset;
          });

          // Se está aguardando reset, iniciar contagem
          if (_aguardandoReset && _tempoRestanteReset.inSeconds > 0) {
            _iniciarResetManual();
          }

          _reiniciarTimersEmAndamento();

          print('✅ Atividades carregadas: ${_atividadesDoDia.length}');
          print('🔄 Aguardando reset: $_aguardandoReset');
          if (_aguardandoReset) {
            print(
              '⏰ Tempo restante: ${_formatarTempoReset(_tempoRestanteReset)}',
            );
          }
        }
      }
    } catch (e) {
      print('❌ Erro ao gerar atividades do dia: $e');
      // Em caso de erro, criar atividades padrão
      await _resetarAtividadesDoDia();
    }
  }

  // NOVO: Método para garantir que sempre haja atividades
  Future<void> _garantirAtividadesParaNovoUsuario() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final snapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = snapshot.data() ?? {};

        // Verificações mais abrangentes para novo usuário
        final atividadesExistem =
            data['atividadesDoDia'] != null &&
            (data['atividadesDoDia'] as List).isNotEmpty;

        final ultimoResetExiste = data['ultimoResetAtividades'] != null;

        if (!atividadesExistem || !ultimoResetExiste) {
          print('🎯 Criando atividades para novo usuário...');
          print('   - Atividades existem: $atividadesExistem');
          print('   - Último reset existe: $ultimoResetExiste');

          // Forçar criação de atividades
          await _resetarAtividadesDoDia();
        } else {
          print('✅ Usuário já tem atividades configuradas');
        }
      }
    } catch (e) {
      print('❌ Erro ao garantir atividades: $e');
      // Em caso de erro, forçar criação de atividades
      await _resetarAtividadesDoDia();
    }
  }

  // Método para reiniciar timers em andamento
  void _reiniciarTimersEmAndamento() {
    print('🔄 Reiniciando timers em andamento...');

    // Reiniciar timers para atividades em andamento
    _atividadesEmAndamento.forEach((idAtividade, emAndamento) {
      if (emAndamento && _tempoRestanteAtividades.containsKey(idAtividade)) {
        final tempoRestante = _tempoRestanteAtividades[idAtividade]!;
        if (tempoRestante > 0) {
          print(
            '⏰ Reiniciando timer para $idAtividade: $tempoRestante segundos',
          );
          _iniciarTimerAtividade(idAtividade, tempoRestante);
        }
      }
    });

    // Carrega atividades para confirmar - COM VERIFICAÇÃO MAIS ROBUSTA
    try {
      if (_dadosUsuario.containsKey('atividadesParaConfirmar')) {
        final atividadesParaConfirmar =
            _dadosUsuario['atividadesParaConfirmar'];
        Map<String, bool> confirmacoes = {};

        if (atividadesParaConfirmar != null && atividadesParaConfirmar is Map) {
          atividadesParaConfirmar.forEach((key, value) {
            if (key is String && value is bool) {
              confirmacoes[key] = value;
            } else if (key != null) {
              // Converte para string e bool se necessário
              confirmacoes[key.toString()] = value == true;
            }
          });

          setState(() {
            _atividadesParaConfirmar = confirmacoes;
          });
          print(
            '✅ Atividades para confirmar carregadas: ${_atividadesParaConfirmar.length}',
          );
        } else {
          setState(() {
            _atividadesParaConfirmar = {};
          });
          print('ℹ️ Nenhuma atividade para confirmar encontrada (campo vazio)');
        }
      } else {
        setState(() {
          _atividadesParaConfirmar = {};
        });
        print('ℹ️ Campo atividadesParaConfirmar não existe no Firestore');
      }
    } catch (e) {
      print('❌ Erro ao carregar atividades para confirmar: $e');
      setState(() {
        _atividadesParaConfirmar = {};
      });
    }
  }

  // Método para realizar exercício (ATUALIZADO)
  Future<void> realizarExercicio(String idAtividade) async {
    // NOVO: Verificar se existe alguma atividade em andamento
    final existeAtividadeEmAndamento = _atividadesEmAndamento.values.any(
      (estaEmAndamento) => estaEmAndamento == true,
    );

    if (existeAtividadeEmAndamento) {
      _mostrarDialogoAtividadeBloqueada(
        'Você já tem uma atividade em andamento!\n\nComplete ou cancele a atividade atual antes de iniciar outra.',
      );
      return;
    }

    // NOVO: Verificar se a atividade já foi realizada hoje
    final jaRealizada =
        _atividadesRealizadasHoje > 0 &&
        _atividadesDoDia.indexWhere((a) => a['id'] == idAtividade) <
            _atividadesRealizadasHoje;

    if (jaRealizada) {
      _mostrarDialogoAtividadeBloqueada(
        'Esta atividade já foi realizada hoje!\n\nVolte amanhã para novas atividades.',
      );
      return;
    }

    final atividade = _atividadesDoDia.firstWhere(
      (a) => a['id'] == idAtividade,
      orElse: () => <String, dynamic>{},
    );

    if (atividade.isEmpty) return;

    final dano = atividade['dano'] ?? 0.1;
    final energia = atividade['energia'] ?? 10;
    final tempo = atividade['tempo'] ?? 300;
    final titulo = atividade['titulo'] ?? 'Atividade';

    final agora = DateTime.now();

    // Verificar se já foi realizada hoje
    if (_atividadesRealizadasHoje >= _limiteAtividadesDiarias) {
      _mostrarDialogoLimiteAtividades();
      return;
    }

    // Verificar se já está em andamento
    if (_atividadesEmAndamento[idAtividade] == true) {
      _mostrarDialogoAtividadeEmAndamento();
      return;
    }

    // Verificar stamina
    final energiaInt = energia is int ? energia : (energia as num).toInt();
    if (_stamina < energiaInt) {
      _mostrarSemStaminaDialog();
      return;
    }

    // Verificar limite diário de XP
    await _verificarLimiteDiario();
    if (_xpHoje >= _limiteDiarioXP) {
      _mostrarLimiteDiarioDialog();
      return;
    }

    // Iniciar atividade
    setState(() {
      _atividadesEmAndamento[idAtividade] = true;
      _tempoRestanteAtividades[idAtividade] = tempo;
      _stamina -= energiaInt;
    });

    // Salvar estado no Firestore
    await _salvarEstadoAtividades();

    // Iniciar timer
    _iniciarTimerAtividade(idAtividade, tempo);

    // Mostrar diálogo de confirmação
    _mostrarDialogoAtividadeIniciada(titulo, tempo);
  }

  // Método para iniciar timer de atividade
  void _iniciarTimerAtividade(String idAtividade, int tempoTotal) {
    // Cancelar timer existente
    _timersAtividades[idAtividade]?.cancel();

    final timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        final tempoRestante = _tempoRestanteAtividades[idAtividade] ?? 0;
        if (tempoRestante > 0) {
          _tempoRestanteAtividades[idAtividade] = tempoRestante - 1;
        } else {
          // Tempo esgotado - atividade falhou
          timer.cancel();
          _atividadesEmAndamento[idAtividade] = false;
          _atividadesParaConfirmar.remove(
            idAtividade,
          ); // Remove se estava aguardando confirmação
          _finalizarAtividade(idAtividade, false);
        }
      });

      // Atualizar a cada 10 segundos no Firestore
      if ((_tempoRestanteAtividades[idAtividade] ?? 0) % 10 == 0) {
        await _salvarEstadoAtividades();
      }
    });

    _timersAtividades[idAtividade] = timer;
  }

  // NOVO: Diálogo informando que o reset foi iniciado

  // NOVO: Método para iniciar reset manual quando todas as tarefas são concluídas
  void _iniciarResetManual() {
    setState(() {
      _aguardandoReset = true;
      _tempoRestanteReset = const Duration(seconds: 10); // 3 horas de espera
    });

    // Cancelar timer anterior se existir
    _timerResetManual?.cancel();

    _timerResetManual = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_tempoRestanteReset.inSeconds > 0) {
          _tempoRestanteReset =
              _tempoRestanteReset - const Duration(seconds: 1);
        } else {
          // Tempo esgotado - resetar atividades
          timer.cancel();
          _resetarAtividadesDoDia();
        }
      });
    });

    print('🔄 Reset manual iniciado! Aguardando 3 horas para novas atividades');
    _mostrarDialogoResetIniciado();
  }

  // Método para finalizar atividade
  Future<void> _finalizarAtividade(String idAtividade, bool sucesso) async {
    final atividade = _atividadesDoDia.firstWhere(
      (a) => a['id'] == idAtividade,
      orElse: () => {},
    );

    if (atividade.isEmpty) return;

    // Cancelar timer
    _timersAtividades[idAtividade]?.cancel();
    _timersAtividades.remove(idAtividade);

    if (sucesso) {
      final dano = atividade['dano'] ?? 0.1;
      final titulo = atividade['titulo'] ?? 'Atividade';

      // Aplicar dano ao monstro
      final fase = _fases[_faseAtual - 1];
      final double vidaMaxima = (fase['vidaMaxima'] as num).toDouble();
      final double danoReal = vidaMaxima * dano;

      setState(() {
        _vidaMonstro -= danoReal;
        _atividadesRealizadasHoje += 1;
        _xpGanho += (danoReal * 100).toInt();
      });

      // Atualizar estatísticas
      await _atualizarEstatisticasExercicio(titulo, dano);
      await _salvarEstadoMonstro();

      if (_vidaMonstro <= 0) {
        await _derrotarMonstro();
      }

      await _atualizarXP(_xpGanho);

      _mostrarDialogoAtividadeConcluida(titulo, true);
    } else {
      final titulo = atividade['titulo'] ?? 'Atividade';
      // Registrar falha nas estatísticas
      await _registrarFalhaAtividade(titulo);
      _mostrarDialogoAtividadeConcluida(titulo, false);
    }

    // Limpar estado da atividade
    setState(() {
      _atividadesEmAndamento.remove(idAtividade);
      _tempoRestanteAtividades.remove(idAtividade);
    });

    await _salvarEstadoAtividades();

    // NOVO: Verificar se todas as atividades foram concluídas
    _verificarSePrecisaReset();
  }

  // NOVO: Método para verificar se precisa iniciar o reset
  void _verificarSePrecisaReset() {
    // Se todas as atividades foram realizadas, iniciar reset
    if (_atividadesRealizadasHoje >= _limiteAtividadesDiarias &&
        !_aguardandoReset) {
      _iniciarResetManual();
    }
  }

  // Método para registrar falha de atividade
  Future<void> _registrarFalhaAtividade(String tipoExercicio) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'estatisticas.missoesAtraso': FieldValue.increment(1),
          'estatisticas.dataUltimaAtividade': Timestamp.now(),
        });

        await _adicionarHistoricoAtividade(
          'falha',
          '$tipoExercicio - Tempo esgotado',
        );

        print('❌ Falha registrada: $tipoExercicio');
      }
    } catch (e) {
      print('❌ Erro ao registrar falha: $e');
    }
  }

  // Método para salvar estado das atividades
  Future<void> _salvarEstadoAtividades() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // CONVERTE OS MAPAS PARA FORMATO COMPATÍVEL COM FIREBASE
        Map<String, dynamic> atividadesEmAndamentoFirebase = {};
        Map<String, dynamic> tempoRestanteFirebase = {};
        Map<String, dynamic> atividadesParaConfirmarFirebase = {};

        // Converte Map<String, bool> para Map<String, dynamic>
        _atividadesEmAndamento.forEach((key, value) {
          atividadesEmAndamentoFirebase[key] = value;
        });

        _tempoRestanteAtividades.forEach((key, value) {
          tempoRestanteFirebase[key] = value;
        });

        _atividadesParaConfirmar.forEach((key, value) {
          atividadesParaConfirmarFirebase[key] = value;
        });

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'atividadesRealizadasHoje': _atividadesRealizadasHoje,
          'atividadesEmAndamento': atividadesEmAndamentoFirebase,
          'tempoRestanteAtividades': tempoRestanteFirebase,
          'atividadesParaConfirmar': atividadesParaConfirmarFirebase,
        });

        print(
          '💾 Estado das atividades salvo: ${_atividadesParaConfirmar.length} para confirmar',
        );
      }
    } catch (e) {
      print('❌ Erro ao salvar estado das atividades: $e');
    }
  }

  // Método para cancelar atividade
  Future<void> _cancelarAtividade(String idAtividade) async {
    _timersAtividades[idAtividade]?.cancel();
    _timersAtividades.remove(idAtividade);

    setState(() {
      _atividadesEmAndamento.remove(idAtividade);
      _tempoRestanteAtividades.remove(idAtividade);
    });

    await _salvarEstadoAtividades();

    _mostrarDialogoAtividadeCancelada();
  }

  // NOVO: Prepara a atividade para confirmação
  Future<void> _prepararParaConfirmar(String idAtividade) async {
    final atividade = _atividadesDoDia.firstWhere(
      (a) => a['id'] == idAtividade,
      orElse: () => {},
    );

    if (atividade.isEmpty) return;

    // Parar o timer
    _timersAtividades[idAtividade]?.cancel();
    _timersAtividades.remove(idAtividade);

    setState(() {
      _atividadesEmAndamento[idAtividade] = false;
      _atividadesParaConfirmar[idAtividade] = true;
      _tempoRestanteAtividades.remove(idAtividade);
    });

    await _salvarEstadoAtividades();

    final titulo = atividade['titulo'] ?? 'Atividade';
    _mostrarDialogoPrepararConfirmacao(titulo);
  }

  // NOVO: Confirma que a atividade foi concluída
  Future<void> _confirmarAtividadeConcluida(String idAtividade) async {
    final atividade = _atividadesDoDia.firstWhere(
      (a) => a['id'] == idAtividade,
      orElse: () => {},
    );

    if (atividade.isEmpty) return;

    setState(() {
      _atividadesParaConfirmar.remove(idAtividade);
    });

    await _finalizarAtividade(idAtividade, true); // Conclui com sucesso
  }

  // NOVO: Diálogo para preparar confirmação

  // MÉTODOS EXISTENTES (mantidos para compatibilidade)

  Future<void> _atualizarXP(int xpGanho) async {
    if (_xpHoje + xpGanho > _limiteDiarioXP) {
      _mostrarLimiteDiarioDialog();
      return;
    }

    _xpHoje += xpGanho;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final xpAtual = userDoc.data()?['xp'] ?? 0;
        final novoXP = xpAtual + xpGanho;

        final novoLevel = _calcularLevel(novoXP);
        final levelAtual = userDoc.data()?['level'] ?? 1;

        Map<String, dynamic> updateData = {
          'xp': FieldValue.increment(xpGanho),
          'xpHoje': FieldValue.increment(xpGanho),
          'ultimaData': Timestamp.now(),
        };

        if (novoLevel > levelAtual) {
          updateData['level'] = novoLevel;
          setState(() {
            level = novoLevel;
          });
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(updateData);

        setState(() {
          xp += xpGanho;
        });

        if (novoLevel > levelAtual) {
          _mostrarLevelUp(novoLevel);
        }
      }
    } catch (e) {
      print('Erro ao atualizar XP: $e');
    }
  }

  Future<void> _atualizarMoedas(int moedasGanhas) async {
    if (_moedasHoje + moedasGanhas > _limiteDiarioMoedas) {
      return;
    }

    _moedasHoje += moedasGanhas;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'moedas': FieldValue.increment(moedasGanhas),
          'moedasHoje': FieldValue.increment(moedasGanhas),
        });

        setState(() {
          moedas += moedasGanhas;
        });
      }
    } catch (e) {
      print('Erro ao atualizar moedas: $e');
    }
  }

  Future<void> _atualizarFase(int novaFase) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fase': novaFase,
        });
      }
    } catch (e) {
      print('Erro ao atualizar fase: $e');
    }
  }

  Future<void> _derrotarMonstro() async {
    final faseAtual = _fases[_faseAtual - 1];
    final xpRecompensa = (faseAtual['xpRecompensa'] as num).toInt();
    final moedasRecompensa = (faseAtual['moedasRecompensa'] as num).toInt();

    await _atualizarEstatisticasVitoria();

    _xpGanho += xpRecompensa;

    await _mostrarDialogoVitoria(xpRecompensa, moedasRecompensa);

    if (_faseAtual < _fases.length) {
      setState(() {
        _faseAtual++;
        _vidaMonstro = (_fases[_faseAtual - 1]['vidaMaxima'] as num).toDouble();
        _xpGanho = 0;
      });
    } else {
      setState(() {
        _faseAtual = 1;
        _vidaMonstro = (_fases[0]['vidaMaxima'] as num).toDouble();
        _xpGanho = 0;
      });
    }

    await _atualizarFase(_faseAtual);
    await _salvarEstadoMonstro();
    await _atualizarMoedas(moedasRecompensa);

    print(
      '🎉 Monstro derrotado! Nova fase: $_faseAtual, Vida: ${_vidaMonstro.toStringAsFixed(2)}',
    );
  }

  // DIÁLOGOS DO SISTEMA DE ATIVIDADES

  Future<void> _mostrarDialogoVitoria(
    int xpRecompensa,
    int moedasRecompensa,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1F2D0B),
                  Color(0xFF132007),
                  Color(0xFF0A0F03),
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
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 50,
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
                    child: Center(
                      child: Text(
                        '🏆 VITÓRIA GLORIOSA 🏆',
                        style: TextStyle(
                          color: const Color(0xFF3E2F16),
                          fontFamily: 'MedievalSharp',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 60,
                    bottom: 20,
                    left: 25,
                    right: 25,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🎉', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 10),
                          Text(
                            'Vitória Conquistada!',
                            style: TextStyle(
                              color: const Color(0xFFF3E5AB),
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF8B6C1F),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Você derrotou ${_fases[_faseAtual - 1]['nome']}!',
                          style: TextStyle(
                            color: const Color(0xFFF3E5AB),
                            fontFamily: 'MedievalSharp',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2D5F2D),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.green,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '✨ XP',
                                        style: TextStyle(
                                          color: Colors.green[300],
                                          fontFamily: 'MedievalSharp',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '+$xpRecompensa',
                                        style: TextStyle(
                                          color: Colors.green[300],
                                          fontFamily: 'MedievalSharp',
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(
                                                0.8,
                                              ),
                                              offset: const Offset(1, 1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5F4F2D),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.amber,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '🪙 Moedas',
                                        style: TextStyle(
                                          color: Colors.amber[300],
                                          fontFamily: 'MedievalSharp',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '+$moedasRecompensa',
                                        style: TextStyle(
                                          color: Colors.amber[300],
                                          fontFamily: 'MedievalSharp',
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(
                                                0.8,
                                              ),
                                              offset: const Offset(1, 1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 2,
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/trofeu.png',
                          width: 60,
                          height: 60,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _faseAtual < _fases.length
                              ? '🎯 Fase ${_faseAtual + 1} desbloqueada!'
                              : '🏰 Todas as fases completas! Reiniciando...',
                          style: TextStyle(
                            color: const Color(0xFFF3E5AB),
                            fontFamily: 'MedievalSharp',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFD4AF37),
                              Color(0xFFB8941F),
                              Color(0xFFD4AF37),
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
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(-1, -1),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFF3E2F16),
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '⚔️ CONTINUAR AVENTURA',
                                style: TextStyle(
                                  fontFamily: 'MedievalSharp',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
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
        );
      },
    );
  }

  // DIÁLOGOS ATUALIZADOS NO ESTILO DOS CARDS DE TAREFAS

  // 1. Diálogo de Prêmio Diário Coletado
  void _mostrarDialogoPremioColetado() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2D1F0B).withOpacity(0.95),
                  const Color(0xFF1A1307).withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 15,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: const Text(
                    '🎉 Prêmio Diário Coletado!',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontFamily: 'MedievalSharp',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                // Image.asset('assets/images/tesouro.png', width: 70, height: 70),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF8B6C1F),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildItemPremioCard(
                        '⚡',
                        'XP',
                        '$_premioXP',
                        Colors.green,
                      ),
                      _buildItemPremioCard(
                        '🪙',
                        'Moedas',
                        '$_premioMoedas',
                        Colors.amber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Volte amanhã para mais recompensas!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'MedievalSharp',
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF3E2F16),
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'FECHAR',
                      style: TextStyle(
                        fontFamily: 'MedievalSharp',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. Diálogo de Reset Iniciado
  void _mostrarDialogoResetIniciado() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D1F0B).withOpacity(0.95),
                    const Color(0xFF1A1307).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      '🎯 Missões Concluídas!',
                      style: TextStyle(
                        color: Colors.orange,
                        fontFamily: 'MedievalSharp',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Você completou todas as missões de hoje!\n\nNovas missões estarão disponíveis em 3 horas.\n\nDescanse e se prepare para a próxima batalha!',
                    style: TextStyle(
                      color: Color(0xFFF3E5AB),
                      fontFamily: 'MedievalSharp',
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Color(0xFFFFB74D)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ENTENDIDO',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 3. Diálogo de Atividade Bloqueada
  void _mostrarDialogoAtividadeBloqueada(String motivo) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D1F0B).withOpacity(0.95),
                    const Color(0xFF1A1307).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      '⏰ Atividade Bloqueada',
                      style: TextStyle(
                        color: Colors.blue,
                        fontFamily: 'MedievalSharp',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    motivo,
                    style: const TextStyle(
                      color: Color(0xFFF3E5AB),
                      fontFamily: 'MedievalSharp',
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Color(0xFF64B5F6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ENTENDIDO',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 4. Diálogo de Atividade Iniciada
  void _mostrarDialogoAtividadeIniciada(String titulo, int tempo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D1F0B).withOpacity(0.95),
                    const Color(0xFF1A1307).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      '⏰ Atividade Iniciada!',
                      style: TextStyle(
                        color: Colors.blue,
                        fontFamily: 'MedievalSharp',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Você iniciou: $titulo',
                    style: const TextStyle(
                      color: Color(0xFFF3E5AB),
                      fontFamily: 'MedievalSharp',
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF8B6C1F),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // const Icon(Icons.timer, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Tempo: ${(tempo / 60).ceil()} minutos',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontFamily: 'MedievalSharp',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Complete a atividade antes do tempo acabar!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'MedievalSharp',
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Color(0xFF64B5F6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ENTENDIDO',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 5. Diálogo de Atividade Concluída
  void _mostrarDialogoAtividadeConcluida(String titulo, bool sucesso) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D1F0B).withOpacity(0.95),
                    const Color(0xFF1A1307).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: sucesso ? Colors.green : Colors.red,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: (sucesso ? Colors.green : Colors.red)
                              .withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      sucesso ? '🎉 Missão Cumprida!' : '💀 Tempo Esgotado!',
                      style: TextStyle(
                        color: sucesso ? Colors.green : Colors.red,
                        fontFamily: 'MedievalSharp',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    sucesso
                        ? 'Você completou: $titulo\n\n⚔️ Dano aplicado ao monstro!'
                        : 'Você falhou em: $titulo\n\n⏰ O tempo acabou!',
                    style: const TextStyle(
                      color: Color(0xFFF3E5AB),
                      fontFamily: 'MedievalSharp',
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            sucesso
                                ? [Colors.green, Color(0xFF4CAF50)]
                                : [Colors.red, Color(0xFFF44336)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'CONTINUAR',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 6. Diálogo de Atividade Cancelada
  void _mostrarDialogoAtividadeCancelada() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D1F0B).withOpacity(0.95),
                    const Color(0xFF1A1307).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      '⏹️ Atividade Cancelada',
                      style: TextStyle(
                        color: Colors.orange,
                        fontFamily: 'MedievalSharp',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'A atividade foi cancelada.\n\nSua energia foi recuperada.',
                    style: TextStyle(
                      color: Color(0xFFF3E5AB),
                      fontFamily: 'MedievalSharp',
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Color(0xFFFFB74D)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ENTENDIDO',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 7. Diálogo de Limite de Atividades
  void _mostrarDialogoLimiteAtividades() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D1F0B).withOpacity(0.95),
                    const Color(0xFF1A1307).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      '🎯 Limite Atingido!',
                      style: TextStyle(
                        color: Colors.orange,
                        fontFamily: 'MedievalSharp',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Você já completou todas as atividades de hoje!\n\nVolte amanhã para novas missões.',
                    style: TextStyle(
                      color: Color(0xFFF3E5AB),
                      fontFamily: 'MedievalSharp',
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Color(0xFFFFB74D)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ENTENDIDO',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 8. Diálogo de Preparar Confirmação
  void _mostrarDialogoPrepararConfirmacao(String titulo) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D1F0B).withOpacity(0.95),
                    const Color(0xFF1A1307).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      '🎉 Atividade Concluída!',
                      style: TextStyle(
                        color: Colors.green,
                        fontFamily: 'MedievalSharp',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Você completou: $titulo',
                        style: const TextStyle(
                          color: Color(0xFFF3E5AB),
                          fontFamily: 'MedievalSharp',
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Confirme abaixo para receber sua recompensa!',
                        style: TextStyle(
                          color: Colors.green,
                          fontFamily: 'MedievalSharp',
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.green, Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ENTENDIDO',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 9. Diálogo de Cooldown
  Future<void> _mostrarCooldownDialog(int segundosRestantes) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D1F0B).withOpacity(0.95),
                    const Color(0xFF1A1307).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFFD4AF37).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      '⏰ Calma, Aventureiro!',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontFamily: 'MedievalSharp',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF8B6C1F),
                        width: 1,
                      ),
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Teu espírito precisa descansar!\n\n',
                            style: TextStyle(
                              color: const Color(0xFFF3E5AB),
                              fontFamily: 'MedievalSharp',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Aguarde ',
                            style: TextStyle(
                              color: Color(0xFFF3E5AB),
                              fontFamily: 'MedievalSharp',
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: '$segundosRestantes segundos',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontFamily: 'MedievalSharp',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '\nantes do próximo combate.',
                            style: TextStyle(
                              color: Color(0xFFF3E5AB),
                              fontFamily: 'MedievalSharp',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFF3E2F16),
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ENTENDIDO',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 10. Diálogo de Limite Diário
  Future<void> _mostrarLimiteDiarioDialog() async {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D1F0B).withOpacity(0.95),
                    const Color(0xFF1A1307).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      '🎯 Limite Diário Atingido',
                      style: TextStyle(
                        color: Colors.orange,
                        fontFamily: 'MedievalSharp',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Você já conquistou todo o XP disponível hoje! Volte amanhã para mais aventuras.',
                    style: TextStyle(
                      color: Color(0xFFF3E5AB),
                      fontFamily: 'MedievalSharp',
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Color(0xFFFFB74D)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ENTENDIDO',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 11. Diálogo Sem Stamina
  Future<void> _mostrarSemStaminaDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A0F2D).withOpacity(0.95),
                    const Color(0xFF130A23).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      '⚡ Energia Esgotada!',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontFamily: 'MedievalSharp',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6D28D9),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Tua energia mística se esvaiu!\n\nAguarde alguns minutos para que tua força retorne.',
                      style: TextStyle(
                        color: Color(0xFFE9D5FF),
                        fontFamily: 'MedievalSharp',
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'DESCANSAR',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 12. Diálogo de Level Up (ATUALIZADO NO ESTILO DOS CARDS)
  Future<void> _mostrarLevelUp(int novoLevel) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0B2D1F).withOpacity(0.95),
                  const Color(0xFF072013).withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF37D46B), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 15,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFF37D46B).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: const Text(
                    '🌟 Evolução Gloriosa!',
                    style: TextStyle(
                      color: Color(0xFF37D46B),
                      fontFamily: 'MedievalSharp',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Parabéns! Você subiu de nível!',
                  style: TextStyle(
                    color: Color(0xFFABF3C8),
                    fontFamily: 'MedievalSharp',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: const Color(0xFF37D46B),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF37D46B).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Text(
                    'Level $novoLevel',
                    style: const TextStyle(
                      color: Color(0xFF37D46B),
                      fontFamily: 'MedievalSharp',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF37D46B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF37D46B),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Próximo level em: ${_calcularXPProximoLevel() - xp} XP',
                    style: const TextStyle(
                      color: Color(0xFFABF3C8),
                      fontFamily: 'MedievalSharp',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF37D46B), Color(0xFF1FB854)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'CONTINUAR JORNADA',
                      style: TextStyle(
                        fontFamily: 'MedievalSharp',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget auxiliar para itens de prêmio nos diálogos
  Widget _buildItemPremioCard(
    String emoji,
    String tipo,
    String valor,
    Color cor,
  ) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 5),
        Text(
          tipo,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'MedievalSharp',
            fontSize: 10,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            color: cor,
            fontFamily: 'MedievalSharp',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // WIDGETS DA INTERFACE
  // ADICIONE ESTE MÉTODO QUE ESTÁ FALTANDO:
  void _mostrarDialogoAtividadeEmAndamento() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D1F0B).withOpacity(0.95),
                    const Color(0xFF1A1307).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      '⏰ Atividade em Andamento',
                      style: TextStyle(
                        color: Colors.blue,
                        fontFamily: 'MedievalSharp',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Você já tem uma atividade em andamento!\n\nComplete ou cancele a atividade atual antes de iniciar outra.',
                    style: TextStyle(
                      color: Color(0xFFF3E5AB),
                      fontFamily: 'MedievalSharp',
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Color(0xFF64B5F6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ENTENDIDO',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
    final fase = _fases[_faseAtual - 1];
    final double vidaMaxima = (fase['vidaMaxima'] as num).toDouble();
    final double porcentagemVida = (_vidaMonstro / vidaMaxima).clamp(0.0, 1.0);
    final double porcentagemStamina = _stamina / _staminaMaxima;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fundo dinâmico baseado na fase
          Positioned.fill(
            child: Image.asset(fase['cenario'], fit: BoxFit.cover),
          ),

          // LAYOUT PRINCIPAL
          Column(
            children: [
              // Cabeçalho fixo
              SafeArea(
                bottom: false,
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MeuPerfilPage(),
                                  ),
                                );
                              },
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/perfil.png',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nome,
                                  style: const TextStyle(
                                    color: Color(0xFFF3E5AB),
                                    fontFamily: 'MedievalSharp',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Level $level | ${xp}Xp',
                                  style: const TextStyle(
                                    color: Color(0xFFF3E5AB),
                                    fontFamily: 'MedievalSharp',
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Fase $_faseAtual',
                                  style: const TextStyle(
                                    color: Color(0xFFF3E5AB),
                                    fontFamily: 'MedievalSharp',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () async {
                                await FirebaseAuth.instance.signOut();
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/login');
                              },
                              child: Image.asset(
                                'assets/images/porta_sair.png',
                                width: 30,
                                height: 30,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/moeda.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  moedas.toString(),
                                  style: const TextStyle(
                                    color: Color(0xFFF3E5AB),
                                    fontFamily: 'MedievalSharp',
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 100,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Text(
                                        '⚡ ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        '$_stamina/$_staminaMaxima',
                                        style: const TextStyle(
                                          color: Color(0xFFF3E5AB),
                                          fontFamily: 'MedievalSharp',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(1, 1),
                                              blurRadius: 2,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 100,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D1F0B),
                                      border: Border.all(
                                        color: const Color(0xFF8B6C1F),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 3,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: porcentagemStamina,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF4A90E2),
                                                const Color(0xFF7BB0FF),
                                                if (porcentagemStamina > 0.7)
                                                  const Color(0xFF4A90E2),
                                                if (porcentagemStamina <= 0.3)
                                                  const Color(0xFFE23645),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_stamina < _staminaMaxima) ...[
                                    const SizedBox(height: 2),
                                    const Text(
                                      '⚡ Recarregando...',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 8,
                                        fontFamily: 'MedievalSharp',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Indicador de limite diário
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.black.withOpacity(0.6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'XP Hoje: $_xpHoje/$_limiteDiarioXP',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontFamily: 'MedievalSharp',
                      ),
                    ),
                  ],
                ),
              ),

              // CONTEÚDO PRINCIPAL COM SCROLL
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // Indicador de fase
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Color(0xFFD4AF37),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'Fase $_faseAtual: ${fase['nome']}',
                          style: const TextStyle(
                            color: Color(0xFFF3E5AB),
                            fontFamily: 'MedievalSharp',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Imagem do monstro
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            fase['monstro'],
                            width: double.infinity,
                            height: fase['height'] ?? 280.0,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // STATUS DO MONSTRO
                      Column(
                        children: [
                          Container(
                            width: 340,
                            child: Column(
                              children: [
                                // Topo da barra de vida
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.9),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                    border: Border.all(
                                      color: Color(0xFFD4AF37),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 6,
                                        offset: Offset(3, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${(_vidaMonstro * 100).toInt()}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'MedievalSharp',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        '⚔️',
                                        style: TextStyle(
                                          color: Color(0xFFD4AF37),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${(vidaMaxima * 100).toInt()}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'MedievalSharp',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Barra de vida
                                Container(
                                  width: 340,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2D1F0B),
                                    border: Border.all(
                                      color: Color(0xFF8B6C1F),
                                      width: 2,
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: Offset(4, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF3A2A15),
                                                Color(0xFF2D1F0B),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                          ),
                                        ),

                                        FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: porcentagemVida,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.red.shade900,
                                                  Colors.red.shade700,
                                                  porcentagemVida > 0.3
                                                      ? Colors.orange.shade600
                                                      : Colors.red.shade600,
                                                  if (porcentagemVida > 0.7)
                                                    Colors.green.shade600,
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                            ),
                                          ),
                                        ),

                                        if (_estaLevandoDano)
                                          Container(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                          ),

                                        Center(
                                          child: Text(
                                            '${(porcentagemVida * 100).toInt()}%',
                                            style: TextStyle(
                                              color:
                                                  porcentagemVida > 0.4
                                                      ? Colors.white
                                                      : Colors.black,
                                              fontFamily: 'MedievalSharp',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black
                                                      .withOpacity(0.8),
                                                  offset: Offset(1, 1),
                                                  blurRadius: 3,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Estado do monstro
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCorEstado(
                                      porcentagemVida,
                                    ).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: _getCorEstado(porcentagemVida),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _getEstadoMonstro(porcentagemVida),
                                    style: TextStyle(
                                      color: _getCorEstado(porcentagemVida),
                                      fontFamily: 'MedievalSharp',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.6),
                                          offset: Offset(1, 1),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Texto da história
                      Container(
                        width: 400,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Color(0xFFD4AF37),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          fase['descricao'],
                          style: const TextStyle(
                            color: Color(0xFFF3E5AB),
                            fontFamily: 'MedievalSharp',
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Contador de atividades
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // const Icon(
                                //   Icons.fitness_center,
                                //   size: 16,
                                //   color: Colors.amber,
                                // ),
                                const SizedBox(width: 8),
                                Text(
                                  'Atividades: $_atividadesRealizadasHoje/$_limiteAtividadesDiarias',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 14,
                                    fontFamily: 'MedievalSharp',
                                  ),
                                ),
                                if (_atividadesEmAndamento.values.any(
                                  (v) => v,
                                )) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        // Icon(
                                        //   Icons.timer,
                                        //   size: 12,
                                        //   color: Colors.white,
                                        // ),
                                        SizedBox(width: 4),
                                        Text(
                                          'EM ANDAMENTO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontFamily: 'MedievalSharp',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _aguardandoReset
                                  ? 'Próximo reset em: ${_formatarTempoReset(_tempoRestanteReset)}'
                                  : 'Complete as missões para desbloquear novas!',
                              style: TextStyle(
                                color:
                                    _aguardandoReset
                                        ? Colors.green
                                        : Colors.amber,
                                fontSize: 12,
                                fontFamily: 'MedievalSharp',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // NOVO: LISTA DE ATIVIDADES - ADICIONE ESTA SEÇÃO
                      if (_atividadesDoDia.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🎯 Missões do Dia',
                                style: TextStyle(
                                  color: Color(0xFFF3E5AB),
                                  fontFamily: 'MedievalSharp',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 150, // Altura fixa para o carrossel
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _atividadesDoDia.length,
                                  itemBuilder: (context, index) {
                                    return _buildAtividadeCard(
                                      _atividadesDoDia[index],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (!carregando) ...[
                        // Mensagem quando não há atividades
                        Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFFD4AF37),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '⏰ Aguardando novas missões...',
                                style: TextStyle(
                                  color: Color(0xFFF3E5AB),
                                  fontFamily: 'MedievalSharp',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _aguardandoReset
                                    ? 'Novas missões disponíveis em: ${_formatarTempoReset(_tempoRestanteReset)}'
                                    : 'Complete as missões atuais para desbloquear mais!',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'MedievalSharp',
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // FOOTER
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  border: const Border(
                    top: BorderSide(color: Color(0xFFD4AF37), width: 2),
                  ),
                ),
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: 20,
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        MenuItem(icon: '🏰', label: 'Home'),
                        MenuItem(icon: '⚔️', label: 'Desafios'),
                        MenuItem(icon: '📊', label: 'Estatísticas'),
                        MenuItem(icon: '🛒', label: 'Loja'),
                        MenuItem(
                          icon: _premioDiarioDisponivel ? '🎁✨' : '🎁',
                          label: 'Baú',
                          onTap: _mostrarModalBauDiario,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGETS DAS ATIVIDADES
  Widget _buildAtividadeCard(Map<String, dynamic> atividade) {
    final id = atividade['id'] ?? '';
    final emoji = atividade['emoji'] ?? '💪';
    final titulo = atividade['titulo'] ?? 'Atividade';
    final energia = atividade['energia'] ?? 10;
    final dano = atividade['dano'] ?? 0.1;
    final tempo = atividade['tempo'] ?? 300;

    final emAndamento = _atividadesEmAndamento[id] == true;
    final tempoRestante = _tempoRestanteAtividades[id] ?? 0;
    final podeConfirmar = _atividadesParaConfirmar[id] == true;

    // NOVO: Verificar se existe alguma atividade em andamento (qualquer uma)
    final existeAtividadeEmAndamento = _atividadesEmAndamento.values.any(
      (estaEmAndamento) => estaEmAndamento == true,
    );

    // NOVO: Verificar se esta atividade já foi realizada no ciclo atual
    final jaRealizada =
        _atividadesRealizadasHoje > 0 &&
        _atividadesDoDia.indexWhere((a) => a['id'] == id) <
            _atividadesRealizadasHoje;

    final podeRealizar =
        _stamina >= energia &&
        _atividadesRealizadasHoje < _limiteAtividadesDiarias &&
        !emAndamento &&
        !podeConfirmar &&
        !jaRealizada && 
        !existeAtividadeEmAndamento;

    // NOVO: Cor baseada no estado
    Color corBorda;
    Color corTexto;
    bool estaBloqueada = false;

    if (podeConfirmar) {
      corBorda = Colors.green;
      corTexto = Colors.green.shade100;
    } else if (emAndamento) {
      corBorda = const Color(0xFFD4AF37);
      corTexto = const Color(0xFFF3E5AB);
    } else if (jaRealizada) {
      // NOVO: Atividade já realizada - fica cinza
      corBorda = Colors.grey.shade600;
      corTexto = Colors.grey.shade400;
      estaBloqueada = true;
    } else if (existeAtividadeEmAndamento) {
      // NOVO: Existe outra atividade em andamento - fica cinza
      corBorda = Colors.grey.shade600;
      corTexto = Colors.grey.shade400;
      estaBloqueada = true;
    } else if (podeRealizar) {
      corBorda = const Color(0xFFD4AF37);
      corTexto = const Color(0xFFF3E5AB);
    } else {
      corBorda = Colors.grey.shade600;
      corTexto = Colors.grey.shade400;
      estaBloqueada = true;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        width: 220,
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                podeConfirmar
                    ? [
                      const Color(0xFF1F2D0B).withOpacity(0.9),
                      const Color(0xFF132007).withOpacity(0.9),
                    ]
                    : emAndamento
                    ? [
                      const Color(0xFF2D1F0B).withOpacity(0.9),
                      const Color(0xFF1A1307).withOpacity(0.9),
                    ]
                    : estaBloqueada // NOVO: Gradiente para bloqueado
                    ? [
                      Colors.grey.shade800.withOpacity(0.7),
                      Colors.grey.shade900.withOpacity(0.7),
                    ]
                    : podeRealizar
                    ? [
                      const Color(0xFF2D1F0B).withOpacity(0.9),
                      const Color(0xFF1A1307).withOpacity(0.9),
                    ]
                    : [
                      Colors.grey.shade800.withOpacity(0.7),
                      Colors.grey.shade900.withOpacity(0.7),
                    ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: corBorda, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Título centralizado
            Column(
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: corTexto,
                    fontFamily: 'MedievalSharp',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // NOVO: Indicador de estado
                if (jaRealizada) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'CONCLUÍDA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontFamily: 'MedievalSharp',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else if (existeAtividadeEmAndamento && !emAndamento) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'AGUARDANDO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontFamily: 'MedievalSharp',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            if (emAndamento || podeConfirmar) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  podeConfirmar
                      ? '✅ PRONTO PARA CONFIRMAR!'
                      : _formatarTempo(tempoRestante),
                  style: TextStyle(
                    color:
                        podeConfirmar ? Colors.green : const Color(0xFFF3E5AB),
                    fontFamily: 'MedievalSharp',
                    fontSize: podeConfirmar ? 12 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 6),

            // Status (energia e dano na mesma linha) - ESTILO ORIGINAL
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF8B6C1F).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Energia necessária
                  Row(
                    children: [
                      Text(
                        '⚡',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              estaBloqueada
                                  ? Colors.grey
                                  : podeConfirmar
                                  ? Colors.green
                                  : emAndamento
                                  ? Colors.blue.shade300
                                  : podeRealizar
                                  ? Colors.blue.shade300
                                  : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$energia',
                        style: TextStyle(
                          color:
                              estaBloqueada
                                  ? Colors.grey
                                  : podeConfirmar
                                  ? Colors.green.shade100
                                  : emAndamento
                                  ? Colors.blue.shade100
                                  : podeRealizar
                                  ? Colors.blue.shade100
                                  : Colors.grey,
                          fontSize: 13,
                          fontFamily: 'MedievalSharp',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Divisor
                  Container(
                    width: 1,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: const Color(0xFF8B6C1F).withOpacity(0.5),
                  ),

                  // Poder de ataque
                  Row(
                    children: [
                      Text(
                        '⚔️',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              estaBloqueada
                                  ? Colors.grey
                                  : podeConfirmar
                                  ? Colors.green
                                  : emAndamento
                                  ? Colors.red.shade300
                                  : podeRealizar
                                  ? Colors.red.shade300
                                  : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(dano * 100).toInt()}%',
                        style: TextStyle(
                          color:
                              estaBloqueada
                                  ? Colors.grey
                                  : podeConfirmar
                                  ? Colors.green.shade100
                                  : emAndamento
                                  ? Colors.red.shade100
                                  : podeRealizar
                                  ? Colors.red.shade100
                                  : Colors.grey,
                          fontSize: 13,
                          fontFamily: 'MedievalSharp',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Divisor
                  Container(
                    width: 1,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: const Color(0xFF8B6C1F).withOpacity(0.5),
                  ),

                  // Tempo
                  Row(
                    children: [
                      // Icon(
                      //   Icons.timer,
                      //   size: 12,
                      //   color:
                      //       estaBloqueada
                      //           ? Colors.grey
                      //           : podeConfirmar
                      //           ? Colors.green.shade100
                      //           : Colors.white70,
                      // ),
                      const SizedBox(width: 4),
                      Text(
                        '${(tempo / 60).ceil()}min',
                        style: TextStyle(
                          color:
                              estaBloqueada
                                  ? Colors.grey
                                  : podeConfirmar
                                  ? Colors.green.shade100
                                  : Colors.white70,
                          fontSize: 11,
                          fontFamily: 'MedievalSharp',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Botão - DIFERENTES ESTADOS
            Container(
              width: double.infinity,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient:
                    podeConfirmar
                        ? const LinearGradient(
                          colors: [Colors.green, Colors.lightGreen],
                        )
                        : emAndamento
                        ? const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB)],
                        )
                        : estaBloqueada
                        ? LinearGradient(
                          colors: [Colors.grey.shade600, Colors.grey.shade700],
                        )
                        : podeRealizar
                        ? const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB)],
                        )
                        : LinearGradient(
                          colors: [Colors.grey.shade600, Colors.grey.shade700],
                        ),
              ),
              child: ElevatedButton(
                onPressed:
                    podeConfirmar
                        ? () => _confirmarAtividadeConcluida(id)
                        : emAndamento
                        ? () => _prepararParaConfirmar(id)
                        : estaBloqueada
                        ? null // NOVO: Bloqueado se já realizada ou outra em andamento
                        : podeRealizar
                        ? () => realizarExercicio(id)
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor:
                      podeConfirmar
                          ? Colors.white
                          : emAndamento
                          ? const Color(0xFF3E2F16)
                          : estaBloqueada
                          ? Colors.grey.shade300
                          : podeRealizar
                          ? const Color(0xFF3E2F16)
                          : Colors.grey.shade300,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon(
                    //   podeConfirmar
                    //       ? Icons.check_circle
                    //       : emAndamento
                    //       ? Icons.done_all
                    //       : estaBloqueada
                    //       ? Icons.lock_outline
                    //       :
                    //       podeRealizar
                    //       ? Icons.play_arrow
                    //       : Icons.lock,
                    //   size: 14,
                    // ),
                    const SizedBox(width: 6),
                    Text(
                      podeConfirmar
                          ? 'CONFIRMAR CONCLUÍDA'
                          : emAndamento
                          ? 'TERMINEI A ATIVIDADE'
                          : estaBloqueada
                          ? 'BLOQUEADA'
                          : // NOVO: Texto para bloqueado
                          podeRealizar
                          ? 'ATACAR'
                          : 'BLOQUEADA',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'MedievalSharp',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarTempo(int segundos) {
    final minutos = segundos ~/ 60;
    final segundosRestantes = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundosRestantes.toString().padLeft(2, '0')}';
  }

  Widget _buildCarregandoAtividades() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFD4AF37)),
          SizedBox(height: 10),
          Text(
            'Gerando atividades do dia...',
            style: TextStyle(
              color: Color(0xFFF3E5AB),
              fontFamily: 'MedievalSharp',
            ),
          ),
        ],
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onTap;

  const MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap:
            onTap ??
            () {
              if (label == 'Desafios') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DesafiosPage()),
                );
              } else if (label == 'Loja') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LojaPage()),
                );
              } else if (label == 'Estatísticas') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EstatisticasPage()),
                );
              } else if (label == 'Baú') {
                // Já está sendo tratado pelo onTap personalizado
              }
            },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFFF3E5AB)),
            ),
          ],
        ),
      ),
    );
  }
}
