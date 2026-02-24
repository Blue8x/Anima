# Anima - AI Biographer and Local Mentor

Anima is your private biographer, journal, and mentor. It remembers what matters, supports your growth, and runs fully offline. Zero cloud. Total privacy.

## Current Milestone

- Phase 2 (Local LLM integration with `llama.cpp`) is completed.
- Phase 3 (RAG + long-term semantic memory with vector search) is completed.
- Real-time local inference is running in Rust and connected end-to-end to the Flutter chat UI.
- Dual-model pipeline is active: chat model + embedding model (`all-MiniLM-L6-v2.gguf`).
- Semantic memories are persisted in SQLite (`memories` table with embedding BLOB) and retrieved via cosine similarity top-k.
- Generation parameters are wired from Flutter to Rust (`temperature`, `max_tokens`) for runtime control.

## Language Support

- User-selectable app language at onboarding: Inglés, Español, Chino, Árabe, Ruso.
- UI text is translated dynamically (onboarding, drawer, chat input, relative chat timestamps).
- Selected language is persisted locally in Rust config (`app_language`).
- Chat system prompt enforces responses in the selected app language, regardless of input language.

## Changelog (Phase 5 + i18n)

- Added cognitive sleep cycle with JSON consolidation into persistent profile traits.
- Implemented profile fusion (existing traits + raw episodic memories) during nightly processing.
- Added Digital Brain and memory control surfaces in Flutter UI.
- Added onboarding language selection with five supported languages.
- Added dynamic UI translation (`tr(key)`) with Spanish fallback.
- Enforced LLM response language via system prompt directive using saved `app_language`.

## Value Proposition

Anima is a cross-platform app that works as a personal biographer, intelligent diary, and AI mentor. What sets it apart:

- Long-term memory across conversations and life patterns
- 100% local execution with no internet dependency
- Encrypted data at rest with AES-256
- Adaptive personality that evolves with the user

## Technical Stack

| Layer | Technology |
|------|------------|
| Frontend | Flutter (iOS, Android, macOS, Windows) |
| AI Engine | llama.cpp + quantized models (Llama-3-8B, Phi-3) |
| Database | SQLite + sqlite-vec (AES-256) |
| Backend | Rust (performance, safety, efficiency) |
| Communication | Native IPC / FFI |

## Memory Architecture (4 Layers)

```
┌─────────────────────────────────────┐
│ 1. Episodic Memory                  │
│    Raw conversations and diary logs │
│    Vector embeddings per message    │
└─────────────────────────────────────┘
						↓ (Sleep Cycle)
┌─────────────────────────────────────┐
│ 2. Semantic Memory                  │
│    Consolidated knowledge           │
│    Patterns and insights            │
└─────────────────────────────────────┘
						↓
┌─────────────────────────────────────┐
│ 3. User Identity                    │
│    Long-term traits and profile     │
└─────────────────────────────────────┘
						↓
┌─────────────────────────────────────┐
│ 4. AI Self Model                    │
│    Personality parameters           │
└─────────────────────────────────────┘
```

## Project Structure

```
anima/
├── backend/                    # Rust backend
│   ├── src/
│   │   ├── main.rs           # Entry point
│   │   ├── api.rs            # Flutter Rust Bridge API
│   │   ├── models/           # Data structures
│   │   ├── database/         # Database layer
│   │   └── services/         # Business logic
│   └── Cargo.toml
│
├── frontend/                   # Flutter frontend
│   ├── lib/
│   │   ├── api.dart                  # FRB v2 generated API
│   │   ├── frb_generated.dart        # FRB v2 entrypoint/bootstrap
│   │   ├── frb_generated.io.dart
│   │   ├── frb_generated.web.dart
│   │   ├── main.dart
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   └── pubspec.yaml
│
├── docs/                       # Documentation
│   ├── ARCHITECTURE.md
│   ├── API.md
│   ├── database/SCHEMA.md
│   ├── IMPLEMENTATION_GUIDE.md
│   └── ROADMAP.md
│
└── README.md
```

## Getting Started

### Prerequisites

- Backend: Rust 1.70+
- Frontend: Flutter 3.10+, Dart

### Quick Start

```bash
git clone https://github.com/your-username/anima.git
cd anima

cd backend
cargo build --release

cd ../frontend
flutter pub get
flutter run -d windows
```

Notes:
- FRB v2 generated files are currently in `frontend/lib/` (for example `api.dart`, `frb_generated.dart`).
- The Flutter app initializes FRB in `frontend/lib/main.dart` via `await RustLib.init()`.
- On Windows, the Rust dynamic library is loaded from `backend/target/release/`.

For detailed instructions, see [docs/IMPLEMENTATION_GUIDE.md](docs/IMPLEMENTATION_GUIDE.md).

## Documentation

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - System design and workflows
- [docs/database/SCHEMA.md](docs/database/SCHEMA.md) - Database schema
- [docs/API.md](docs/API.md) - API specification
- [docs/IMPLEMENTATION_GUIDE.md](docs/IMPLEMENTATION_GUIDE.md) - Development guide
- [docs/ROADMAP.md](docs/ROADMAP.md) - Development roadmap

## Core Workflows

### Chat Interaction (Local RAG)

```
User message
	→ Generate embedding
	→ Vector search in episodic and semantic memory
	→ Build prompt with user identity and AI personality
	→ LLM generates response
	→ Store both user and AI messages
```

### Sleep Cycle (Memory Consolidation)

```
Nightly trigger
	→ Fetch unprocessed episodes
	→ LLM reflection prompt
	→ Extract insights and traits
	→ Update semantic_memory, user_identity, ai_self_model
	→ Mark episodes as processed
```

## Security and Privacy

- AES-256 encryption for the entire database (SQLCipher)
- 100% local processing
- No data synchronization across devices
- Native key management (Secure Enclave, Keychain, Android Keystore)

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License. See [LICENSE](LICENSE).

## Contact

- Email: support@animaai.local
- Issues: https://github.com/your-username/anima/issues
- Discussions: https://github.com/your-username/anima/discussions

Last updated: February 25, 2026 (Phase 5 core + i18n completed)
