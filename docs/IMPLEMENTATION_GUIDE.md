# Implementation Guide - Anima

## Getting Started

This guide covers the setup and development of the Anima project across backend and frontend.

## Backend Setup (Rust)

### Prerequisites
- Rust 1.70+ ([Install Rust](https://rustup.rs/))
- Cargo (included with Rust)

### Building the Backend

```bash
cd backend
cargo build --release
```

### Running Tests

```bash
cargo test
```

### Running the Backend

```bash
cargo run --release
```

The backend will start and initialize the SQLite database with AES-256 encryption.

## Frontend Setup (Flutter)

### Prerequisites
- Flutter 3.10+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Dart >= 3.3 (included with Flutter)

### Getting Dependencies

```bash
cd frontend
flutter pub get
```

### Running the App

#### iOS
```bash
flutter run -d iphone
# or for simulator:
open -a Simulator && flutter run
```

#### Android
```bash
flutter run -d android
# or list devices:
flutter devices
```

#### macOS
```bash
flutter run -d macos
```

#### Windows
```bash
cd backend
cargo build --release

cd ../frontend
flutter run -d windows
```

### Flutter Rust Bridge (FRB v2)

This project uses `flutter_rust_bridge` v2.

- `flutter_rust_bridge.yaml` points Dart output to `frontend/lib`
- Generated files currently used by the app:
    - `frontend/lib/api.dart`
    - `frontend/lib/frb_generated.dart`
    - `frontend/lib/frb_generated.io.dart`
    - `frontend/lib/frb_generated.web.dart`
- FRB initialization happens in `frontend/lib/main.dart` via `await RustLib.init()`

If you change Rust API signatures, regenerate bindings:

```bash
flutter_rust_bridge_codegen generate
```

### Building for Release

#### iOS
```bash
flutter build ios --release
# Then open in Xcode and build/archive
```

#### Android
```bash
flutter build apk --release
# or AAB (Google Play):
flutter build appbundle --release
```

#### macOS
```bash
flutter build macos --release
```

#### Windows
```bash
flutter build windows --release
```

## Architecture Overview

### Backend Flow

```
User Message
    ↓
Chat Service
    ├─→ Generate Embedding
    ├─→ Vector Search (episodic_memory, semantic_memory)
    ├─→ Compile Context
    ├─→ Send to LLM
    └─→ Save Response
    
    ↓
Memory Consolidation (Sleep Cycle)
    ├─→ Fetch Unprocessed Episodes
    ├─→ Send to LLM with Reflection Prompt
    ├─→ Extract Insights
    ├─→ Update user_identity
    └─→ Update ai_self_model
```

### Frontend Architecture

```
Flutter App
    ├─ Screens
    │   └─ HomeScreen (Chat Interface)
    ├─ Services
    │   └─ AnimaService (FRB v2 calls to Rust backend)
    ├─ Widgets
    │   ├─ ChatBubble
    │   └─ MessageInput
    └─ FRB Bindings
        ├─ api.dart
        └─ frb_generated*.dart
```

## Core Components

### 1. Database (backend/src/database/)

- **db_manager.rs**: SQLite operations with encryption
- **vector_search.rs**: Cosine similarity search for embeddings

### 2. Models (backend/src/models/)

- **memory.rs**: Core data structures (EpisodicMemory, SemanticMemory, etc.)
- **identity.rs**: User profile models

### 3. Services (backend/src/services/)

- **chat.rs**: Message processing and RAG
- **sleep_cycle.rs**: Memory consolidation
- **ai.rs**: AI personality management

## Configuration

### Backend Configuration

Create `backend/.env`:
```env
DATABASE_PASSWORD=your_secure_password
LLM_MODEL_PATH=/path/to/model.gguf
EMBEDDING_MODEL_PATH=/path/to/embedding_model.onnx
SLEEP_CYCLE_TIME=03:00
LOG_LEVEL=info
```

### Frontend Configuration

Create `frontend/.env`:
```env
BACKEND_IPC_PATH=/tmp/anima.sock
MAX_MESSAGE_HISTORY=100
VECTOR_SEARCH_LIMIT=5
```

## Development Workflow

### Adding a New Data Model

1. Add to `backend/src/models/memory.rs`
2. Add database table in `backend/src/database/db_manager.rs`
3. Add CRUD operations
4. Mirror in Flutter models

### Adding a New Service Method

1. Define in appropriate service file (`backend/src/services/`)
2. Add to API documentation
3. Implement Flutter service call
4. Add UI to interact with it

### Running Locally

Build Rust library:
```bash
cd backend
cargo build --release
```

Run Flutter app:
```bash
cd frontend
flutter run -d windows
```

## Testing

### Backend Tests

```bash
cd backend
cargo test --all
```

### Frontend Tests

```bash
cd frontend
flutter test
```

## Deployment

### Backend Deployment

1. Build release binary: `cargo build --release`
2. Binary at: `target/release/anima-core`
3. Bundle with assets and models
4. Encrypt database with strong password

### Frontend Deployment

See Flutter documentation for your platform:
- [iOS Deployment](https://flutter.dev/docs/deployment/ios)
- [Android Deployment](https://flutter.dev/docs/deployment/android)
- [macOS Deployment](https://flutter.dev/docs/deployment/macos)
- [Windows Deployment](https://flutter.dev/docs/deployment/windows)

## Troubleshooting

### Database Connection Issues
- Check password in `.env`
- Ensure database file has proper permissions
- Check SQLCipher configuration

### Vector Search Not Working
- Ensure embeddings are generated with correct dimensionality (768)
- Check sqlite-vec extension is loaded
- Verify vector search SQL syntax

### LLM Not Responding
- Check model file exists and is in GGUF format
- Verify llama.cpp is compiled correctly
- Check system resources (RAM, GPU)

## Next Steps

1. Implement llama.cpp integration for LLM
2. Implement embedding generation (Sentence-BERT)
3. Extend Rust API surface and regenerate FRB bindings
4. Implement sleep cycle scheduler
5. Add UI for identity management
6. Add export/backup functionality

