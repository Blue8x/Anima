# Project Roadmap - Anima

## Phase 1 — Foundation (Completed)

- [x] Flutter app bootstrap.
- [x] Rust backend integration via FRB v2.
- [x] SQLite base schema (`messages`, `memories`, `config`, `profile_traits`).

## Phase 2 — Local AI Core (Completed)

- [x] `llama.cpp` local inference runtime.
- [x] Chat response generation.
- [x] Runtime controls (`temperature`, `max_tokens`).

## Phase 3 — Memory + RAG (Completed)

- [x] Embedding generation runtime.
- [x] Embedding persistence in `memories`.
- [x] Cosine similarity retrieval with threshold.
- [x] Prompt context injection.

## Phase 4 — Product Surfaces (Completed)

- [x] Home chat UI.
- [x] Memory browser.
- [x] Settings / Command Center.
- [x] Digital Brain screen.

## Phase 5 — Cognitive Cycle + i18n (Completed)

- [x] Sleep cycle consolidation JSON.
- [x] Profile consolidation in `profile_traits`.
- [x] Persisted language (`app_language`) and LLM steering.
- [x] Unified AAA System Prompt refactor (single non-fragmented template for chat behavior).
- [x] Multilingual onboarding/settings with 7-language selector and instant global locale updates.

## Phase 6 — Streaming + Reliability (Completed)

- [x] Token-by-token chat streaming.
- [x] Final assistant message persistence.
- [x] Full factory reset with double confirmation.
- [x] Database export.

## Phase 7 — Premium UX (Completed)

- [x] Premium dark visual redesign (home/onboarding/menus).
- [x] Unified logo across app, drawer, chat empty state, and app icons.
- [x] Microinteractions (hover/scale/transitions) in drawer and app bars.

## Phase 8 — Hardening & Release (Next)

- [ ] Full E2E QA for onboarding/i18n/streaming/reset.
- [ ] Performance profiling on target hardware.
- [ ] Visual regression checklist per screen.
- [ ] Packaging final release artifacts.

## Future Exploration

- [ ] Local voice support (ASR/TTS).
- [ ] Multimodal memory.
- [ ] Optional encrypted cross-device sync.
- [ ] Optional integrations (calendar/notes).

---

Last updated: February 26, 2026

