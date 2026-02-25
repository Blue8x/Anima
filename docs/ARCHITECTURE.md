# Anima Architecture

## 1) System Vision

Anima is a local personal-AI architecture that:
- converses (chat),
- remembers (RAG + persistent memory),
- consolidates (sleep cycle),
- and preserves user identity/language.

Everything runs locally using Flutter (UI) + Rust (AI/data core).

## 2) Current Stack

- **Frontend**: Flutter
- **Backend**: Rust
- **Bridge**: `flutter_rust_bridge` v2 (FFI, no HTTP server)
- **Local inference**: `llama.cpp` + `.gguf` models
- **Persistence**: SQLite

## 3) Main Components

### Frontend (`frontend/lib`)

- `screens/`: onboarding, home, memory, settings, brain.
- `services/anima_service.dart`: FRB call layer.
- `services/translation_service.dart`: local i18n dictionary, language normalization, and global locale state.
- `widgets/`: chat bubbles, message input.

### Backend (`frontend/rust/src`)

- `api/simple.rs`: public API exposed through FRB.
- `ai.rs`: prompting, streaming, embeddings, sleep cycle.
- `db.rs`: SQLite schema + CRUD + semantic retrieval.

## 4) Operational Data Model

The current database uses 4 main tables:
- `messages` → chat history.
- `memories` → embedding per message.
- `profile_traits` → consolidated user traits.
- `config` → name, language, extra prompt settings.

## 5) Key Flows

### A. Memory-Augmented Chat (RAG)

1. User message arrives.
2. It is stored in `messages`.
3. Embedding is generated.
4. Similar memories are retrieved from `memories` using cosine similarity.
5. Context + profile + language rules are assembled.
6. LLM responds (sync or stream).
7. Response and related memory are persisted.

### B. Sleep Cycle

1. Collects raw memories.
2. Runs JSON consolidation in backend.
3. Merges/updates `profile_traits`.
4. Purges raw memory when appropriate.

### C. Language Persistence

1. User selects language in onboarding or settings.
2. It is saved in `config` (`app_language`).
3. UI locale rebuilds instantly via global state.
4. LLM prompt stays aligned with persisted language and latest message mirroring rules.

## 6) Runtime Architecture

There is no remote server. The flow is in-process:

`Flutter UI` → `FRB bindings` → `Rust API` → `AI + DB local`

This minimizes network roundtrip latency and preserves local privacy.

## 7) Folder Structure (Summary)

```
frontend/
   lib/
      main.dart
      screens/
      services/
      widgets/
   rust/
      src/
         api/simple.rs
         ai.rs
         db.rs
docs/
   API.md
   ARCHITECTURE.md
   IMPLEMENTATION_GUIDE.md
   ROADMAP.md
   database/SCHEMA.md
```

---

Last updated: February 25, 2026
