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
      appBar: AppBar(title: const Text('Memorias')),
      body: _isLoading
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
    );
  }
}
