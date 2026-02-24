// Anima backend service

import 'package:logger/logger.dart';
import '../api.dart' as rust_api;
import '../src/rust/api/simple.dart' as rust_simple;

class AnimaService {
  final Logger _logger = Logger();

  AnimaService();

  Future<String> processMessage(String text) async {
    final stopwatch = Stopwatch()..start();
    _logger.i('processMessage start');
    _logger.d('processMessage payload length=${text.length}');
    try {
      final response = await rust_simple.sendMessage(message: text);
      stopwatch.stop();
      _logger.i('processMessage success in ${stopwatch.elapsedMilliseconds}ms');
      _logger.d('processMessage response length=${response.length}');
      return response;
    } catch (e, st) {
      stopwatch.stop();
      _logger.e(
        'processMessage failed after ${stopwatch.elapsedMilliseconds}ms',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Save a user message in the local database
  Future<String> saveUserMessage(String content) async {
    _logger.d('Saving user message: $content');
    return rust_api.saveUserMessage(content: content);
  }

  /// Get recent episodic memories
  Future<List<rust_api.EpisodicMemoryDto>> getRecentMemories({
    int limit = 50,
  }) async {
    _logger.d('Fetching recent memories: limit=$limit');
    return rust_api.getRecentMemories(limit: limit);
  }

  /// Get user identity
  Future<Map<String, dynamic>> getUserIdentity() async {
    _logger.d('Fetching user identity');
    return {};
  }

  /// Get semantic insights
  Future<List<Map<String, dynamic>>> getSemanticInsights({
    String? topic,
    int limit = 10,
  }) async {
    _logger.d('Fetching semantic insights: topic=$topic');
    return [];
  }

  /// Trigger manual sleep cycle
  Future<String> triggerSleepCycle() async {
    _logger.i('Triggering manual sleep cycle');
    return 'Sleep cycle initiated';
  }

  /// Get AI personality
  Future<Map<String, String>> getAiPersonality() async {
    _logger.d('Fetching AI personality');
    return {};
  }
}
