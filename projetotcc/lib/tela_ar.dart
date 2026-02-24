import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as math;

class TelaAR extends StatefulWidget {
  const TelaAR({super.key});

  @override
  State<TelaAR> createState() => _TelaARState();
}

class _TelaARState extends State<TelaAR> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARNode? objeto3D;

  @override
  void dispose() {
    // É crucial limpar a sessão de RA ao fechar o ecrã para não esgotar a bateria do telemóvel
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualizador RA'),
        backgroundColor: Colors.black87,
      ),
      // Aqui usamos o Stack para colocar os nossos botões POR CIMA da câmara 3D
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: ElevatedButton(
                onPressed: _adicionarOuRemoverObjeto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  objeto3D == null ? 'Adicionar Objeto 3D' : 'Remover Objeto',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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

    // Inicializa o motor de RA.
    // showPlanes: mostra pontinhos brancos no ecrã quando ele deteta uma superfície
    arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
    );
    arObjectManager!.onInitialize();
  }

  Future<void> _adicionarOuRemoverObjeto() async {
    if (objeto3D != null) {
      // Se já existe um objeto, o botão serve para o remover da cena
      arObjectManager!.removeNode(objeto3D!);
      setState(() {
        objeto3D = null;
      });
    } else {
      // Se não existe, vamos descarregar um modelo 3D gratuito de teste diretamente da internet
      var novoObjeto = ARNode(
        type: NodeType.webGLB, // <--- O tipo correto agora é webGLB
        // Link atualizado para baixar o arquivo .glb (binário) direto do repositório oficial
        uri:
            "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Duck/glTF-Binary/Duck.glb",
        scale: math.Vector3(0.2, 0.2, 0.2),
        position: math.Vector3(0.0, 0.0, -1.0),
        rotation: math.Vector4(1.0, 0.0, 0.0, 0.0),
      );

      bool? sucesso = await arObjectManager!.addNode(novoObjeto);

      if (sucesso == true) {
        setState(() {
          objeto3D = novoObjeto;
        });
      }
    }
  }
}
