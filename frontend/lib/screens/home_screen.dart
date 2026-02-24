// Main screen for Anima

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'brain_screen.dart';
import 'memory_browser_screen.dart';
import 'settings_screen.dart';
import '../services/anima_service.dart';
import '../services/translation_service.dart';
import '../src/rust/db.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _historyMessages = [];
  List<ChatMessage> _sessionMessages = [];
  bool _isHistoryExpanded = false;
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final animaService = context.read<AnimaService>();
      final history = await animaService.loadHistory();
      if (!mounted) return;
      setState(() {
        _historyMessages = history;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('${tr(context, 'failedLoadHistory')}: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final nowIso = DateTime.now().toUtc().toIso8601String();

    setState(() {
      _sessionMessages = [
        ..._sessionMessages,
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          role: 'user',
          content: content,
          timestamp: nowIso,
        ),
      ];
      isTyping = true;
    });
    _scrollToBottom();

    try {
      final animaService = context.read<AnimaService>();
      final response = await animaService.processMessage(content);

      if (!mounted) return;
      setState(() {
        _sessionMessages = [
          ..._sessionMessages,
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch + 1,
            role: 'assistant',
            content: response,
            timestamp: DateTime.now().toUtc().toIso8601String(),
          ),
        ];
        isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isTyping = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('${tr(context, 'failedProcessMessage')}: $e')),
      );
    }

    _scrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesToRender = _isHistoryExpanded
        ? [..._historyMessages, ..._sessionMessages]
        : _sessionMessages;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anima'),
            Text(
              tr(context, 'personalCompanion'),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text('Anima', style: TextStyle(fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(tr(context, 'chat')),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.memory_outlined),
              title: Text(tr(context, 'memoryExplorer')),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MemoryBrowserScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text(tr(context, 'commandCenter')),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.face_retouching_natural),
              title: Text(tr(context, 'digitalBrain')),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BrainScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                if (_historyMessages.isNotEmpty)
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isHistoryExpanded = !_isHistoryExpanded;
                        });
                      },
                      child: Text(
                        _isHistoryExpanded
                            ? tr(context, 'hidePreviousHistory')
                            : tr(context, 'showPreviousHistory'),
                      ),
                    ),
                  ),
                if (messagesToRender.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.psychology,
                              size: 64, color: Colors.deepPurple),
                          const SizedBox(height: 16),
                          const Text(
                            'Anima',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr(context, 'aiBiographerTagline'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            tr(context, 'welcomeIntro'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                for (final memory in messagesToRender)
                  ChatBubble(
                    message: memory.content,
                    isUser: memory.role == 'user',
                    timestamp: _parseTimestamp(memory.timestamp),
                  ),
                if (isTyping)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          MessageInput(onSend: _sendMessage, isLoading: isTyping),
        ],
      ),
    );
  }

  DateTime _parseTimestamp(String timestamp) {
    final parsed =
        DateTime.tryParse(timestamp) ?? DateTime.tryParse(timestamp.replaceFirst(' ', 'T'));
    return parsed ?? DateTime.now();
  }
}
