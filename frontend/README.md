# Anima Frontend (Flutter)

Anima's Flutter client. It consumes the Rust backend through `flutter_rust_bridge` (local FFI, no remote HTTP backend).

## Requirements

- Flutter SDK
- Rust toolchain
- `.gguf` models available in `../models/`

## Run locally

```bash
cd frontend
flutter pub get
flutter run -d windows
```

You can use `-d macos` or `-d linux` depending on your platform.

## FRB Integration

- Rust API: `rust/src/api/simple.rs`
- Service wrapper: `lib/services/anima_service.dart`
- Bootstrap: `lib/main.dart` (`await RustLib.init()` + `initApp(...)`)

If you change Rust signatures:

```bash
flutter_rust_bridge_codegen generate
```

## Useful commands

```bash
flutter analyze
flutter test
flutter build windows --release
```
