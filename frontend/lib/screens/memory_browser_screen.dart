import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/anima_service.dart';
import '../services/translation_service.dart';
import '../src/rust/db.dart';
import '../widgets/main_drawer.dart';

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
      ).showSnackBar(SnackBar(content: Text('${tr(context, 'errorLoadingMemories')}: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        ).showSnackBar(SnackBar(content: Text(tr(context, 'deleteMemoryFailed'))));
        return;
      }

      setState(() {
        _memories = _memories.where((item) => item.id != memory.id).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'memoryDeleted'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${tr(context, 'errorDeletingMemory')}: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(currentSection: MainDrawerSection.memory),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: tr(context, 'openMenu'),
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
            );
          },
        ),
        title: Text(tr(context, 'memoryTitle')),
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
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _memories.isEmpty
                  ? Center(child: Text(tr(context, 'noMemoriesSaved')))
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
                                tooltip: tr(context, 'deleteMemory'),
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
