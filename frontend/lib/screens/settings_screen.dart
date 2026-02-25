import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../services/anima_service.dart';
import '../services/translation_service.dart';
import '../widgets/main_drawer.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _isExporting = false;
  bool _isFactoryResetting = false;

  String _userName = '';
  String _selectedLanguage = 'ES';
  double _temperature = 0.7;

  static const Map<String, String> _languageLabels = {
    'ES': 'Español',
    'EN': 'English',
    'CH': '中文',
    'AR': 'العربية',
    'RU': 'Русский',
    'JP': '日本語',
    'DE': 'Deutsch',
    'FR': 'Français',
    'HI': 'हिन्दी',
    'PT': 'Português',
    'BN': 'বাংলা',
    'UR': 'اردو',
    'ID': 'Bahasa Indonesia',
    'KO': '한국어',
    'VI': 'Tiếng Việt',
    'IT': 'Italiano',
    'TR': 'Türkçe',
    'TA': 'தமிழ்',
    'TH': 'ไทย',
    'PL': 'Polski',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final animaService = context.read<AnimaService>();
      final userName = await animaService.getUserName();
      final dbLanguage = await animaService.getAppLanguage();
      final normalizedLanguage = TranslationService.normalizeLanguageCode(dbLanguage);
      final temperature = await animaService.getTemperature();

      if (!mounted) return;
      setState(() {
        _userName = userName;
        _selectedLanguage = normalizedLanguage;
        _temperature = temperature;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando ajustes: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showEditNameDialog() async {
    final controller = TextEditingController(text: _userName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          title: const Text('Cambiar nombre'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Tu nombre',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newName == null) return;
    if (!mounted) return;

    try {
      final animaService = context.read<AnimaService>();
      final saved = await animaService.setUserName(newName);
      if (!mounted) return;

      if (!saved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No se pudo guardar el nombre')));
        return;
      }

      setState(() {
        _userName = newName;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nombre actualizado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error guardando nombre: $e')));
    }
  }

  Future<void> _updateLanguage(String code) async {
    final normalizedCode = TranslationService.normalizeLanguageCode(code);

    try {
      final animaService = context.read<AnimaService>();
      final saved = await animaService.setAppLanguage(normalizedCode);
      if (!mounted) return;

      if (!saved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No se pudo cambiar el idioma')));
        return;
      }

      context.read<TranslationService>().setLanguage(normalizedCode);
      setState(() {
        _selectedLanguage = normalizedCode;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Idioma actualizado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cambiando idioma: $e')));
    }
  }

  Future<void> _saveTemperature(double value) async {
    try {
      final animaService = context.read<AnimaService>();
      final saved = await animaService.setTemperature(value);
      if (!mounted) return;

      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la creatividad')),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Creatividad actualizada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error guardando creatividad: $e')));
    }
  }

  Future<void> _exportBrainToFile() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final animaService = context.read<AnimaService>();
      final exportPayload = await animaService.exportBrain();

      final docsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${docsDir.path}${Platform.pathSeparator}anima_brain_$timestamp.json';
      final file = File(filePath);
      await file.writeAsString(exportPayload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cerebro exportado en: $filePath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exportando cerebro: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _runFactoryResetFlow() async {
    if (_isFactoryResetting) return;

    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
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
          backgroundColor: const Color(0xFF18181B),
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Formateando Anima...')));

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error en formateo total: $e')));
      setState(() {
        _isFactoryResetting = false;
      });
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 14, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _settingCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      drawer: const MainDrawer(currentSection: MainDrawerSection.settings),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
        title: const Text('Ajustes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                _sectionTitle('IDENTIDAD'),
                _settingCard(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Cambiar nombre'),
                    subtitle: Text(
                      _userName.trim().isEmpty ? 'Sin definir' : _userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showEditNameDialog,
                  ),
                ),
                _settingCard(
                  child: ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: const Text('Cambiar idioma'),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        dropdownColor: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(12),
                        items: TranslationService.supportedLanguages
                            .map(
                              (code) => DropdownMenuItem<String>(
                                value: code,
                                child: Text(_languageLabels[code] ?? code),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          _updateLanguage(value);
                        },
                      ),
                    ),
                  ),
                ),
                _sectionTitle('COMPORTAMIENTO'),
                _settingCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology_outlined),
                            SizedBox(width: 10),
                            Text(
                              'Creatividad del modelo',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _temperature.toStringAsFixed(2),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                        Slider(
                          value: _temperature,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          label: _temperature.toStringAsFixed(2),
                          onChanged: (value) {
                            setState(() {
                              _temperature = value;
                            });
                          },
                          onChangeEnd: _saveTemperature,
                        ),
                      ],
                    ),
                  ),
                ),
                _sectionTitle('DATOS Y PRIVACIDAD'),
                _settingCard(
                  child: ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: const Text('Exportar mi Cerebro'),
                    subtitle: const Text('Guardar copia local en .json'),
                    trailing: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _isExporting ? null : _exportBrainToFile,
                  ),
                ),
                _settingCard(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    title: const Text(
                      'Formatear Anima (Botón de Pánico)',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    subtitle: const Text('Zona de peligro · borrado total irreversible'),
                    trailing: _isFactoryResetting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right, color: Colors.redAccent),
                    onTap: _isFactoryResetting ? null : _runFactoryResetFlow,
                  ),
                ),
              ],
            ),
    );
  }
}
