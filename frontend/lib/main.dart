import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/anima_service.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final animaService = AnimaService();
  await animaService.initialize();
  runApp(AnimaApp(animaService: animaService));
}

class AnimaApp extends StatelessWidget {
  final AnimaService animaService;

  const AnimaApp({super.key, required this.animaService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider<AnimaService>.value(value: animaService)],
      child: MaterialApp(
        title: 'Anima',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
