import 'package:flutter/material.dart';

class MirrorScreen extends StatelessWidget {
  const MirrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('El Espejo (Perfil)')),
      body: Center(
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
