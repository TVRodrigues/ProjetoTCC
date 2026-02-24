import 'package:flutter/material.dart';
// Descomente as importações abaixo quando formos ligar os ecrãs
// import 'tela_ar.dart';
// import 'main.dart'; // Assumindo que a classe do seu scanner está aqui

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  // Gestão de estado da arquitetura
  bool _estaAProcessar = false;
  bool _raPronta = false;

  // Função que simula o envio das imagens para um servidor backend
  Future<void> _simularProcessamentoNaNuvem() async {
    setState(() {
      _estaAProcessar = true;
      _raPronta = false;
    });

    // O "Mágico de Oz": Simulamos 4 segundos de latência de rede e processamento
    await Future.delayed(const Duration(seconds: 4));

    setState(() {
      _estaAProcessar = false;
      _raPronta = true;
    });

    // Feedback visual de sucesso para o utilizador
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Imagens processadas e transformadas em alvos RA!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcador RA - Hub Central'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CARD DE STATUS DO SISTEMA
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: _raPronta ? Colors.green.shade50 : Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        _raPronta
                            ? Icons.check_circle_outline
                            : (_estaAProcessar
                                  ? Icons.cloud_upload_outlined
                                  : Icons.image_search),
                        size: 72,
                        color: _raPronta
                            ? Colors.green
                            : (_estaAProcessar ? Colors.blue : Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _raPronta
                            ? "Realidade Aumentada Pronta!"
                            : (_estaAProcessar
                                  ? "A processar alvos na nuvem..."
                                  : "A aguardar novas imagens..."),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _raPronta
                              ? Colors.green.shade700
                              : Colors.black87,
                        ),
                      ),
                      if (_estaAProcessar) ...[
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // BOTÃO 1: ESCANEAR NOVO MARCADOR
              ElevatedButton.icon(
                onPressed: _estaAProcessar
                    ? null // Bloqueia o botão durante o processamento
                    : () async {
                        // Passo 1: Navega para o ecrã do Scanner (ML Kit)
                        // AQUI ENTRA A NAVEGAÇÃO PARA O SEU CÓDIGO EXISTENTE
                        // await Navigator.push(context, MaterialPageRoute(builder: (context) => const SuaClasseDeScanner()));

                        // Passo 2: Quando o utilizador voltar do scanner, iniciamos a simulação
                        _simularProcessamentoNaNuvem();
                      },
                icon: const Icon(Icons.document_scanner),
                label: const Text('1. Escanear Nova Página'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),

              // BOTÃO 2: ABRIR REALIDADE AUMENTADA
              ElevatedButton.icon(
                onPressed: _raPronta
                    ? () {
                        // Navega para o Ecrã de RA apenas quando estiver pronto
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaAR(imagensAlvo: [])));
                      }
                    : null, // Fica cinzento e inativo se não estiver pronto
                icon: const Icon(Icons.view_in_ar),
                label: const Text('2. Abrir Visualizador RA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
