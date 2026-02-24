import 'package:flutter/material.dart';

class MirrorScreen extends StatelessWidget {
  const MirrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('El Espejo (Perfil)')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aquí se construirá tu biografía sintetizada en la Fase 5',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
