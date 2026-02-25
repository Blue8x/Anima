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
  runApp(
    AnimaApp(
      animaService: animaService,
      initialScreen: initialScreen,
      initialLanguage: appLanguage,
    ),
  );
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
