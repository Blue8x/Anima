# Project Roadmap - Anima

## Phase 1: Core Infrastructure (Completed)

### Backend
- [x] SQLite schema and initialization
- [x] Core data models (messages, memories, profile, config)
- [x] FRB v2 bridge setup

### Frontend
- [x] Flutter scaffolding and app bootstrap
- [x] Service layer and FRB integration
- [x] Core chat UI and reusable widgets

## Phase 2: Local LLM Integration (Completed)

### Backend
- [x] `llama.cpp` runtime initialization
- [x] Local chat inference pipeline
- [x] Runtime generation controls (`temperature`, `max_tokens`)

### Frontend
- [x] End-to-end chat connected to Rust inference

## Phase 3: RAG + Semantic Memory (Completed)

### Backend
- [x] Embedding generation runtime (`all-MiniLM-L6-v2.gguf`)
- [x] Embedding persistence in SQLite (`memories` BLOB)
- [x] Cosine similarity top-k retrieval + threshold filtering
- [x] Prompt context injection with relevant memories

### Frontend
- [x] Message flow with persisted long-term context

## Phase 4: UX + Control Surfaces (Completed)

### Backend
- [x] Config endpoints (core prompt, user name, export)
- [x] Profile trait management endpoints

### Frontend
- [x] Memory Explorer
- [x] Settings / Command Center
- [x] Mirror and Digital Brain screens
- [x] Onboarding entry flow

## Phase 5: Cognitive Cycle + Internationalization (Core Completed)

### Backend
- [x] Sleep cycle JSON consolidation
- [x] Profile fusion (current profile + raw memories)
- [x] Raw episodic memory purge after consolidation
- [x] App language persistence (`app_language`)
- [x] Chat system prompt language steering

### Frontend
- [x] Language selector in onboarding (Inglés, Español, Chino, Árabe, Ruso)
- [x] Dynamic UI translation (`tr(key)` + Spanish fallback)
- [x] i18n applied to drawer, onboarding, chat input, relative timestamps

## Phase 6: Privacy & Security (Next)

- [ ] Secure key management hardening
- [ ] Biometric unlock flow
- [ ] Encryption verification and secure deletion tests
- [ ] Threat-model and privacy compliance pass

## Phase 7: Polish & Release

- [ ] Performance optimization and latency tuning
- [ ] End-to-end QA and stability fixes
- [ ] Documentation final pass
- [ ] Beta testing and public release readiness

## Research & Exploration

### AI/ML
- [ ] Fine-tuning LLM on user patterns (optional)
- [x] Multi-language support (UI + LLM steering)
- [ ] Voice input/output capability
- [ ] Multimodal embeddings (text + image support)

### Features
- [ ] Cross-device sync (optional - privacy trade-off)
- [ ] Cloud backup (optional - privacy trade-off)
- [ ] Collaborative features (optional - group dynamics)
- [ ] Integration with calendars/notes apps

### Performance
- [ ] Quantization optimization
- [ ] Mobile-specific model optimization
- [ ] Battery impact analysis
- [ ] Storage footprint reduction

## Success Metrics

- User retention rate (target: 80% week 1, 50% month 1)
- Average daily usage (target: 10+ min/day)
- Memory quality (user satisfaction with recalled context)
- Response latency (target: <2 seconds on average device)
- Storage footprint (target: <1GB)
- Battery impact (target: <5% per hour of usage)

