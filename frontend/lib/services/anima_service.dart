// Anima backend service

import 'package:logger/logger.dart';
import '../api.dart' as rust_api;
import '../src/rust/db.dart';
import '../src/rust/api/simple.dart' as rust_simple;
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class AnimaService {
  final Logger _logger = Logger();
  bool _initialized = false;

  AnimaService();

  Future<void> initialize() async {
    if (_initialized) return;

    _logger.i('Initializing Rust AI models');
    await rust_simple.initApp(
      chatModelPath: 'models/anima_v1.gguf',
      embeddingModelPath: 'models/all-MiniLM-L6-v2.gguf',
    );
    _initialized = true;
    _logger.i('Rust AI models initialized');
  }

  Future<String> processMessage(String text) async {
    final stopwatch = Stopwatch()..start();
    _logger.i('processMessage start');
    _logger.d('processMessage payload length=${text.length}');
    try {
      final configuredTemperature = await getTemperature();
      final response = await rust_simple.sendMessage(
        message: text,
        temperature: configuredTemperature,
        maxTokens: 512,
      );
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

  Stream<String> streamMessage(String text) {
    _logger.i('streamMessage start');
    _logger.d('streamMessage payload length=${text.length}');
    return _streamMessageInternal(text);
  }

  Stream<String> _streamMessageInternal(String text) async* {
    final configuredTemperature = await getTemperature();
    yield* rust_simple.sendMessageStream(
      message: text,
      temperature: configuredTemperature,
      maxTokens: 512,
    );
  }

  Future<bool> saveAssistantMessage(String text) async {
    _logger.i('saveAssistantMessage start length=${text.length}');
    try {
      final saved = await rust_simple.saveAssistantMessage(message: text);
      _logger.i('saveAssistantMessage result=$saved');
      return saved;
    } catch (e, st) {
      _logger.e('saveAssistantMessage failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<String> generateProactiveGreeting(String timeOfDay) async {
    _logger.i('generateProactiveGreeting start timeOfDay=$timeOfDay');
    try {
      final greeting = await rust_simple.generateProactiveGreeting(
        timeOfDay: timeOfDay,
      );
      _logger.i('generateProactiveGreeting success length=${greeting.length}');
      return greeting;
    } catch (e, st) {
      _logger.e('generateProactiveGreeting failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<ChatMessage>> loadHistory() async {
    _logger.i('loadHistory start');
    try {
      final history = await rust_simple.getChatHistory();
      _logger.i('loadHistory success count=${history.length}');
      return history;
    } catch (e, st) {
      _logger.e('loadHistory failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<MemoryItem>> getAllMemories() async {
    _logger.i('getAllMemories start');
    try {
      final memories = await rust_simple.getAllMemories();
      _logger.i('getAllMemories success count=${memories.length}');
      return memories;
    } catch (e, st) {
      _logger.e('getAllMemories failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> deleteMemory(PlatformInt64 memoryId) async {
    _logger.i('deleteMemory start id=$memoryId');
    try {
      final deleted = await rust_simple.deleteMemory(id: memoryId);
      _logger.i('deleteMemory result id=$memoryId deleted=$deleted');
      return deleted;
    } catch (e, st) {
      _logger.e('deleteMemory failed id=$memoryId', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<String> getCorePrompt() async {
    _logger.i('getCorePrompt start');
    try {
      final prompt = await rust_simple.getCorePrompt();
      _logger.i('getCorePrompt success length=${prompt.length}');
      return prompt;
    } catch (e, st) {
      _logger.e('getCorePrompt failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> setCorePrompt(String prompt) async {
    _logger.i('setCorePrompt start length=${prompt.length}');
    try {
      final saved = await rust_simple.setCorePrompt(prompt: prompt);
      _logger.i('setCorePrompt result saved=$saved');
      return saved;
    } catch (e, st) {
      _logger.e('setCorePrompt failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> exportDatabase(String destinationPath) async {
    _logger.i('exportDatabase start path=$destinationPath');
    try {
      final exported = await rust_simple.exportDatabase(destPath: destinationPath);
      _logger.i('exportDatabase result exported=$exported');
      return exported;
    } catch (e, st) {
      _logger.e('exportDatabase failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> factoryReset() async {
    _logger.i('factoryReset start');
    try {
      final reset = await rust_simple.factoryReset();
      _logger.i('factoryReset result=$reset');
      return reset;
    } catch (e, st) {
      _logger.e('factoryReset failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<ProfileTrait>> getProfileTraits() async {
    _logger.i('getProfileTraits start');
    try {
      final traits = await rust_simple.getProfileTraits();
      _logger.i('getProfileTraits success count=${traits.length}');
      return traits;
    } catch (e, st) {
      _logger.e('getProfileTraits failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> clearProfile() async {
    _logger.i('clearProfile start');
    try {
      final cleared = await rust_simple.clearProfile();
      _logger.i('clearProfile result=$cleared');
      return cleared;
    } catch (e, st) {
      _logger.e('clearProfile failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<String> getUserName() async {
    _logger.i('getUserName start');
    try {
      final name = await rust_simple.getUserName();
      _logger.i('getUserName success length=${name.length}');
      return name;
    } catch (e, st) {
      _logger.e('getUserName failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> setUserName(String name) async {
    _logger.i('setUserName start length=${name.length}');
    try {
      final saved = await rust_simple.setUserName(name: name);
      _logger.i('setUserName result=$saved');
      return saved;
    } catch (e, st) {
      _logger.e('setUserName failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<String> getAppLanguage() async {
    _logger.i('getAppLanguage start');
    try {
      final lang = await rust_simple.getAppLanguage();
      _logger.i('getAppLanguage success value=$lang');
      return lang;
    } catch (e, st) {
      _logger.e('getAppLanguage failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> setAppLanguage(String lang) async {
    _logger.i('setAppLanguage start value=$lang');
    try {
      final saved = await rust_simple.setAppLanguage(lang: lang);
      _logger.i('setAppLanguage result=$saved');
      return saved;
    } catch (e, st) {
      _logger.e('setAppLanguage failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<double> getTemperature() async {
    _logger.i('getTemperature start');
    try {
      final temperature = await rust_simple.getTemperature();
      _logger.i('getTemperature success value=$temperature');
      return temperature;
    } catch (e, st) {
      _logger.e('getTemperature failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> setTemperature(double temperature) async {
    _logger.i('setTemperature start value=$temperature');
    try {
      final saved = await rust_simple.setTemperature(temperature: temperature);
      _logger.i('setTemperature result=$saved');
      return saved;
    } catch (e, st) {
      _logger.e('setTemperature failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<String> exportBrain() async {
    _logger.i('exportBrain start');
    try {
      final payload = await rust_simple.exportBrain();
      _logger.i('exportBrain success length=${payload.length}');
      return payload;
    } catch (e, st) {
      _logger.e('exportBrain failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> addProfileTrait(String category, String content) async {
    _logger.i('addProfileTrait start category=$category');
    try {
      final saved = await rust_simple.addProfileTrait(
        category: category,
        content: content,
      );
      _logger.i('addProfileTrait result=$saved');
      return saved;
    } catch (e, st) {
      _logger.e('addProfileTrait failed', error: e, stackTrace: st);
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
  Future<bool> triggerSleepCycle() async {
    _logger.i('Triggering manual sleep cycle');
    try {
      final result = await rust_simple.runSleepCycle();
      _logger.i('triggerSleepCycle result=$result');
      return result;
    } catch (e, st) {
      _logger.e('triggerSleepCycle failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Get AI personality
  Future<Map<String, String>> getAiPersonality() async {
    _logger.d('Fetching AI personality');
    return {};
  }
}
