import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart' as math;

class TelaAR extends StatefulWidget {
  const TelaAR({super.key});

  @override
  State<TelaAR> createState() => _TelaARState();
}

class _TelaARState extends State<TelaAR> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcador RA (Toque na Tela)'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            // Ligamos a deteção de planos (superfícies horizontais e verticais)
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.only(bottom: 30),
              child: const Text(
                'Aponte para a página e toque nos pontos brancos para ancorar!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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

    // LIGANDO OS PONTOS E A MALHA PADRÃO
    arSessionManager!.onInitialize(
      showFeaturePoints: true, // <-- Mudamos para true (mostra os pontinhos)
      showPlanes: true, // <-- Mantemos true (mostra as superfícies)
      // Removemos a linha do customPlaneTexturePath para usar a malha padrão do ARCore
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
    );
    arObjectManager!.onInitialize();

    // Define o que acontece quando o utilizador toca no ecrã
    arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
  }

  // Função disparada ao tocar na superfície
  // Função disparada ao tocar na superfície
  Future<void> onPlaneOrPointTapped(
    List<ARHitTestResult> hitTestResults,
  ) async {
    // Medida de segurança: se o utilizador tocou mas não houve interseção, ignoramos
    if (hitTestResults.isEmpty) return;

    // Procura se o utilizador tocou em cima de um plano válido detetado pelo telemóvel
    var singleHitTestResult = hitTestResults.firstWhere(
      (result) => result.type == ARHitTestResultType.plane,
      orElse: () => hitTestResults.first,
    );

    // O Null Safety garante que temos um resultado válido, então criamos a âncora direto
    var newAnchor = ARPlaneAnchor(
      transformation: singleHitTestResult.worldTransform,
    );
    bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);

    if (didAddAnchor == true) {
      anchors.add(newAnchor);

      // Prepara a nossa anotação 3D
      var newNode = ARNode(
        type: NodeType.webGLB,
        uri:
            "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Binary/Duck.glb",
        scale: math.Vector3(0.05, 0.05, 0.05),
        position: math.Vector3(0.0, 0.0, 0.0),
        rotation: math.Vector4(1.0, 0.0, 0.0, 0.0),
      );

      // Adiciona o nó 3D "grudado" na âncora
      bool? didAddNodeToAnchor = await arObjectManager!.addNode(
        newNode,
        planeAnchor: newAnchor,
      );
      if (didAddNodeToAnchor == true) {
        nodes.add(newNode);
      }
    }
  }
}
