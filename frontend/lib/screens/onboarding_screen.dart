import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../services/anima_service.dart';
import '../services/translation_service.dart';
import '../widgets/starfield_overlay.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _seedController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isSubmitting = false;
  bool _languageSelectedByUser = false;
  String _selectedLanguage = 'EN';
  int _step = 0;
  String? _hoveredLanguage;
  double _wheelAngle = 0;

  static const List<_LanguageOption> _languageOptions = [
    _LanguageOption(
      backendValue: 'ES',
      nativeLabel: 'ES',
      flagImageUrl: 'https://flagcdn.com/w320/es.png',
    ),
    _LanguageOption(
      backendValue: 'EN',
      nativeLabel: 'EN',
      flagImageUrl: 'https://flagcdn.com/w320/us.png',
    ),
    _LanguageOption(
      backendValue: 'ZH',
      nativeLabel: 'ZH',
      flagImageUrl: 'https://flagcdn.com/w320/cn.png',
    ),
    _LanguageOption(
      backendValue: 'AR',
      nativeLabel: 'AR',
      flagImageUrl: 'https://flagcdn.com/w320/sa.png',
    ),
    _LanguageOption(
      backendValue: 'RU',
      nativeLabel: 'RU',
      flagImageUrl: 'https://flagcdn.com/w320/ru.png',
    ),
    _LanguageOption(
      backendValue: 'JP',
      nativeLabel: 'JP',
      flagImageUrl: 'https://flagcdn.com/w320/jp.png',
    ),
    _LanguageOption(
      backendValue: 'DE',
      nativeLabel: 'DE',
      flagImageUrl: 'https://flagcdn.com/w320/de.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = 'EN';
    _wheelAngle = _wheelAngleForLanguage('EN');
    context.read<TranslationService>().setLanguageLocal('EN');
    _loadInitialLanguage();
  }

  double _wheelAngleForLanguage(String languageCode) {
    final normalized = TranslationService.normalizeLanguageCode(languageCode);
    final selectedIndex = _languageOptions.indexWhere(
      (option) => option.backendValue == normalized,
    );

    if (selectedIndex < 0) {
      return 0;
    }

    final angleStep = (2 * math.pi) / _languageOptions.length;
    return -selectedIndex * angleStep;
  }

  Future<void> _loadInitialLanguage() async {
    String languageToUse = 'EN';

    try {
      if (!mounted) return;
      if (_languageSelectedByUser) return;
      final animaService = context.read<AnimaService>();
      final translationService = context.read<TranslationService>();

      final persistedLanguage = await _readPersistedLanguage();
      if (persistedLanguage != null && persistedLanguage.trim().isNotEmpty) {
        languageToUse = TranslationService.normalizeLanguageCode(persistedLanguage);
      } else {
        try {
          final remoteLanguage = await animaService.getAppLanguage();
          if (remoteLanguage.trim().isNotEmpty) {
            languageToUse = TranslationService.normalizeLanguageCode(remoteLanguage);
          }
        } catch (e) {
          debugPrint('[onboarding] Could not read backend language, fallback EN: $e');
        }
      }

      setState(() {
        _selectedLanguage = languageToUse;
        _wheelAngle = _wheelAngleForLanguage(languageToUse);
      });
      translationService.setLanguageLocal(languageToUse);
    } catch (e) {
      debugPrint('[onboarding] Failed to load initial language, fallback EN: $e');
      if (!mounted) return;
      final translationService = context.read<TranslationService>();
      translationService.setLanguageLocal('EN');
      setState(() {
        _selectedLanguage = 'EN';
        _wheelAngle = _wheelAngleForLanguage('EN');
      });
    }
  }

  Future<File> _onboardingStateFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}onboarding_state.json');
  }

  Future<String?> _readPersistedLanguage() async {
    try {
      final file = await _onboardingStateFile();
      if (!await file.exists()) return null;

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final language = decoded['selected_language'];
        if (language is String && language.trim().isNotEmpty) {
          return language;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[onboarding] Failed to read persisted onboarding state: $e');
      return null;
    }
  }

  Future<void> _persistOnboardingState({
    required bool completed,
    required String selectedLanguage,
  }) async {
    try {
      final file = await _onboardingStateFile();
      final payload = jsonEncode({
        'onboarding_completed': completed,
        'selected_language': TranslationService.normalizeLanguageCode(selectedLanguage),
      });
      await file.writeAsString(payload, flush: true);
    } catch (e) {
      debugPrint('[onboarding] Failed to persist onboarding state: $e');
    }
  }

  void _goToStep(int step) {
    if (!mounted) return;
    setState(() {
      _step = step;
    });

    if (step == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _nameFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _selectLanguageAndContinue(String language) async {
    if (_isSubmitting) return;

    setState(() {
      _languageSelectedByUser = true;
      _selectedLanguage = language;
    });

    final translationService = context.read<TranslationService>();
    await translationService.changeLanguage(language);

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    if (context.read<TranslationService>().language == language) {
      _goToStep(1);
    }
  }

  Future<void> _startJourney() async {
    final name = _nameController.text.trim();
    final seed = _seedController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'requiredNameStart'))),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final animaService = context.read<AnimaService>();
      final translationService = context.read<TranslationService>();

      var languageSaved = false;
      try {
        languageSaved = await translationService.changeLanguage(_selectedLanguage);
      } catch (e) {
        debugPrint('[onboarding] Failed to save selected language: $e');
      }

      if (!languageSaved) {
        const fallbackLanguage = 'EN';
        debugPrint('[onboarding] Language save failed, forcing fallback: $fallbackLanguage');
        translationService.setLanguageLocal(fallbackLanguage);
        try {
          await animaService.setAppLanguage(fallbackLanguage);
        } catch (e) {
          debugPrint('[onboarding] Fallback language save also failed: $e');
        }
      }

      if (!mounted) return;
      final nameSaved = await animaService.setUserName(name);

      if (!nameSaved) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'couldNotSaveName'))),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      if (seed.isNotEmpty) {
        await animaService.addProfileTrait('Identidad', seed);
      }

      await _persistOnboardingState(
        completed: true,
        selectedLanguage: translationService.language,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'onboardingError')}: $e')),
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
    _nameFocusNode.dispose();
    super.dispose();
  }

  Widget _buildLanguageStep() {
    const wheelSize = 340.0;
    const radius = 112.0;
    final angleStep = (2 * math.pi) / _languageOptions.length;

    return SizedBox(
      key: const ValueKey('language-step'),
      width: wheelSize,
      height: wheelSize,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _wheelAngle += details.delta.dx * 0.012;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var index = 0; index < _languageOptions.length; index++)
              Builder(builder: (_) {
                final option = _languageOptions[index];
                final angle = _wheelAngle + (index * angleStep) - (math.pi / 2);
                final offsetX = math.cos(angle) * radius;
                final offsetY = math.sin(angle) * radius;
            final selected = _selectedLanguage == option.backendValue;
            final hovered = _hoveredLanguage == option.backendValue;
                return Transform.translate(
                  offset: Offset(offsetX, offsetY),
                  child: MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _hoveredLanguage = option.backendValue;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _hoveredLanguage = null;
                      });
                    },
                    child: GestureDetector(
                      onTap: () => _selectLanguageAndContinue(option.backendValue),
                      child: AnimatedScale(
                        scale: hovered ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 190),
                        curve: Curves.easeOutCubic,
                        child: SizedBox(
                          width: 78,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 210),
                                curve: Curves.easeOutCubic,
                                width: 66,
                                height: 66,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF0F1020),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFFA78BFA)
                                        : Colors.white.withAlpha(58),
                                    width: selected ? 2.0 : 1.3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(50),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                    if (selected || hovered)
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6).withAlpha(52),
                                        blurRadius: 13,
                                        spreadRadius: 0,
                                      ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Padding(
                                  padding: const EdgeInsets.all(2.2),
                                  child: ClipOval(
                                    child: Image.network(
                                      option.flagImageUrl,
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.high,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.flag_outlined,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                option.nativeLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withAlpha(190),
                                  fontSize: 14,
                                  fontWeight:
                                      selected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return Column(
      key: const ValueKey('name-step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(context, 'nameQuestion'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          focusNode: _nameFocusNode,
          controller: _nameController,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (_nameController.text.trim().isNotEmpty) {
              _goToStep(2);
            }
          },
          decoration: InputDecoration(
            hintText: tr(context, 'nameInputHint'),
            hintStyle: TextStyle(color: Colors.white.withAlpha(140)),
            filled: true,
            fillColor: Colors.white.withAlpha(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withAlpha(25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withAlpha(25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: () => _goToStep(0),
              child: Text(tr(context, 'back')),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _nameController.text.trim().isEmpty
                  ? null
                  : () => _goToStep(2),
              child: Text(tr(context, 'continue')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContextStep() {
    return Column(
      key: const ValueKey('context-step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(context, 'optionalSeedQuestion'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _seedController,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: tr(context, 'optionalSeedHint'),
            hintStyle: TextStyle(color: Colors.white.withAlpha(140)),
            filled: true,
            fillColor: Colors.white.withAlpha(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withAlpha(25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withAlpha(25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: () => _goToStep(1),
              child: Text(tr(context, 'back')),
            ),
            const Spacer(),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF09090B),
              Color(0xFF0D0C18),
              Color(0xFF151234),
              Color(0xFF1E1B4B),
            ],
            stops: [0.05, 0.38, 0.74, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          backgroundBlendMode: BlendMode.srcOver,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.78, -0.86),
                      radius: 0.7,
                      colors: [
                        const Color(0xFF8B5CF6).withAlpha(50),
                        const Color(0xFF4F46E5).withAlpha(28),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.82, 0.92),
                      radius: 0.9,
                      colors: [
                        const Color(0xFF312E81).withAlpha(38),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: StarfieldOverlay(seed: 2026, starCount: 85),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(16),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.white.withAlpha(26)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(56),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 420),
                            child: _step == 0
                                ? _buildLanguageStep()
                                : _step == 1
                                    ? _buildNameStep()
                                    : _buildContextStep(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption {
  final String backendValue;
  final String nativeLabel;
  final String flagImageUrl;

  const _LanguageOption({
    required this.backendValue,
    required this.nativeLabel,
    required this.flagImageUrl,
  });
}
