# Anima Architecture - Local AI Biographer and Mentor

## 1. Product Concept

**Anima** is a cross-platform application (mobile and desktop) that acts as a personal biographer, journal, and AI mentor.

Core characteristics:
- **Long-Term Memory**: A 4-layer memory model inspired by cognitive architecture
- **Privacy by Default**: All AI processing runs locally with no internet dependency
- **100% Local Operation**: No automatic cross-device synchronization
- **Encrypted Storage**: AES-256 database encryption
- **Quantized Models**: llama.cpp-based local inference for efficiency

## 2. Core Technology Stack

### Frontend / UI
- **Flutter**: Native builds for iOS, Android, Windows, and macOS from one Dart codebase

### Frontend-Backend Integration
- **flutter_rust_bridge (FRB) v2**: FFI bridge between Dart and Rust
- **Generated bindings (current)**: frontend/lib/api.dart and frontend/lib/frb_generated*.dart
- **Initialization**: RustLib.init() during Flutter app startup
- **Current exposed API**: save user message and fetch recent memories

### Local AI Runtime
- **llama.cpp**: Quantized model runtime with native acceleration
  - Metal (macOS)
  - GPU/NPU (Windows, Android)
  - Neural Engine (iOS)

### Language Models (LLM)
- Llama-3-8B-Instruct (GGUF) - primary
- Phi-3-mini - lightweight alternative
- Gemma-2B - low-resource devices

### Database and Vector Storage
- **SQLite**: Primary local data store
- **sqlite-vec**: Vector storage and similarity search
- **SQLCipher**: Full-database AES-256 encryption

### Security and Key Storage
- **SQLCipher**: Data-at-rest encryption
- **Secure Enclave** (iOS): Native key management
- **Keychain** (macOS): Credential storage
- **Android Keystore**: Key management

### Background Processing
- **WorkManager** (Android)
- **BackgroundTasks** (iOS)
- **Desktop scheduling**: Windows Task Scheduler / cron

## 3. Memory Architecture (4 Layers)

### Table 1: episodic_memory
**Purpose**: Raw journal/chat events and short-term memory

| Field | Type | Description |
|-------|------|-------------|
| id | TEXT (PK) | Unique UUID |
| timestamp | DATETIME | ISO 8601 timestamp |
| role | TEXT | 'user' or 'ai' |
| content | TEXT | Exact message content |
| embedding | VECTOR | Vector representation (768D) |
| processed | BOOLEAN | false by default, true after sleep cycle |
| metadata | JSON | Tags, sentiment, extra context |

**Indexes**:
- PRIMARY KEY (id)
- INDEX ON timestamp
- INDEX ON processed
- VECTOR INDEX ON embedding

### Table 2: semantic_memory
**Purpose**: Consolidated knowledge and extracted patterns

| Field | Type | Description |
|-------|------|-------------|
| id | TEXT (PK) | Unique UUID |
| topic | TEXT | Topic category (work, health, relationships, etc.) |
| insight | TEXT | Insight extracted from episodic memory |
| importance_score | INTEGER | 1-10 relevance score |
| embedding | VECTOR | Vector representation |
| source_episodes | TEXT[] | Source episodic message IDs |
| confidence_score | FLOAT | Confidence score (0.0-1.0) |
| last_updated | DATETIME | Last update timestamp |

**Indexes**:
- PRIMARY KEY (id)
- INDEX ON topic
- INDEX ON importance_score
- VECTOR INDEX ON embedding

### Table 3: user_identity
**Purpose**: Long-term user profile

| Field | Type | Description |
|-------|------|-------------|
| id | TEXT (PK) | Unique UUID |
| trait_name | TEXT | e.g. profession, core fear, hobbies |
| value | TEXT | Trait value |
| confidence_score | INTEGER | Confidence (0-100) |
| category | TEXT | profession, personality, fear, hobby, goal |
| evidence_count | INTEGER | Number of supporting episodes |
| last_reinforced | DATETIME | Last reinforcement time |

**Indexes**:
- PRIMARY KEY (id)
- UNIQUE INDEX (trait_name, category)
- INDEX ON confidence_score

### Table 4: ai_self_model
**Purpose**: AI behavior and personality evolution

| Field | Type | Description |
|-------|------|-------------|
| id | TEXT (PK) | Unique UUID |
| parameter | TEXT | e.g. tone, empathy level, humor |
| current_state | TEXT | Current parameter value |
| delta_from_previous | TEXT | Change from previous state |
| reinforcement_count | INTEGER | Number of reinforcements |
| last_updated | DATETIME | Last update timestamp |

**Indexes**:
- PRIMARY KEY (id)
- UNIQUE INDEX (parameter)

## 4. Main Workflows

### A) Chat Interaction (Local RAG)

```
1. User sends a message
2. Generate embedding for the message
3. Run vector similarity search on:
   - episodic_memory (recent context)
   - semantic_memory (longer-term knowledge)
4. Build prompt context with:
   - user identity
   - AI self model
   - top relevant episodes/insights
5. LLM generates response
6. Store both user and AI messages in episodic_memory
```

### B) Sleep Cycle (Memory Consolidation)

```
Trigger: scheduled time + suitable device state
1. Fetch episodic entries where processed == false
2. Group entries by topic clusters
3. Run reflection prompt on grouped conversations
4. Extract:
   - semantic insights
   - user identity updates
   - AI self model updates
5. Persist updates
6. Mark processed episodes as true
```

### C) Context Retrieval During Chat

```
1. Generate query embedding
2. Retrieve top episodic and semantic matches
3. Rank by relevance and recency
4. Inject into LLM context
5. Use as working memory for the final response
```

## 5. Prompt System

### Main System Prompt (Template)

```
You are Anima, a personal AI companion—biographer, mentor, and confidant.
Your goals:
- Listen and understand deeply
- Remember meaningful life patterns
- Offer personalized guidance and reflection

[USER IDENTITY]
{user_identity}

[CURRENT AI PERSONALITY]
{ai_self_model}

[RECENT CONTEXT]
{relevant_episodes}

[PAST INSIGHTS]
{relevant_insights}
```

### Sleep-Cycle Reflection Prompt (Template)

```
Reflect on these conversations and extract:
1. Patterns
2. User traits
3. Personal evolution
4. Recommended AI interaction adjustments

[CONVERSATIONS]
{unprocessed_episodes}
```

## 6. Privacy and Security Considerations

- **Data at rest**: SQLCipher with AES-256
- **No cloud transmission**: Data remains on device
- **Key management**: Native secure storage per platform
- **Secure deletion**: Full local history reset options
- **Process isolation**: Local-only communication between app components

## 7. Directory Structure

```
anima/
├── backend/
│   ├── src/
│   │   ├── database/
│   │   │   ├── db_manager.rs
│   │   │   └── vector_search.rs
│   │   ├── models/
│   │   │   ├── memory.rs
│   │   │   └── identity.rs
│   │   ├── services/
│   │   │   ├── ai.rs
│   │   │   ├── chat.rs
│   │   │   └── sleep_cycle.rs
│   │   ├── api.rs
│   │   └── main.rs
│   └── Cargo.toml
├── frontend/
│   ├── lib/
│   │   ├── api.dart
│   │   ├── frb_generated.dart
│   │   ├── frb_generated.io.dart
│   │   ├── frb_generated.web.dart
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── services/
│   │   └── main.dart
│   └── pubspec.yaml
├── docs/
│   ├── database/
│   ├── API.md
│   ├── ARCHITECTURE.md
│   ├── IMPLEMENTATION_GUIDE.md
│   └── ROADMAP.md
└── README.md
```

Last updated: February 24, 2026
