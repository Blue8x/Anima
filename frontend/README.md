# Anima Frontend (Flutter)

Frontend Flutter app for Anima. It uses `flutter_rust_bridge` v2 to call the Rust backend through generated Dart bindings.

## Prerequisites

- Flutter SDK (with Dart >= 3.3)
- Rust toolchain installed

## Run locally (Windows)

From the repository root:

```bash
cd backend
cargo build --release

cd ../frontend
flutter pub get
flutter run -d windows
```

## FRB v2 bindings

Current generated files are in `lib/`:

- `lib/api.dart`
- `lib/frb_generated.dart`
- `lib/frb_generated.io.dart`
- `lib/frb_generated.web.dart`

App bootstrap initializes FRB in `lib/main.dart` with `await RustLib.init()`.

## Useful commands

```bash
flutter analyze
flutter test
flutter build windows --release
```
