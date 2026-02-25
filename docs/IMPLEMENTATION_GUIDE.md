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

### Add a New Screen

1. Create it in `frontend/lib/screens/`.
2. Connect navigation (usually from `home_screen.dart`).
3. Keep premium dark style consistent.
4. Add i18n keys if new text is introduced.

### Add a Translation

1. Edit `frontend/lib/services/translation_service.dart`.
2. Add keys for each language.
3. Normalize code/aliases if it is a new language.
4. Verify fallback (`ES` and legacy keys).

## 7) Recommended Quick QA

```bash
# Flutter (analysis)
flutter analyze

# Rust (backend)
cd frontend/rust
cargo check
```

Minimum manual flows:
- Onboarding (main language + `more`).
- Chat streaming + final persistence.
- Sleep cycle.
- Factory reset.

## 8) Release Checklist (Summary)

1. Verify `.gguf` models and paths.
2. Regenerate icons (`flutter_launcher_icons`) if branding changed.
3. Review docs (`README`, `API`, `ROADMAP`, `SCHEMA`).
4. `git add -A && git commit && git push`.

---

Last updated: February 25, 2026

