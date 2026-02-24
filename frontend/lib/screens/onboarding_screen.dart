import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/anima_service.dart';
import '../services/translation_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _seedController = TextEditingController();
  bool _isSubmitting = false;
  String _selectedLanguage = 'Español';

  @override
  void initState() {
    super.initState();
    _loadInitialLanguage();
  }

  Future<void> _loadInitialLanguage() async {
    try {
      final animaService = context.read<AnimaService>();
      final savedLanguage = await animaService.getAppLanguage();
      final language = TranslationService.supportedLanguages.contains(savedLanguage)
          ? savedLanguage
          : 'Español';

      if (!mounted) return;
      setState(() {
        _selectedLanguage = language;
      });
      context.read<TranslationService>().setLanguage(language);
    } catch (_) {
      if (!mounted) return;
      context.read<TranslationService>().setLanguage(_selectedLanguage);
    }
  }

  Future<void> _startJourney() async {
    final name = _nameController.text.trim();
    final seed = _seedController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu nombre es obligatorio para empezar.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final animaService = context.read<AnimaService>();
      await animaService.setAppLanguage(_selectedLanguage);
      final nameSaved = await animaService.setUserName(name);

      if (!nameSaved) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar tu nombre.')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      if (seed.isNotEmpty) {
        await animaService.addProfileTrait('Identidad', seed);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error durante onboarding: $e')),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr(context, 'onboardingTitle'),
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(context, 'onboardingDescription'),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: InputDecoration(
                        labelText: tr(context, 'languageLabel'),
                        border: const OutlineInputBorder(),
                      ),
                      items: TranslationService.supportedLanguages
                          .map(
                            (lang) => DropdownMenuItem<String>(
                              value: lang,
                              child: Text(lang),
                            ),
                          )
                          .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedLanguage = value;
                              });
                              context.read<TranslationService>().setLanguage(value);
                            },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: tr(context, 'nameQuestion'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _seedController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: tr(context, 'optionalSeedQuestion'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _startJourney,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(tr(context, 'startJourney')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
