import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/anima_service.dart';

class MirrorScreen extends StatefulWidget {
  const MirrorScreen({super.key});

  @override
  State<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends State<MirrorScreen> {
  Future<void> _processAndShutdown() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anima está reflexionando sobre hoy...')),
    );

    try {
      final animaService = context.read<AnimaService>();
      await animaService.triggerSleepCycle();
      exit(0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en el ciclo de sueño: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('El Espejo (Perfil)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Aquí se construirá tu biografía sintetizada en la Fase 5',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _processAndShutdown,
                icon: const Icon(Icons.bedtime),
                label: const Text('Dar las buenas noches (Procesar y Apagar)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                ),
              ),
            ],
        ),
      ),
    );
  }
}
