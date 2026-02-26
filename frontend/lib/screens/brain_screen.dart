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
  List<ProfileTrait> _profileTraits = [];
  bool _isLoading = true;
  bool _isLoadingProfile = true;
  bool _isProcessingSleep = false;
  double _sleepProgress = 0.0;
  String _sleepStatusText = '';
  bool _isResetHovered = false;
  Timer? _searchDebounce;
  Timer? _sleepProgressTimer;
  final Map<String, bool> _expandedProfileSections = {};

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
    _loadProfileTraits();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _sleepProgressTimer?.cancel();
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

  Future<void> _loadProfileTraits() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final animaService = context.read<AnimaService>();
      final traits = await animaService.getProfileTraits();
      if (!mounted) return;
      setState(() {
        _profileTraits = traits;
        final categories = traits.map((trait) => trait.category).toSet().toList();
        for (final category in categories) {
          _expandedProfileSections.putIfAbsent(category, () => false);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'errorLoadingProfileSections')}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Map<String, List<ProfileTrait>> _groupTraitsByCategory() {
    final grouped = <String, List<ProfileTrait>>{};
    for (final trait in _profileTraits) {
      grouped.putIfAbsent(trait.category, () => []);
      grouped[trait.category]!.add(trait);
    }
    return grouped;
  }

  int _categoryPriority(String category) {
    final normalized = category.trim().toLowerCase();
    const priority = {
      'identidad': 0,
      'identity': 0,
      'personalidad': 1,
      'personality': 1,
      'hábitos': 2,
      'habitos': 2,
      'habits': 2,
      'objetivos': 3,
      'goals': 3,
      'relaciones': 4,
      'relationships': 4,
      'preferencias': 5,
      'preferences': 5,
      'salud': 6,
      'health': 6,
      'trabajo': 7,
      'work': 7,
      'aprendizaje': 8,
      'learning': 8,
      'sleep cycle': 9,
    };
    return priority[normalized] ?? 100;
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
    final animaService = context.read<AnimaService>();

    setState(() {
      _isProcessingSleep = true;
      _sleepProgress = 0.0;
      _sleepStatusText = translationService.tr('sleepLoadingToday');
    });

    _sleepProgressTimer?.cancel();
    _sleepProgressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted || !_isProcessingSleep) return;

      final nextProgress = (_sleepProgress + 0.08).clamp(0.0, 0.9);
      String nextStatus;

      if (nextProgress < 0.2) {
        nextStatus = translationService.tr('sleepLoadingToday');
      } else if (nextProgress < 0.4) {
        nextStatus = translationService.tr('sleepAnalyzing');
      } else if (nextProgress < 0.7) {
        nextStatus = translationService.tr('sleepExtracting');
      } else {
        nextStatus = translationService.tr('sleepConsolidating');
      }

      setState(() {
        _sleepProgress = nextProgress;
        _sleepStatusText = nextStatus;
      });
    });

    try {
      await Future.delayed(const Duration(milliseconds: 120));
      debugPrint('[sleep_ui_brain] calling triggerSleepCycle');
      await animaService.triggerSleepCycle();
      debugPrint('[sleep_ui_brain] triggerSleepCycle completed');

      _sleepProgressTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _sleepProgress = 1.0;
        _sleepStatusText = translationService.tr('sleepCompleted');
      });

      await Future.delayed(const Duration(seconds: 1));
      debugPrint('[sleep_ui_brain] exiting app (success)');
      exit(0);
    } catch (e) {
      debugPrint('[sleep_ui_brain] triggerSleepCycle failed error=$e');
      _sleepProgressTimer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr(context, 'errorSleepCycle')}: $e')),
        );
      }
    } finally {
      _sleepProgressTimer?.cancel();
      if (mounted) {
        setState(() {
          _isProcessingSleep = false;
          _sleepProgress = 0.0;
        });
      }
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
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  tr(context, 'digitalProfileSections'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (_isLoadingProfile)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...(() {
                  final grouped = _groupTraitsByCategory();
                  final sortedEntries = grouped.entries.toList()
                    ..sort((a, b) {
                      final priorityCompare =
                          _categoryPriority(a.key).compareTo(_categoryPriority(b.key));
                      if (priorityCompare != 0) return priorityCompare;
                      return a.key.toLowerCase().compareTo(b.key.toLowerCase());
                    });
                  if (grouped.isEmpty) {
                    return [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withAlpha(16)),
                        ),
                        child: Text(
                          tr(context, 'noProfileSectionsYet'),
                          style: TextStyle(color: Colors.white.withAlpha(200)),
                        ),
                      ),
                    ];
                  }

                  return sortedEntries.map((entry) {
                    final category = entry.key;
                    final traits = entry.value;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(16)),
                      ),
                      child: ExpansionTile(
                        key: PageStorageKey<String>('profile-$category'),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        initiallyExpanded: _expandedProfileSections[category] ?? false,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _expandedProfileSections[category] = expanded;
                          });
                        },
                        leading: const Icon(Icons.psychology_alt_outlined),
                        title: Text(
                          '$category (${traits.length})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        children: traits
                            .map(
                              (trait) => Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withAlpha(10)),
                                ),
                                child: Text(trait.content),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }).toList();
                })(),
                const SizedBox(height: 18),
                Text(
                  tr(context, 'pastMemorySearchSection'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (displayedMemories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(tr(context, 'noMemoriesForSearch')),
                  )
                else
                  ...displayedMemories.map((memory) {
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
                  }),
              ],
            ),
            if (_isProcessingSleep)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(178),
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(24)),
                      ),
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
                            _sleepStatusText,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _sleepProgress,
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
