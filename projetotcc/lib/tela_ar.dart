import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:vector_math/vector_math_64.dart' as math;

class TelaAR extends StatefulWidget {
  // A lista de caminhos das imagens que vêm da galeria do main.dart
  final List<String> imagensAlvo;

  const TelaAR({super.key, required this.imagensAlvo});

  @override
  State<TelaAR> createState() => _TelaARState();
}

class _TelaARState extends State<TelaAR> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  // Guarda as âncoras para sabermos que páginas já têm o 3D por cima
  Map<String, ARNode> objetosNasPaginas = {};

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcador RA Inteligente'),
        backgroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            // Desligamos a deteção de chão porque só nos interessam as páginas
            planeDetectionConfig: PlaneDetectionConfig.none,
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Aponte a câmara para uma página escaneada",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    // Inicializa o motor focado apenas em rastreio de imagem
    arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
      showWorldOrigin: false,
      handlePans: false,
      handleRotation: false,
    );
    arObjectManager!.onInitialize();

    // Configura o ouvinte: o que fazer quando a câmara encontrar uma imagem?
    arSessionManager!.onAugmentedImageAdd = _aoEncontrarPagina;

    // Carrega a nossa galeria de fotografias para a memória do ARCore
    _carregarImagensAlvo();
  }

  Future<void> _carregarImagensAlvo() async {
    for (int i = 0; i < widget.imagensAlvo.length; i++) {
      String caminhoFicheiro = widget.imagensAlvo[i];
      String nomeAlvo = "pagina_$i"; // Dá um nome único a cada página

      // Adiciona a imagem física ao motor de reconhecimento
      await arSessionManager!.addAugmentedImage(nomeAlvo, caminhoFicheiro);
      debugPrint("✅ Alvo registado na memória do ARCore: $nomeAlvo");
    }
  }

  // Esta função é chamada automaticamente quando a câmara reconhece o livro
  Future<void> _aoEncontrarPagina(ARAugmentedImage imagemReconhecida) async {
    String nomePagina = imagemReconhecida.name;

    // Se já colocámos o pato nesta página, não fazemos nada
    if (objetosNasPaginas.containsKey(nomePagina)) return;

    debugPrint("🔥 O ARCore encontrou a página: $nomePagina!");

    // Cria uma âncora invisível "colada" exatamente no centro da imagem de papel
    ARNode novoObjeto = ARNode(
      type: NodeType.webGLB,
      uri:
          "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Binary/Duck.glb",
      scale: math.Vector3(0.1, 0.1, 0.1), // Um pouco menor para caber na página
      position: math.Vector3(0.0, 0.0, 0.0), // Fica exatamente sobre a âncora
      rotation: math.Vector4(1.0, 0.0, 0.0, 0.0),
    );

    // Adiciona o objeto associado a essa imagem detetada
    bool? sucesso = await arObjectManager!.addNode(novoObjeto);

    if (sucesso == true) {
      setState(() {
        objetosNasPaginas[nomePagina] = novoObjeto;
      });
    }
  }
}
