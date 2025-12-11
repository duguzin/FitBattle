import 'package:flutter/material.dart';

class LojaPage extends StatelessWidget {
  final int moedas = 450;

  final List<ItemLoja> itens = [
    ItemLoja(
      nome: '🍌 Cacho de Banana',
      descricao: 'Banana fresca direto do hortifrúti parceiro.',
      preco: 80,
      imagem: 'assets/images/imagens_loja/banana.png',
    ),
    ItemLoja(
      nome: '🍫 Barra de Proteína',
      descricao: 'Barra sabor chocolate com 15g de proteína.',
      preco: 150,
      imagem: 'assets/images/imagens_loja/barra_proteina.png',
    ),
    ItemLoja(
      nome: '💪 Creatina (amostra)',
      descricao: 'Porção única de creatina monohidratada.',
      preco: 300,
      imagem: 'assets/images/imagens_loja/creatina.png',
    ),
    ItemLoja(
      nome: '🧃 Suco Natural',
      descricao: 'Suco gelado, natural, de laranja ou acerola.',
      preco: 100,
      imagem: 'assets/images/imagens_loja/suco_laranja.png',
    ),
  ];

  LojaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/mercado_medieval3.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🛒 Loja de Recompensas',
                        style: TextStyle(
                          fontFamily: 'MedievalSharp',
                          fontSize: 24,
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              '🪙',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              moedas.toString(),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontFamily: 'MedievalSharp',
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: itens.length,
                    itemBuilder: (context, index) {
                      final item = itens[index];
                      final podeComprar = moedas >= item.preco;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              child: Image.asset(
                                item.imagem,
                                width: 150,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.nome,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'MedievalSharp',
                                        color: Color(0xFFF3E5AB),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.descricao,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontFamily: 'MedievalSharp',
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: ElevatedButton(
                                        onPressed: podeComprar ? () {} : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFD4AF37),
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Comprar',
                                          style: TextStyle(fontFamily: 'MedievalSharp'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ItemLoja {
  final String nome;
  final String descricao;
  final int preco;
  final String imagem;

  ItemLoja({
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.imagem,
  });
}
