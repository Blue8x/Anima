import 'dart:async';
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
    'EN': 'English',
    'ES': 'Español',
    'DE': 'Deutsch',
    'RU': 'Русский',
    'JP': '日本語',
    'ZH': '中文',
    'AR': 'العربية',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final animaService = context.read<AnimaService>();
      final userName = await animaService.getUserName().timeout(
        const Duration(seconds: 2),
        onTimeout: () => '',
      );
      final dbLanguage = await animaService.getAppLanguage().timeout(
        const Duration(seconds: 2),
        onTimeout: () => 'ES',
      );
      final normalizedLanguage = TranslationService.normalizeLanguageCode(dbLanguage);
      final temperature = await animaService.getTemperature().timeout(
        const Duration(seconds: 2),
        onTimeout: () => 0.7,
      );

      if (!mounted) return;
      context.read<TranslationService>().setLanguageLocal(normalizedLanguage);
      setState(() {
        _userName = userName;
        _selectedLanguage = normalizedLanguage;
        _temperature = temperature;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${tr(context, 'errorLoadingSettings')}: $e')));
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
          title: Text(tr(context, 'changeName')),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: tr(context, 'yourName'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr(context, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: Text(tr(context, 'save')),
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
        ).showSnackBar(SnackBar(content: Text(tr(context, 'nameSaveFailed'))));
        return;
      }

      setState(() {
        _userName = newName;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr(context, 'nameUpdated'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${tr(context, 'errorSavingName')}: $e')));
    }
  }

  Future<void> _updateLanguage(String code) async {
    final normalizedCode = TranslationService.normalizeLanguageCode(code);

    try {
      final saved = await context.read<TranslationService>().changeLanguage(normalizedCode);
      if (!mounted) return;

      if (!saved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr(context, 'languageChangeFailed'))));
        return;
      }

      setState(() {
        _selectedLanguage = normalizedCode;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr(context, 'languageUpdated'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${tr(context, 'languageChangeFailed')}: $e')));
    }
  }

  Future<void> _saveTemperature(double value) async {
    try {
      final animaService = context.read<AnimaService>();
      final saved = await animaService.setTemperature(value);
      if (!mounted) return;

      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'creativitySaveFailed'))),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr(context, 'creativityUpdated'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${tr(context, 'errorSavingCreativity')}: $e')));
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
        SnackBar(content: Text('${tr(context, 'brainExportedAt')}: $filePath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'errorExportingBrain')}: $e')),
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
          title: Text(tr(context, 'warningTitle')),
          content: Text(tr(context, 'factoryResetFirstConfirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(tr(context, 'cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(tr(context, 'continue')),
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
          title: Text(tr(context, 'finalWarningTitle')),
          content: Text(tr(context, 'factoryResetSecondConfirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(tr(context, 'cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(tr(context, 'deleteAll')),
            ),
          ],
        );
      },
    );

    if (secondConfirm != true || !mounted) return;

    setState(() {
      _isFactoryResetting = true;
    });

    var flowFinished = false;
    final hardStopTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || flowFinished) return;
      debugPrint('[factory_reset_ui] watchdog forced spinner off');
      setState(() {
        _isFactoryResetting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'factoryResetError'))),
      );
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(tr(context, 'formattingAnima'))));

    try {
      debugPrint('[factory_reset_ui] request start');
      final animaService = context.read<AnimaService>();
      final resetOk = await animaService.factoryReset().timeout(
        const Duration(seconds: 4),
      );
      debugPrint('[factory_reset_ui] request completed result=$resetOk');
      if (!mounted) return;

      if (!resetOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'factoryResetFailed'))),
        );
        return;
      }

      setState(() {
        _userName = '';
        _temperature = 0.7;
        _selectedLanguage = 'ES';
      });

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('[factory_reset_ui] request failed error=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${tr(context, 'factoryResetError')}: $e')));
    } finally {
      flowFinished = true;
      hardStopTimer.cancel();
      debugPrint('[factory_reset_ui] finally set loading false mounted=$mounted');
      if (mounted) {
        setState(() {
          _isFactoryResetting = false;
        });
      }
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
        title: Text(tr(context, 'settingsTitle')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                _sectionTitle(tr(context, 'identitySection')),
                _settingCard(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(tr(context, 'changeName')),
                    subtitle: Text(
                      _userName.trim().isEmpty ? tr(context, 'undefined') : _userName,
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
                    title: Text(tr(context, 'changeLanguage')),
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
                _sectionTitle(tr(context, 'behaviorSection')),
                _settingCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology_outlined),
                            const SizedBox(width: 10),
                            Text(
                              tr(context, 'modelCreativity'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
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
                _sectionTitle(tr(context, 'dataPrivacySection')),
                _settingCard(
                  child: ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: Text(tr(context, 'exportBrain')),
                    subtitle: Text(tr(context, 'saveLocalJson')),
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
                    title: Text(
                      tr(context, 'panicReset'),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    subtitle: Text(tr(context, 'dangerZoneIrreversible')),
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
