// Main screen for Anima

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/anima_service.dart';
import '../services/translation_service.dart';
import '../src/rust/db.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/main_drawer.dart';
import '../widgets/message_input.dart';
import '../widgets/starfield_overlay.dart';

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
  bool _hasRequestedProactiveGreeting = false;
  bool _isOpenDrawerHovered = false;

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

      if (history.isEmpty) {
        await _generateProactiveGreetingIfNeeded();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('${tr(context, 'failedLoadHistory')}: $e')),
      );
    }
  }

  Future<void> _generateProactiveGreetingIfNeeded() async {
    if (_hasRequestedProactiveGreeting) return;
    if (_historyMessages.isNotEmpty || _sessionMessages.isNotEmpty) return;

    _hasRequestedProactiveGreeting = true;

    final hour = DateTime.now().hour;
    final String timeOfDay = hour < 12 ? 'mañana' : hour < 20 ? 'tarde' : 'noche';

    if (!mounted) return;
    setState(() {
      isTyping = true;
    });
    _scrollToBottom();

    try {
      final animaService = context.read<AnimaService>();
      final greeting = await animaService.generateProactiveGreeting(timeOfDay);

      if (!mounted) return;
      setState(() {
        _sessionMessages = [
          ..._sessionMessages,
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch + 1,
            role: 'assistant',
            content: greeting,
            timestamp: DateTime.now().toUtc().toIso8601String(),
          ),
        ];
        isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isTyping = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate greeting: $e')),
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

    final userMessageId = DateTime.now().millisecondsSinceEpoch;
    final assistantMessageId = userMessageId + 1;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    setState(() {
      _sessionMessages = [
        ..._sessionMessages,
        ChatMessage(
          id: userMessageId,
          role: 'user',
          content: content,
          timestamp: nowIso,
        ),
        ChatMessage(
          id: assistantMessageId,
          role: 'assistant',
          content: '',
          timestamp: DateTime.now().toUtc().toIso8601String(),
        ),
      ];
      isTyping = true;
    });
    _scrollToBottom();

    try {
      final animaService = context.read<AnimaService>();
      await for (final chunk in animaService.streamMessage(content)) {
        if (!mounted) return;
        setState(() {
          _sessionMessages = _sessionMessages
              .map(
                (message) => message.id == assistantMessageId
                    ? ChatMessage(
                        id: message.id,
                        role: message.role,
                        content: '${message.content}$chunk',
                        timestamp: message.timestamp,
                      )
                    : message,
              )
              .toList();
        });
        _scrollToBottom();
      }

      final finalAssistantMessage = _sessionMessages
          .where((message) => message.id == assistantMessageId)
          .map((message) => message.content)
          .join();

      if (finalAssistantMessage.trim().isNotEmpty) {
        await animaService.saveAssistantMessage(finalAssistantMessage);
      }

      if (!mounted) return;
      setState(() {
        isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sessionMessages = _sessionMessages
            .map(
              (message) => message.id == assistantMessageId
                  ? ChatMessage(
                      id: message.id,
                      role: message.role,
                      content: message.content.isEmpty
                          ? 'Error: $e'
                          : message.content,
                      timestamp: message.timestamp,
                    )
                  : message,
            )
            .toList();
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
        leading: Builder(
          builder: (context) {
            return MouseRegion(
              onEnter: (_) {
                setState(() {
                  _isOpenDrawerHovered = true;
                });
              },
              onExit: (_) {
                setState(() {
                  _isOpenDrawerHovered = false;
                });
              },
              child: AnimatedScale(
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOutCubic,
                scale: _isOpenDrawerHovered ? 1.06 : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: _isOpenDrawerHovered
                        ? Colors.white.withAlpha(12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isOpenDrawerHovered
                          ? Colors.white.withAlpha(24)
                          : Colors.transparent,
                    ),
                  ),
                  child: IconButton(
                    tooltip: tr(context, 'openMenu'),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu),
                  ),
                ),
              ),
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 9),
            const Text(
              'Anima',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
          ],
        ),
        centerTitle: true,
      ),
      drawer: const MainDrawer(currentSection: MainDrawerSection.chat),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          children: [
            const Positioned.fill(
              child: StarfieldOverlay(seed: 1337, starCount: 150),
            ),
            Column(
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(18)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(30),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/logo.png',
                              height: 180,
                              width: 180,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Anima',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr(context, 'aiBiographerTagline'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
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
          ],
        ),
      ),
    );
  }

  DateTime _parseTimestamp(String timestamp) {
    final parsed =
        DateTime.tryParse(timestamp) ?? DateTime.tryParse(timestamp.replaceFirst(' ', 'T'));
    return parsed ?? DateTime.now();
  }
}
