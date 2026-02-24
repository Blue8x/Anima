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
          create: (_) =>
              TranslationService(initialLanguage: initialLanguage),
        ),
      ],
      child: MaterialApp(
        title: 'Anima',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: initialScreen,
      ),
    );
  }
}
