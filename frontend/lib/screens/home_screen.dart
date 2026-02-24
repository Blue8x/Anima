// Main screen for Anima

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart' as rust_api;
import '../services/anima_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<rust_api.EpisodicMemoryDto> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadRecentMemories();
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

  Future<void> _loadRecentMemories() async {
    try {
      final animaService = context.read<AnimaService>();
      final memories = await animaService.getRecentMemories(limit: 50);
      setState(() {
        _messages = memories.reversed.toList();
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load memories: $e')));
    }
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final animaService = context.read<AnimaService>();
      await animaService.saveUserMessage(content);
      await _loadRecentMemories();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
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
                    message: memory.content,
                    isUser: memory.role == 'user',
                    timestamp: DateTime.parse(memory.timestamp),
                  ),
              ],
            ),
          ),
          MessageInput(onSend: _sendMessage, isLoading: _isLoading),
        ],
      ),
    );
  }
}
