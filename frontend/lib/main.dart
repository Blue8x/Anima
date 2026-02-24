// The original content is temporarily commented out to allow generating a self-contained demo - feel free to uncomment later.

// // The original content is temporarily commented out to allow generating a self-contained demo - feel free to uncomment later.
//
// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'frb_generated.dart';
// // import 'services/anima_service.dart';
// // import 'screens/home_screen.dart';
// //
// // Future<void> main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await RustLib.init();
// //   runApp(const AnimaApp());
// // }
// //
// // class AnimaApp extends StatelessWidget {
// //   const AnimaApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MultiProvider(
// //       providers: [Provider<AnimaService>(create: (_) => AnimaService())],
// //       child: MaterialApp(
// //         title: 'Anima',
// //         theme: ThemeData(
// //           colorScheme: ColorScheme.fromSeed(
// //             seedColor: Colors.deepPurple,
// //             brightness: Brightness.dark,
// //           ),
// //           useMaterial3: true,
// //         ),
// //         home: const HomeScreen(),
// //       ),
// //     );
// //   }
// // }
// //
//
// import 'package:flutter/material.dart';
// import 'package:anima/src/rust/api/simple.dart';
// import 'package:anima/src/rust/frb_generated.dart';
//
// Future<void> main() async {
//   await RustLib.init();
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
//         body: Center(
//           child: Text(
//               'Action: Call Rust `greet("Tom")`\nResult: `${greet(name: "Tom")}`'),
//         ),
//       ),
//     );
//   }
// }
//

import 'package:flutter/material.dart';
import 'package:anima/src/rust/api/simple.dart';
import 'package:anima/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Center(
          child: Text(
              'Action: Call Rust `greet("Tom")`\nResult: `${greet(name: "Tom")}`'),
        ),
      ),
    );
  }
}
