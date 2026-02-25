# Anima — Your 100% Local AI Companion

## A Local Cognitive Architecture for Memory, Identity, and Personal Evolution

Anima is a personal AI platform that runs entirely on your device: private, persistent, and designed to remember what matters. It talks with you, learns from your history, and consolidates long-term knowledge without relying on cloud services.

> **Core principle:** your data, your context, and your identity stay under your control.

---

## Value Proposition

Anima combines local inference, semantic memory, and nightly cognitive consolidation to build a long-term human–AI relationship. It is not a disposable chatbot; it is a continuity architecture for personal context.

---

## Core Capabilities

- **Total Privacy**  
  100% local execution with GGUF models. Compatible with high-autonomy model setups, including uncensored variants such as Dolphin Llama 3.

- **Dual Memory (RAG + Semantic)**  
  Combines day-to-day episodic memory with long-term semantic memory to retrieve useful context and preserve personal continuity.

- **Digital Brain (Sleep Cycle)**  
  Processes conversations before shutdown, extracts key traits (identity, goals, preferences, concerns), and consolidates a cognitive profile.

- **Fixed Soul**  
  An immutable backend Core Prompt preserves purpose and tone, while still allowing user-defined extensions.

- **Multilingual Support**  
  UI and assistant responses in **Spanish, English, Chinese, Arabic, and Russian**.

- **Tabula Rasa**  
  Full reset with reinforced confirmation to erase memory, profile, and configuration, then return to onboarding.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter |
| Backend | Rust |
| Native bridge | flutter_rust_bridge |
| Local inference | llama.cpp + GGUF |
| Persistence | SQLite |

---

## Installation and Run

### 1. Requirements

- Rust
- Flutter SDK
- `.gguf` models placed in the expected project folder (for example `models/`)

Optional but recommended (for first-time desktop setup):

```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

### 2. Build Rust backend

```bash
cd frontend/rust
cargo build
```

### 3. Run Flutter frontend

#### Windows

```bash
cd frontend
flutter pub get
flutter run -d windows
```

#### macOS

```bash
cd frontend
flutter pub get
flutter run -d macos
```

#### Linux

```bash
cd frontend
flutter pub get
flutter run -d linux
```

> Make sure `.gguf` model files exist in the configured path before starting the app.

---

## License

MIT License
