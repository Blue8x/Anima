import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/anima_service.dart';
import 'services/translation_service.dart';
import 'src/rust/frb_generated.dart';
import 'widgets/custom_title_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(980, 680),
      center: true,
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: Color(0xFF09090B),
    );

    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const _BootstrapApp());
}

class _BootstrapResult {
  final AnimaService animaService;
  final Widget initialScreen;
  final String initialLanguage;

  const _BootstrapResult({
    required this.animaService,
    required this.initialScreen,
    required this.initialLanguage,
  });
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late final Future<_BootstrapResult> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<_BootstrapResult> _bootstrap() async {
    await RustLib.init();
    final animaService = AnimaService();
    await animaService.initialize();
    final userName = await animaService.getUserName();
    final appLanguage = TranslationService.normalizeLanguageCode(
      await animaService.getAppLanguage(),
    );
    final initialScreen = userName.trim().isEmpty
        ? const OnboardingScreen()
        : const HomeScreen();

    return _BootstrapResult(
      animaService: animaService,
      initialScreen: initialScreen,
      initialLanguage: appLanguage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapResult>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupLoadingApp();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _StartupErrorApp(
            message: snapshot.error?.toString() ?? 'Initialization failed',
          );
        }

        final result = snapshot.data!;
        return AnimaApp(
          animaService: result.animaService,
          initialScreen: result.initialScreen,
          initialLanguage: result.initialLanguage,
        );
      },
    );
  }
}

class _StartupLoadingApp extends StatelessWidget {
  const _StartupLoadingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF09090B),
      ),
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!Platform.isWindows) return content;
        return Column(
          children: [
            const CustomTitleBar(),
            Expanded(child: content),
          ],
        );
      },
      home: const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedStartupLogo(),
              SizedBox(height: 16),
              Text(
                'Loading Anima...',
                style: TextStyle(color: Color(0xFFE4E4E7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedStartupLogo extends StatefulWidget {
  const _AnimatedStartupLogo();

  @override
  State<_AnimatedStartupLogo> createState() => _AnimatedStartupLogoState();
}

class _AnimatedStartupLogoState extends State<_AnimatedStartupLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = 0.96 + (t * 0.08);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: 0.82 + (t * 0.18),
            child: child,
          ),
        );
      },
      child: Image.asset(
        'assets/anima_logo.png',
        width: 108,
        height: 108,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  final String message;

  const _StartupErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF09090B),
      ),
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!Platform.isWindows) return content;
        return Column(
          children: [
            const CustomTitleBar(),
            Expanded(child: content),
          ],
        );
      },
      home: Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to initialize Anima:\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFE4E4E7)),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimaApp extends StatelessWidget {
  final AnimaService animaService;
  final Widget initialScreen;
  final String initialLanguage;

  const AnimaApp({
    super.key,
    required this.animaService,
    required this.initialScreen,
    required this.initialLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AnimaService>.value(value: animaService),
        ChangeNotifierProvider<TranslationService>(
          create: (_) => TranslationService(
            animaService: animaService,
            initialLanguage: initialLanguage,
          ),
        ),
      ],
      child: Consumer<TranslationService>(
        builder: (context, translationService, _) {
          return MaterialApp(
            title: translationService.tr('appTitle'),
            locale: translationService.locale,
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.dark,
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF09090B),
              canvasColor: const Color(0xFF18181B),
              cardColor: const Color(0xFF18181B),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF8B5CF6),
                secondary: Color(0xFF8B5CF6),
                surface: Color(0xFF18181B),
                onPrimary: Color(0xFFF4F4F5),
                onSurface: Color(0xFFE4E4E7),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF09090B),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
              ),
              useMaterial3: true,
            ),
            builder: (context, child) {
              final content = child ?? const SizedBox.shrink();
              if (!Platform.isWindows) return content;

              return Column(
                children: [
                  const CustomTitleBar(),
                  Expanded(child: content),
                ],
              );
            },
            home: initialScreen,
          );
        },
      ),
    );
  }
}
