import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/anima_service.dart';
import '../services/translation_service.dart';
import '../src/rust/db.dart';
import '../widgets/main_drawer.dart';

class BrainScreen extends StatefulWidget {
  const BrainScreen({super.key});

  @override
  State<BrainScreen> createState() => _BrainScreenState();
}

class _BrainScreenState extends State<BrainScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MemoryItem> displayedMemories = [];
  bool _isLoading = true;
  bool _isProcessingSleep = false;
  bool _isResetHovered = false;
  Timer? _searchDebounce;

  Widget _buildAnimatedAppBarIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool hovered,
    required ValueChanged<bool> onHoverChanged,
  }) {
    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        scale: hovered ? 1.06 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: hovered ? Colors.white.withAlpha(12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hovered ? Colors.white.withAlpha(24) : Colors.transparent,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            tooltip: tooltip,
            icon: Icon(icon, size: 18),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _runMemorySearch('');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runMemorySearch(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final animaService = context.read<AnimaService>();
      final memories = await animaService.searchMemories(query);
      if (!mounted) return;
      setState(() {
        displayedMemories = memories;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'errorSearchingMemories')}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _runMemorySearch(value);
    });
  }

  Future<void> _confirmFactoryReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr(context, 'factoryResetCognitive')),
          content: Text(tr(context, 'confirmDeleteCognitive')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(tr(context, 'cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(tr(context, 'delete')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      final animaService = context.read<AnimaService>();
      final cleared = await animaService.clearProfile();
      if (!mounted) return;

      if (cleared) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'cognitiveDeleted'))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'cognitiveDeleteFailed'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'errorDeletingProfile')}: $e')),
      );
    }
  }

  Future<void> _sleepAndShutdown() async {
    if (_isProcessingSleep) return;
    debugPrint('[sleep_ui_brain] start');

    final translationService = context.read<TranslationService>();

    setState(() {
      _isProcessingSleep = true;
    });

    double progress = 0.0;
    String statusText = translationService.tr('sleepStart');
    StateSetter? dialogSetState;
    Timer? fakeProgressTimer;

    void refreshDialog() {
      if (dialogSetState == null) return;
      dialogSetState!(() {});
    }

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: tr(context, 'sleepProgressLabel'),
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            dialogSetState = setStateDialog;
            return Center(
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(35),
                        ),
                        child: Icon(
                          Icons.nightlight_round,
                          size: 34,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    fakeProgressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      progress = (progress + 0.08).clamp(0.0, 0.9);

      if (progress < 0.3) {
        statusText = translationService.tr('sleepAnalyzing');
      } else if (progress < 0.6) {
        statusText = translationService.tr('sleepExtracting');
      } else {
        statusText = translationService.tr('sleepConsolidating');
      }

      refreshDialog();
    });

    try {
      final animaService = context.read<AnimaService>();
      debugPrint('[sleep_ui_brain] calling triggerSleepCycle');
      await animaService.triggerSleepCycle();
      debugPrint('[sleep_ui_brain] triggerSleepCycle completed');

      fakeProgressTimer.cancel();
      progress = 1.0;
      statusText = translationService.tr('sleepCompleted');
      refreshDialog();

      await Future.delayed(const Duration(seconds: 1));
      debugPrint('[sleep_ui_brain] exiting app (success)');
      exit(0);
    } catch (e) {
      debugPrint('[sleep_ui_brain] triggerSleepCycle failed error=$e');
      fakeProgressTimer.cancel();
      // Even if memory consolidation failed, show error briefly then close.
      progress = 1.0;
      statusText = '⚠️ ${e.toString().split(":").first}';
      refreshDialog();
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('[sleep_ui_brain] exiting app (error fallback)');
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: Text(tr(context, 'brainTitle')),
        actions: [
          _buildAnimatedAppBarIconButton(
            icon: Icons.delete_outline,
            tooltip: tr(context, 'factoryResetCognitive'),
            onPressed: _confirmFactoryReset,
            hovered: _isResetHovered,
            onHoverChanged: (value) {
              setState(() {
                _isResetHovered = value;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withAlpha(18)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: tr(context, 'searchMemoriesHint'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _runMemorySearch('');
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ),
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
                : displayedMemories.isEmpty
                  ? Center(child: Text(tr(context, 'noMemoriesForSearch')))
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: displayedMemories.map((memory) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withAlpha(16)),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.auto_awesome),
                              title: Text(memory.content),
                              subtitle: Text(memory.createdAt),
                            ),
                          );
                        }).toList(),
                      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sleepAndShutdown,
        icon: const Icon(Icons.bedtime),
        label: Text(tr(context, 'goodNightAction')),
      ),
      drawer: const MainDrawer(currentSection: MainDrawerSection.brain),
    );
  }
}
