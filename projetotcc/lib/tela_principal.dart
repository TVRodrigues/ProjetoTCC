import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'tela_lista_paginas.dart';
import 'main.dart';
import 'models/scan.dart';
import 'services/scan_storage_service.dart';

enum _LoadingPhase { count, skeleton, details, loaded, empty, error }

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  final ScanStorageService _storage = ScanStorageService();

  int? _count;
  List<Scan>? _scans;
  _LoadingPhase _phase = _LoadingPhase.count;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarLista();
  }

  Future<void> _carregarLista() async {
    if (!mounted) return;
    setState(() {
      _phase = _LoadingPhase.count;
      _count = null;
      _scans = null;
      _errorMessage = null;
    });

    try {
      // Fase 1: quantidade
      final count = await _storage.getScansCount();
      if (!mounted) return;
      setState(() {
        _count = count;
        _phase = count == 0 ? _LoadingPhase.empty : _LoadingPhase.skeleton;
      });

      if (count == 0) return;

      // Fase 2: skeleton já visível (N placeholders)
      // Fase 3: detalhes
      final scans = await _storage.loadScans();
      if (!mounted) return;
      setState(() {
        _scans = scans;
        _phase = _LoadingPhase.loaded;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _LoadingPhase.error;
        _errorMessage = 'Erro ao carregar. Reabra a app.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Livros'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _carregarLista,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const TelaGaleria(),
            ),
          );
          if (result == true && mounted) {
            _carregarLista();
          }
        },
        tooltip: 'Escanear nova página',
        backgroundColor: Colors.blueAccent,
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.menu_book, size: 28),
            Positioned(
              bottom: 4,
              right: 4,
              child: Icon(Icons.add_circle, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _LoadingPhase.count:
        return const Center(child: CircularProgressIndicator());
      case _LoadingPhase.empty:
        return _buildEmpty();
      case _LoadingPhase.skeleton:
      case _LoadingPhase.details:
        return _buildSkeletonList();
      case _LoadingPhase.loaded:
        return _buildBookList();
      case _LoadingPhase.error:
        return _buildError();
    }
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Nenhum livro guardado. Toque no botão + para escanear.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    final n = _count ?? 5;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: n,
      itemBuilder: (context, index) => _SkeletonItem(),
    );
  }

  Widget _buildBookList() {
    final scans = _scans ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scans.length,
      itemBuilder: (context, index) {
        final scan = scans[index];
        return _BookListItem(
          scan: scan,
          onTap: () => _abrirLivro(scan),
        );
      },
    );
  }

  Widget _buildError() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _errorMessage ?? 'Erro ao carregar. Reabra a app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirLivro(Scan scan) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Spec 002: se as imagens do livro foram removidas do storage, remover livro e atualizar lista
    var todasExistem = true;
    for (final p in scan.imagePaths) {
      if (!await File(p).exists()) {
        todasExistem = false;
        break;
      }
    }
    if (!todasExistem) {
      try {
        await _storage.deleteScan(scan.id);
      } catch (_) {}
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Imagens não encontradas. Livro removido da lista.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _carregarLista();
      return;
    }

    if (!mounted) return;
    final result = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (context) => TelaListaPaginas(scan: scan),
      ),
    );
    if (result == true && mounted) {
      _carregarLista();
    }
  }
}

class _SkeletonItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade800,
        highlightColor: Colors.grey.shade600,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _BookListItem extends StatelessWidget {
  final Scan scan;
  final VoidCallback onTap;

  const _BookListItem({required this.scan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.blueAccent),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    scan.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
