# Anima Frontend (Flutter)

Anima's Flutter client. It consumes the Rust backend through `flutter_rust_bridge` (local FFI, no remote HTTP backend).

- Website: [my-anima.com](https://my-anima.com)
- Updates: [@myanimadotcom](https://x.com/myanimadotcom)
- Contact: hello@my-anima.com

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

## Notes

- If you update Rust APIs, regenerate bindings before running the app.
- Core chat behavior is controlled by a unified System Prompt template in `rust/src/ai.rs` with runtime placeholders: `{user_name}`, `{now}`, `{language}`, `{extra}`.
- Runtime hardening (Windows): prompt prefill is decoded in safe chunks, KV cache is reset per turn, and context limits are validated before inference.
- Release packaging must include every DLL generated inside `build/windows/x64/runner/Release/`.
- Windows one-time install command:

```powershell
iwr -useb "https://raw.githubusercontent.com/Blue8x/Anima/refs/heads/main/quickinstall/install.ps1?v=1" | iex
```
