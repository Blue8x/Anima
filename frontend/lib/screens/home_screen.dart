// Main screen for Anima

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
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
  static bool _isAppInitialized = false;
  static List<ChatMessage> _cachedHistoryMessages = [];
  static List<ChatMessage> _cachedSessionMessages = [];
  static bool _cachedHistoryExpanded = false;
  static bool _cachedHasRequestedProactiveGreeting = false;

  final ScrollController _scrollController = ScrollController();
  StreamSubscription<void>? _factoryResetSubscription;
  List<ChatMessage> _historyMessages = [];
  List<ChatMessage> _sessionMessages = [];
  bool _isHistoryExpanded = false;
  bool _isInitializing = true;
  bool isTyping = false;
  bool _hasRequestedProactiveGreeting = false;
  bool _isOpenDrawerHovered = false;

  @override
  void initState() {
    super.initState();
    _factoryResetSubscription = context.read<AnimaService>().onFactoryReset.listen((_) {
      if (!mounted) return;
      setState(() {
        _historyMessages = [];
        _sessionMessages = [];
        _isHistoryExpanded = false;
        isTyping = false;
        _hasRequestedProactiveGreeting = false;
        _isInitializing = false;
      });

      _isAppInitialized = false;
      _cachedHistoryMessages = [];
      _cachedSessionMessages = [];
      _cachedHistoryExpanded = false;
      _cachedHasRequestedProactiveGreeting = false;
    });

    if (_isAppInitialized) {
      _historyMessages = List<ChatMessage>.from(_cachedHistoryMessages);
      _sessionMessages = List<ChatMessage>.from(_cachedSessionMessages);
      _isHistoryExpanded = _cachedHistoryExpanded;
      _hasRequestedProactiveGreeting = _cachedHasRequestedProactiveGreeting;
      _isInitializing = false;
      return;
    }

    _loadHistory();
  }

  void _cacheHomeState() {
    _cachedHistoryMessages = List<ChatMessage>.from(_historyMessages);
    _cachedSessionMessages = List<ChatMessage>.from(_sessionMessages);
    _cachedHistoryExpanded = _isHistoryExpanded;
    _cachedHasRequestedProactiveGreeting = _hasRequestedProactiveGreeting;
    _isAppInitialized = !_isInitializing;
  }

  Future<void> _loadHistory() async {
    try {
      final animaService = context.read<AnimaService>();
      final history = await animaService.loadHistory();
      if (!mounted) return;
      setState(() {
        _historyMessages = history
            .map(
              (message) => ChatMessage(
                id: message.id,
                role: message.role,
                content: _normalizeModelText(message.content),
                timestamp: message.timestamp,
              ),
            )
            .toList();
      });
          _cacheHomeState();

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
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _cacheHomeState();
      }
    }
  }

  Future<void> _generateProactiveGreetingIfNeeded() async {
    if (_hasRequestedProactiveGreeting) return;
    if (_historyMessages.isNotEmpty || _sessionMessages.isNotEmpty) return;

    _hasRequestedProactiveGreeting = true;
    _cacheHomeState();

    final hour = DateTime.now().hour;
    final String timeOfDay = hour < 6
      ? 'night'
      : hour < 12
        ? 'morning'
        : hour < 20
          ? 'afternoon'
          : 'evening';

    if (!mounted) return;
    setState(() {
      isTyping = true;
    });
    _scrollToBottom();

    try {
      final animaService = context.read<AnimaService>();
      final uiLanguage = context.read<TranslationService>().language;
      final greeting = await animaService.generateProactiveGreeting(
        timeOfDay,
        appLanguage: uiLanguage,
      );

      if (!mounted) return;
      setState(() {
        _sessionMessages = [
          ..._sessionMessages,
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch + 1,
            role: 'assistant',
            content: _normalizeModelText(greeting),
            timestamp: DateTime.now().toUtc().toIso8601String(),
          ),
        ];
        isTyping = false;
      });
      _cacheHomeState();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isTyping = false;
      });
      _cacheHomeState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'failedGenerateGreeting')}: $e')),
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
    _cacheHomeState();
    _scrollToBottom();

    try {
      final animaService = context.read<AnimaService>();
      final uiLanguage = context.read<TranslationService>().language;
      await for (final chunk in animaService.streamMessage(content, appLanguage: uiLanguage)) {
        if (!mounted) return;
        final normalizedChunk = _normalizeModelText(chunk);
        setState(() {
          _sessionMessages = _sessionMessages
              .map(
                (message) => message.id == assistantMessageId
                    ? ChatMessage(
                        id: message.id,
                        role: message.role,
                        content: '${message.content}$normalizedChunk',
                        timestamp: message.timestamp,
                      )
                    : message,
              )
              .toList();
        });
              _cacheHomeState();
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
      _cacheHomeState();
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
      _cacheHomeState();
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
    _factoryResetSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/anima_logo.png',
                width: 130,
                height: 130,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

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
              'assets/anima_logo.png',
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
              child: StarfieldOverlay(seed: 1337, starCount: 70),
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

  String _normalizeModelText(String text) {
    return text
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t');
  }
}
