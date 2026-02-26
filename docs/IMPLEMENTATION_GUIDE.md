# Implementation Guide - Anima

This guide describes how to develop and maintain Anima using the **current** project structure.

## 1) Prerequisites

- Flutter SDK (Dart included)
- Rust (`rustup`, `cargo`)
- `.gguf` models in `models/`

Recommended for desktop:

```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

## 2) Run the Project

```bash
cd frontend
flutter pub get
flutter run -d windows
```

Also supports `-d macos` and `-d linux`.

## 3) Build/Check Rust Backend

```bash
cd frontend/rust
cargo check
cargo build
```

## 4) FRB Flow

Anima uses `flutter_rust_bridge` v2.

- Rust API: `frontend/rust/src/api/simple.rs`
- Dart service wrapper: `frontend/lib/services/anima_service.dart`

If you change Rust signatures, regenerate bindings:

```bash
flutter_rust_bridge_codegen generate
```

## 5) Relevant Structure

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
```

## 6) Development Conventions

### Add a New Endpoint

1. Implement function in `frontend/rust/src/api/simple.rs`.
2. Add logic in `ai.rs` and/or `db.rs` if needed.
3. Regenerate FRB.
4. Expose wrapper in `AnimaService`.
5. Integrate into screen/widget.
6. Update `docs/API.md`.

### Modify Prompt Behavior

1. Edit unified system prompt template in `frontend/rust/src/ai.rs`.
2. Keep placeholders synchronized: `{user_name}`, `{now}`, `{language}`, `{extra}`.
3. Keep language enforcement explicit (responses/greetings/thoughts in configured app language).
4. Run `cargo check` in `frontend/rust`.

### Modify Inference Runtime (Critical)

When touching `ai.rs`, keep these constraints intact:

1. `n_ctx` bounded (currently 2048) with explicit overflow error.
2. Prompt prefill decode in chunks (`SAFE_N_BATCH`, currently 512), never all tokens at once.
3. Stateless turn isolation (`clear_kv_cache`) before and after generation.
4. No panic paths in inference flow (`unwrap`/`expect` avoided in runtime-critical generation code).

### Add a New Screen

1. Create it in `frontend/lib/screens/`.
2. Connect navigation (usually from `home_screen.dart`).
3. Keep premium dark style consistent.
4. Add i18n keys if new text is introduced.

### Add a Translation

1. Edit `frontend/lib/services/translation_service.dart`.
2. Add the key in `AppTranslations.values` for all 7 supported languages: `EN`, `ES`, `DE`, `RU`, `JP`, `ZH`, `AR`.
3. If needed, update language normalization aliases.
4. Verify fallback to `EN`.

## 7) Recommended Quick QA

```bash
# Flutter (analysis)
flutter analyze

# Rust (backend)
cd frontend/rust
cargo check
```

Minimum manual flows:
- Onboarding (7-language selector).
- Onboarding "Start journey" fallback path when language persistence fails.
- Chat streaming + final persistence.
- Long-prompt second-turn chat on a clean install (Windows Release build).
- Sleep cycle.
- Factory reset.
- Instant language switch from onboarding and settings.
- Verify output language follows `app_language` after prompt edits.

## 8) Release Checklist (Summary)

1. Verify `.gguf` models and paths.
2. Regenerate icons (`flutter_launcher_icons`) if branding changed.
3. Review docs (`README`, `API`, `ROADMAP`, `SCHEMA`).
4. `git add -A && git commit && git push`.

---

Last updated: February 26, 2026

