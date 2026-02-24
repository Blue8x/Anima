import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/anima_service.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _corePromptController = TextEditingController();
  bool _isLoading = true;
  bool _isSavingPrompt = false;
  bool _isExporting = false;
  bool _isFactoryResetting = false;

  @override
  void initState() {
    super.initState();
    _loadCorePrompt();
  }

  Future<void> _loadCorePrompt() async {
    try {
      final animaService = context.read<AnimaService>();
      final prompt = await animaService.getCorePrompt();
      if (!mounted) return;
      _corePromptController.text = prompt;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando Core Prompt: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCorePrompt() async {
    setState(() {
      _isSavingPrompt = true;
    });

    try {
      final animaService = context.read<AnimaService>();
      final saved = await animaService.setCorePrompt(_corePromptController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved ? 'Core Prompt guardado' : 'No se pudo guardar el Core Prompt'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando Core Prompt: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSavingPrompt = false;
      });
    }
  }

  Future<void> _exportBrain() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        if (!mounted) return;
        setState(() {
          _isExporting = false;
        });
        return;
      }

      final destinationPath = '$selectedDirectory${Platform.pathSeparator}anima_backup.db';
      final animaService = context.read<AnimaService>();
      final exported = await animaService.exportDatabase(destinationPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exported
                ? 'Backup exportado en: $destinationPath'
                : 'No se pudo exportar el backup',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exportando backup: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _runFactoryResetFlow() async {
    if (_isFactoryResetting) return;

    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Atención?'),
          content: const Text(
            'Estás a punto de borrar todos tus recuerdos, tu cerebro digital y tu identidad. Anima empezará de cero. ¿Quieres continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    if (firstConfirm != true || !mounted) return;

    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('⚠️ ÚLTIMA ADVERTENCIA'),
          content: const Text(
            'Esta acción es irreversible. ¿Estás absolutamente seguro de que quieres destruir a esta versión de Anima?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('¡BORRAR TODO!'),
            ),
          ],
        );
      },
    );

    if (secondConfirm != true || !mounted) return;

    setState(() {
      _isFactoryResetting = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Borrando memoria...')),
    );

    try {
      final animaService = context.read<AnimaService>();
      final resetOk = await animaService.factoryReset();
      if (!mounted) return;

      if (!resetOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo completar el formateo total')),
        );
        setState(() {
          _isFactoryResetting = false;
        });
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en formateo total: $e')),
      );
      setState(() {
        _isFactoryResetting = false;
      });
    }
  }

  @override
  void dispose() {
    _corePromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sala de Mandos y Legado')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Añadidos a la personalidad (Opcional)'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _corePromptController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            'Ej: Háblame de usted, o compórtate como un sargento...',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isSavingPrompt ? null : _saveCorePrompt,
                    child: _isSavingPrompt
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar Core Prompt'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportBrain,
                    icon: const Icon(Icons.download),
                    label: _isExporting
                        ? const Text('Exportando Cerebro...')
                        : const Text('Exportar Cerebro'),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _isFactoryResetting ? null : _runFactoryResetFlow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: _isFactoryResetting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Formatear Anima (Borrado Total)'),
                  ),
                ],
              ),
            ),
    );
  }
}
