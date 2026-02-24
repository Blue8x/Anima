# Anima API Documentation

## Overview

Anima frontend and backend communicate through flutter_rust_bridge (FRB) v2 over FFI.

Current status:
- Bridge technology: flutter_rust_bridge v2
- Dart generated bindings: frontend/lib/api.dart and frontend/lib/frb_generated*.dart
- Rust exported API source: frontend/rust/src/api/simple.rs

## Communication Model (Current)

- Type: In-process FFI calls (no HTTP server)
- Dart side: generated top-level functions in frontend/lib/api.dart
- Rust side: functions annotated with #[flutter_rust_bridge::frb]

## Current Exported API (frontend/rust/src/api/simple.rs)

### Chat and bootstrap
- `init_app(chat_model_path: String, embedding_model_path: String) -> ()`
- `send_message(message: String, temperature: f32, max_tokens: u32) -> String`
- `get_chat_history() -> Vec<ChatMessage>`

### Memory and profile
- `get_all_memories() -> Vec<MemoryItem>`
- `delete_memory(id: i64) -> bool`
- `run_sleep_cycle() -> Result<bool, String>`
- `get_profile_traits() -> Vec<ProfileTrait>`
- `add_profile_trait(category: String, content: String) -> bool`
- `clear_profile() -> bool`

### User config and identity
- `get_user_name() -> String`
- `set_user_name(name: String) -> bool`
- `get_core_prompt() -> String`
- `set_core_prompt(prompt: String) -> bool`
- `get_app_language() -> String`
- `set_app_language(lang: String) -> bool`

### Utilities
- `export_database(dest_path: String) -> Result<bool, String>`
- `greet(name: String) -> String`

## Legacy FRB Surface (frontend/lib/api.dart)

### saveUserMessage

Stores a user message in episodic memory.

Dart call:

```dart
final id = await saveUserMessage(content: 'Today was an intense day.');
```

Dart signature:

```dart
Future<String> saveUserMessage({required String content})
```

Rust source function:

```rust
#[flutter_rust_bridge::frb]
pub fn save_user_message(content: String) -> Result<String, String>
```

Response semantics:
- Success: returns the created message id
- Error: throws an FRB exception carrying Rust String error

### getRecentMemories

Returns the most recent episodic memories.

Dart call:

```dart
final memories = await getRecentMemories(limit: 50);
```

Dart signature:

```dart
Future<List<EpisodicMemoryDto>> getRecentMemories({required int limit})
```

Rust source function:

```rust
#[flutter_rust_bridge::frb]
pub fn get_recent_memories(limit: u32) -> Result<Vec<EpisodicMemoryDto>, String>
```

## Data Types

### EpisodicMemoryDto

Generated Dart DTO in frontend/lib/api.dart:

```dart
class EpisodicMemoryDto {
  final String id;
  final String timestamp;
  final String role;
  final String content;
  final bool processed;
}
```

Field meanings:
- id: message identifier
- timestamp: ISO-8601 string generated in Rust
- role: user or ai
- content: message text
- processed: true when consolidated by sleep cycle

## App Bootstrap Requirements

Before calling any API function, FRB must be initialized once:

```dart
WidgetsFlutterBinding.ensureInitialized();
await RustLib.init();
```

Current app initialization is in frontend/lib/main.dart.

## Planned API (Not Yet Exposed via FRB)

The following areas are planned in architecture docs but are not yet exported in frontend/rust/src/api/simple.rs:
- semantic insights
- user identity read/update
- sleep-cycle control and status
- settings and health/status surface

When these are implemented, update this file with exact Dart signatures and matching Rust functions.

Last updated: February 25, 2026
