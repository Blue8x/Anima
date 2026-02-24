# Project Summary

## Overview

**Anima** is now a local cognitive architecture: a private digital companion that runs entirely on-device, remembers what matters, and evolves through conversational memory and sleep-cycle consolidation.

This project is no longer a scaffold-only prototype; it has a functional Rust + Flutter product loop with local inference, RAG memory retrieval, profile consolidation, multi-language UX, and reset/recovery controls.

## Current Product State

### Backend (Rust, `frontend/rust`)
- Local LLM inference via `llama.cpp` with dual runtime design:
  - chat runtime
  - embeddings runtime (`all-MiniLM-L6-v2.gguf`)
- Semantic retrieval pipeline:
  - per-message embedding generation
  - storage in `memories` (SQLite BLOB)
  - cosine similarity top-k retrieval with threshold filtering
- Cognitive persistence and profile model:
  - episodic raw memories (`memories`)
  - profile traits (`profile_traits`)
  - user configuration (`config`: name, language, prompt extras)
- Sleep cycle implemented with JSON consolidation and profile fusion.
- Language steering in chat system prompt using persisted app language.
- Factory reset backend endpoint implemented:
  - `factory_reset() -> Result<bool, String>`
  - clears `memories`, `profile_traits`, and `config`.

### API / Bridge (FRB)
- FRB v2 active and regenerated against current Rust API.
- Core endpoints available for:
  - chat send/history
  - memory list/delete
  - sleep cycle execution
  - profile trait CRUD-lite (add/list/clear)
  - app language and user name
  - core prompt settings
  - database export
  - factory reset

### Frontend (Flutter)
- Onboarding flow with:
  - user identity capture
  - optional seed trait
  - language selector (Español, Inglés, Chino, Árabe, Ruso)
- Home chat UX with translated drawer/navigation labels.
- Translation service (`tr(key)`) with Spanish fallback.
- Digital Brain screen with grouped cognitive nodes.
- Sleep-cycle UX upgraded:
  - non-dismissible modal
  - fake animated progress
  - dynamic stage messages
  - smooth fade/scale modal transition
  - controlled shutdown when processing completes.
- Settings/Command Center includes:
  - core prompt extras
  - database export
  - **Factory Reset (double-confirmation destructive flow)**
  - redirect to onboarding using `pushAndRemoveUntil`.

## Key Delivered Capabilities

1. **Local-first cognition**
   - Inference, memory, and personalization fully local.

2. **Dual memory model**
   - Episodic recall (RAG context) + semantic profile consolidation.

3. **Autonomous sleep cycle**
   - Processes daily memories into long-term traits before shutdown.

4. **Identity consistency**
   - Fixed base soul prompt + user augmentations.

5. **Multilingual operation**
   - UI and assistant behavior aligned to selected app language.

6. **Safety and recovery controls**
   - One-click export + destructive full reset with double confirmation.

## Documentation Alignment

The following docs are already aligned to the current architecture and feature set:
- `README.md`
- `docs/ROADMAP.md`
- `docs/API.md`

## Near-Term Priorities

1. Security hardening and key-management strategy.
2. Broader platform QA/performance tuning.
3. Release preparation (stability pass + packaging).

---

**Status:** Phase 5 implemented (cognition + i18n + reset UX), entering Phase 6 hardening
**Last Updated:** February 25, 2026

