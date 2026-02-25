# Project Summary

## Executive Summary

**Anima** is a local AI companion focused on personal continuity: conversation + memory + cognitive consolidation. The system runs on Flutter + Rust, with inference and persistence on the user’s device.

The product is already in a strong functional V1 state: streaming chat, semantic memory, cognitive profile, advanced i18n, premium UX, and recovery controls.

## Product Objective

Move from a stateless chatbot to a continuity-based companion.

Anima is designed to:
- remember relevant information across sessions,
- consolidate user patterns into a useful profile,
- keep tone/language coherence,
- and preserve local privacy.

## Current Technical State

### 1) Rust Backend (frontend/rust)

- Dual AI runtime (chat + embeddings).
- SQLite persistence:
  - messages (history),
  - memories (embedding per message),
  - profile_traits (consolidated profile),
  - config (name, language, prompt extras).
- Semantic retrieval through cosine similarity.
- Sleep cycle to consolidate raw memories into traits.
- Prompt steering based on persisted language.
- DB export and transactional factory reset.

### 2) API and Bridge (flutter_rust_bridge)

- FRB v2 is operational and synchronized.
- Main surface: chat (sync + stream), memory, profile, config, sleep cycle, export, and reset.

### 3) Flutter Frontend

- Multi-step onboarding with wheel-based language selector + extra menu.
- Home chat with streaming and final-response persistence.
- Premium drawer/menus with microinteractions.
- Settings, Memory, and Brain screens with coherent dark style.
- Global i18n with code normalization and robust fallback.

## Delivered Key Capabilities

1. **Local privacy by design**.
2. **Contextual memory during conversation**.
3. **Cognitive consolidation through Sleep Cycle**.
4. **Identity/tone control through base prompt + extras**.
5. **Persistent multilingual experience**.
6. **Safe critical operations (export/reset)**.

## Recommended Next Focus Areas

- Release hardening (cross-platform QA, performance, visual regression).
- E2E test coverage for onboarding/i18n/streaming.
- Distribution (installers, release notes, public Anima.ai web).

---

**Status:** Functional V1 + visual polish completed  
**Last Updated:** February 25, 2026

