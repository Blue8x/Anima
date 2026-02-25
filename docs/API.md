# Anima API Documentation

## Overview

The Flutter app consumes the Rust backend through `flutter_rust_bridge` v2 (in-process FFI, no HTTP).

- Rust API source: `frontend/rust/src/api/simple.rs`
- Dart bindings generated: `frontend/lib/src/rust/` and `frontend/lib/api.dart`

## Bootstrap

Before using the API:

```dart
WidgetsFlutterBinding.ensureInitialized();
await RustLib.init();
```

Then initialize models:

```dart
await initApp(chatModelPath: 'models/anima_v1.gguf', embeddingModelPath: 'models/all-MiniLM-L6-v2.gguf');
```

## Currently Exposed Endpoints

### System / Init

- `greet(name: String) -> String`
- `init_app(chat_model_path: String, embedding_model_path: String) -> ()`

### Chat

- `send_message(message: String, temperature: f32, max_tokens: u32) -> String`
- `send_message_stream(message: String, temperature: f32, max_tokens: u32, sink) -> Result<(), String>`
- `save_assistant_message(message: String) -> bool`
- `generate_proactive_greeting(time_of_day: String) -> Result<String, String>`
- `get_chat_history() -> Vec<ChatMessage>`

### Memory

- `get_all_memories() -> Vec<MemoryItem>`
- `search_memories(query: String) -> Result<Vec<MemoryItem>, String>`
- `delete_memory(id: i64) -> bool`

### Profile / Cognitive

- `get_profile_traits() -> Vec<ProfileTrait>`
- `add_profile_trait(category: String, content: String) -> bool`
- `clear_profile() -> bool`
- `run_sleep_cycle() -> Result<bool, String>`

### Config

- `get_user_name() -> String`
- `set_user_name(name: String) -> bool`
- `get_core_prompt() -> String`
- `set_core_prompt(prompt: String) -> bool`
- `get_app_language() -> String`
- `set_app_language(lang: String) -> bool`

### Maintenance

- `export_database(dest_path: String) -> Result<bool, String>`
- `factory_reset() -> Result<bool, String>`

## Main Types

### ChatMessage

- `id: i64`
- `role: String`
- `content: String`
- `timestamp: String`

### MemoryItem

- `id: i64` (message_id)
- `content: String`
- `created_at: String`

### ProfileTrait

- `category: String`
- `content: String`

## Integration Notes

- `send_message_stream` emits chunks; the UI should concatenate tokens and persist the final result (`save_assistant_message`).
- Persisted language (`app_language`) affects both UI and backend prompt steering.
- `factory_reset` clears `messages`, `memories`, `profile_traits`, and `config`, and resets message autoincrement state.

---

Last updated: February 25, 2026
