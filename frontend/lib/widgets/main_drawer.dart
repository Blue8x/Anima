import 'package:flutter/material.dart';

import '../screens/brain_screen.dart';
import '../screens/home_screen.dart';
import '../screens/memory_browser_screen.dart';
import '../screens/settings_screen.dart';
import '../services/translation_service.dart';

enum MainDrawerSection {
  chat,
  memory,
  settings,
  brain,
}

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key, required this.currentSection});

  final MainDrawerSection currentSection;

  void _navigateTo(BuildContext context, MainDrawerSection section) {
    Navigator.of(context).pop();

    if (section == currentSection) {
      return;
    }

    final Widget destination;
    switch (section) {
      case MainDrawerSection.chat:
        destination = const HomeScreen();
        break;
      case MainDrawerSection.memory:
        destination = const MemoryBrowserScreen();
        break;
      case MainDrawerSection.settings:
        destination = const SettingsScreen();
        break;
      case MainDrawerSection.brain:
        destination = const BrainScreen();
        break;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF09090B), Color(0xFF111025), Color(0xFF1D1B45)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(border: Border()),
              child: Center(
                child: Image(
                  image: AssetImage('assets/anima_logo.png'),
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(tr(context, 'chat')),
              selected: currentSection == MainDrawerSection.chat,
              onTap: () => _navigateTo(context, MainDrawerSection.chat),
            ),
            ListTile(
              leading: const Icon(Icons.memory_outlined),
              title: Text(tr(context, 'memoryExplorer')),
              selected: currentSection == MainDrawerSection.memory,
              onTap: () => _navigateTo(context, MainDrawerSection.memory),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text(tr(context, 'commandCenter')),
              selected: currentSection == MainDrawerSection.settings,
              onTap: () => _navigateTo(context, MainDrawerSection.settings),
            ),
            ListTile(
              leading: const Icon(Icons.face_retouching_natural),
              title: Text(tr(context, 'digitalBrain')),
              selected: currentSection == MainDrawerSection.brain,
              onTap: () => _navigateTo(context, MainDrawerSection.brain),
            ),
          ],
        ),
      ),
    );
  }
}
