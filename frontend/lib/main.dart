import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/anima_service.dart';
import 'services/translation_service.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final animaService = AnimaService();
  await animaService.initialize();
  final userName = await animaService.getUserName();
  final appLanguage = await animaService.getAppLanguage();
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
          create: (_) => TranslationService(initialLanguage: initialLanguage),
        ),
      ],
      child: MaterialApp(
        title: 'Anima - Tu Cerebro Digital',
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
        home: initialScreen,
      ),
    );
  }
}
