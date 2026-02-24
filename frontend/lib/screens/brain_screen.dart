import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/anima_service.dart';
import '../src/rust/db.dart';

class BrainScreen extends StatefulWidget {
  const BrainScreen({super.key});

  @override
  State<BrainScreen> createState() => _BrainScreenState();
}

class _BrainScreenState extends State<BrainScreen> {
  Map<String, List<ProfileTrait>> _groupedTraits = {};
  bool _isLoading = true;
  bool _isProcessingSleep = false;

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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anima está durmiendo...')),
    );

    try {
      final animaService = context.read<AnimaService>();
      await animaService.triggerSleepCycle();
      exit(0);
    } catch (e) {
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
        title: const Text('Cerebro Digital'),
        actions: [
          IconButton(
            onPressed: _confirmFactoryReset,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Factory Reset Cognitivo',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedTraits.isEmpty
              ? const Center(child: Text('No hay nodos cognitivos todavía'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: _groupedTraits.entries.map((entry) {
                    return ExpansionTile(
                      leading: Icon(_iconForCategory(entry.key)),
                      title: Text(entry.key),
                      children: entry.value
                          .map(
                            (trait) => ListTile(
                              title: Text(trait.content),
                            ),
                          )
                          .toList(),
                    );
                  }).toList(),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sleepAndShutdown,
        icon: const Icon(Icons.bedtime),
        label: const Text('Dar las buenas noches (Procesar y Apagar)'),
      ),
    );
  }
}
