import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/anima_service.dart';
import '../src/rust/db.dart';

class MemoryBrowserScreen extends StatefulWidget {
  const MemoryBrowserScreen({super.key});

  @override
  State<MemoryBrowserScreen> createState() => _MemoryBrowserScreenState();
}

class _MemoryBrowserScreenState extends State<MemoryBrowserScreen> {
  List<MemoryItem> _memories = [];
  bool _isLoading = true;
  bool _isBackHovered = false;

  Widget _buildAnimatedAppBarBackButton() {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isBackHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isBackHovered = false;
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        scale: _isBackHovered ? 1.06 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _isBackHovered ? Colors.white.withAlpha(12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isBackHovered
                  ? Colors.white.withAlpha(24)
                  : Colors.transparent,
            ),
          ),
          child: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final animaService = context.read<AnimaService>();
      final memories = await animaService.getAllMemories();
      if (!mounted) return;
      setState(() {
        _memories = memories;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando memorias: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMemory(MemoryItem memory) async {
    try {
      final animaService = context.read<AnimaService>();
      final deleted = await animaService.deleteMemory(memory.id);

      if (!mounted) return;
      if (!deleted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No se pudo borrar la memoria')));
        return;
      }

      setState(() {
        _memories = _memories.where((item) => item.id != memory.id).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memoria eliminada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error borrando memoria: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _buildAnimatedAppBarBackButton(),
        title: const Text('Memorias'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF09090B), Color(0xFF0F1021), Color(0xFF1B1842)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.045,
                child: Image.asset('assets/web.png', fit: BoxFit.cover),
              ),
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _memories.isEmpty
                    ? const Center(child: Text('No hay memorias guardadas'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _memories.length,
                        itemBuilder: (context, index) {
                          final memory = _memories[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: Colors.white.withAlpha(9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.white.withAlpha(16)),
                            ),
                            child: ListTile(
                              title: Text(
                                memory.content,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(memory.createdAt),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteMemory(memory),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
