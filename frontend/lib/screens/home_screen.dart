// Main screen for Anima

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/anima_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool isTyping = false;

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

    setState(() {
      _messages.add(ChatMessage(text: content, isUser: true));
      isTyping = true;
    });
    _scrollToBottom();

    try {
      final animaService = context.read<AnimaService>();
      final response = await animaService.processMessage(content);

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
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
                if (_messages.isEmpty)
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
                for (final memory in _messages)
                  ChatBubble(
                    message: memory.text,
                    isUser: memory.isUser,
                    timestamp: memory.timestamp,
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
}
