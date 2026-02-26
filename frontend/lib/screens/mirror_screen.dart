import 'dart:async';
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
  bool _isProcessingSleep = false;

  Future<void> _processAndShutdown() async {
    if (_isProcessingSleep) return;
    debugPrint('[sleep_ui_mirror] start');

    setState(() {
      _isProcessingSleep = true;
    });

    double progress = 0.0;
    String statusText = 'Cargando los mensajes del día...';
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
                          color: Theme.of(context).colorScheme.primary.withAlpha(35),
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

      if (progress < 0.2) {
        statusText = 'Cargando los mensajes del día...';
      } else if (progress < 0.4) {
        statusText = 'Analizando recuerdos crudos...';
      } else if (progress < 0.7) {
        statusText = 'Extrayendo rasgos de personalidad...';
      } else {
        statusText = 'Consolidando Cerebro Digital...';
      }

      refreshDialog();
    });

    try {
      final animaService = context.read<AnimaService>();
      await Future.delayed(const Duration(milliseconds: 120));
      debugPrint('[sleep_ui_mirror] calling triggerSleepCycle');
      await animaService.triggerSleepCycle();
      debugPrint('[sleep_ui_mirror] triggerSleepCycle completed');

      fakeProgressTimer.cancel();
      progress = 1.0;
      statusText = '¡Ciclo completado. Buenas noches!';
      refreshDialog();

      await Future.delayed(const Duration(seconds: 1));
      debugPrint('[sleep_ui_mirror] exiting app (success)');
      exit(0);
    } catch (e) {
      debugPrint('[sleep_ui_mirror] triggerSleepCycle failed error=$e');
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en el ciclo de sueño: $e')),
      );
    } finally {
      fakeProgressTimer.cancel();
      setState(() {
        _isProcessingSleep = false;
      });
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
      ),
    );
  }
}
