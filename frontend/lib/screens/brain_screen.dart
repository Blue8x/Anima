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
  Map<String, List<ProfileTrait>> _groupedTraits = {};
  bool _isLoading = true;
  bool _isProcessingSleep = false;
  bool _isResetHovered = false;

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
    _loadTraits();
  }

  Future<void> _loadTraits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final animaService = context.read<AnimaService>();
      final traits = await animaService.getProfileTraits();
      final grouped = <String, List<ProfileTrait>>{};

      for (final trait in traits) {
        grouped.putIfAbsent(trait.category, () => []);
        grouped[trait.category]!.add(trait);
      }

      if (!mounted) return;
      setState(() {
        _groupedTraits = grouped;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando cerebro digital: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Identidad':
        return Icons.badge_outlined;
      case 'Metas':
        return Icons.flag_outlined;
      case 'Gustos':
        return Icons.favorite_border;
      case 'Alimentación':
        return Icons.restaurant_outlined;
      case 'Preocupaciones':
        return Icons.psychology_alt_outlined;
      case 'Economía':
        return Icons.savings_outlined;
      case 'Relaciones':
        return Icons.people_outline;
      case 'Otros':
        return Icons.category_outlined;
      default:
        return Icons.bubble_chart_outlined;
    }
  }

  Future<void> _confirmFactoryReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Factory Reset Cognitivo'),
          content: const Text('¿Borrar evolución cognitiva?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Borrar'),
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
        setState(() {
          _groupedTraits = {};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evolución cognitiva borrada')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo borrar el perfil cognitivo')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error borrando perfil: $e')),
      );
    }
  }

  Future<void> _sleepAndShutdown() async {
    if (_isProcessingSleep) return;

    setState(() {
      _isProcessingSleep = true;
    });

    double progress = 0.0;
    String statusText = 'Iniciando ciclo de sueño...';
    StateSetter? dialogSetState;
    Timer? fakeProgressTimer;

    void refreshDialog() {
      if (dialogSetState == null) return;
      dialogSetState!(() {});
    }

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Sleep cycle progress',
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
        statusText = 'Analizando recuerdos crudos...';
      } else if (progress < 0.6) {
        statusText = 'Extrayendo rasgos de personalidad...';
      } else {
        statusText = 'Consolidando Cerebro Digital...';
      }

      refreshDialog();
    });

    try {
      final animaService = context.read<AnimaService>();
      await animaService.triggerSleepCycle();

      fakeProgressTimer.cancel();
      progress = 1.0;
      statusText = '¡Ciclo completado. Buenas noches!';
      refreshDialog();

      await Future.delayed(const Duration(seconds: 1));
      exit(0);
    } catch (e) {
      fakeProgressTimer.cancel();
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en ciclo de sueño: $e')),
      );
      setState(() {
        _isProcessingSleep = false;
      });
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
        title: const Text('Cerebro Digital'),
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
                : _groupedTraits.isEmpty
                    ? const Center(child: Text('No hay nodos cognitivos todavía'))
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: _groupedTraits.entries.map((entry) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withAlpha(16)),
                            ),
                            child: ExpansionTile(
                              leading: Icon(_iconForCategory(entry.key)),
                              title: Text(entry.key),
                              children: entry.value
                                  .map(
                                    (trait) => ListTile(
                                      title: Text(trait.content),
                                    ),
                                  )
                                  .toList(),
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
        label: const Text('Dar las buenas noches (Procesar y Apagar)'),
      ),
      drawer: const MainDrawer(currentSection: MainDrawerSection.brain),
    );
  }
}
