// Main screen for Anima

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/anima_service.dart';
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
      ).showSnackBar(SnackBar(content: Text('Failed to load history: $e')));
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
      ).showSnackBar(SnackBar(content: Text('Failed to process message: $e')));
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anima'),
            Text('Your personal AI companion', style: TextStyle(fontSize: 12)),
          ],
        ),
        centerTitle: true,
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
                            ? 'Ocultar historial anterior'
                            : 'Desplegar historial anterior',
                      ),
                    ),
                  ),
                if (messagesToRender.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.psychology,
                              size: 64, color: Colors.deepPurple),
                          SizedBox(height: 16),
                          Text(
                            'Anima',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your AI biographer, journal, and mentor',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          SizedBox(height: 32),
                          Text(
                            'Hello! I am Anima. I am here to listen, remember '
                            'what matters, and support your journey. '
                            'Share your day or whatever is on your mind.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
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
