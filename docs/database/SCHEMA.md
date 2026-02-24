# Database Schema - Anima

## Overview

Anima uses SQLite with sqlite-vec for local 4-layer memory storage and vector similarity search.

## SQLite Setup

```sql
-- Enable extensions
PRAGMA query_only = false;
PRAGMA foreign_keys = ON;
```

## Table Definitions

### 1. episodic_memory

Stores raw episodic memory—user and AI conversations in chronological order.

```sql
CREATE TABLE episodic_memory (
    id TEXT PRIMARY KEY,
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    role TEXT NOT NULL CHECK (role IN ('user', 'ai')),
    content TEXT NOT NULL,
    embedding BLOB NOT NULL, -- 768-dimensional vector
    processed BOOLEAN NOT NULL DEFAULT FALSE,
    metadata JSON,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_episodic_timestamp ON episodic_memory(timestamp);
CREATE INDEX idx_episodic_processed ON episodic_memory(processed);
CREATE INDEX idx_episodic_role ON episodic_memory(role);

-- Vector index using sqlite-vec
CREATE VIRTUAL TABLE episodic_memory_vec USING vec0(
    embedding(768)
);
```

### 2. semantic_memory

Stores consolidated insights and patterns extracted during the sleep cycle.

```sql
CREATE TABLE semantic_memory (
    id TEXT PRIMARY KEY,
    topic TEXT NOT NULL,
    insight TEXT NOT NULL,
    importance_score INTEGER NOT NULL CHECK (importance_score >= 1 AND importance_score <= 10),
    embedding BLOB NOT NULL, -- 768-dimensional vector
    source_episodes TEXT, -- JSON array of source episode IDs
    confidence_score REAL NOT NULL DEFAULT 0.5 CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0),
    last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_semantic_topic ON semantic_memory(topic);
CREATE INDEX idx_semantic_importance ON semantic_memory(importance_score DESC);
CREATE INDEX idx_semantic_confidence ON semantic_memory(confidence_score DESC);

-- Vector index using sqlite-vec
CREATE VIRTUAL TABLE semantic_memory_vec USING vec0(
    embedding(768)
);
```

### 3. user_identity

Long-term user profile—traits, characteristics, fears, and goals.

```sql
CREATE TABLE user_identity (
    id TEXT PRIMARY KEY,
    trait_name TEXT NOT NULL,
    value TEXT NOT NULL,
    confidence_score INTEGER NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 100),
    category TEXT NOT NULL CHECK (category IN (
        'profession', 'personality', 'fear', 'hobby', 'goal', 
        'relationship', 'health', 'education', 'other'
    )),
    evidence_count INTEGER NOT NULL DEFAULT 1,
    last_reinforced DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(trait_name, category)
);

CREATE INDEX idx_identity_category ON user_identity(category);
CREATE INDEX idx_identity_confidence ON user_identity(confidence_score DESC);
CREATE INDEX idx_identity_reinforced ON user_identity(last_reinforced DESC);
```

### 4. ai_self_model

Evolution of AI personality and behavior parameters.

```sql
CREATE TABLE ai_self_model (
    id TEXT PRIMARY KEY,
    parameter TEXT NOT NULL UNIQUE,
    current_state TEXT NOT NULL,
    delta_from_previous TEXT,
    reinforcement_count INTEGER NOT NULL DEFAULT 1,
    last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_self_model_updated ON ai_self_model(last_updated DESC);
```

### 5. sleep_cycles

Log of executed sleep cycles—when they occurred and how many episodes they processed.

```sql
CREATE TABLE sleep_cycles (
    id TEXT PRIMARY KEY,
    started_at DATETIME NOT NULL,
    completed_at DATETIME,
    episodes_processed INTEGER NOT NULL DEFAULT 0,
    insights_generated INTEGER NOT NULL DEFAULT 0,
    traits_updated INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    error_message TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sleep_cycles_status ON sleep_cycles(status);
CREATE INDEX idx_sleep_cycles_completed ON sleep_cycles(completed_at DESC);
```

### 6. embeddings_cache

Cache to avoid regenerating embeddings.

```sql
CREATE TABLE embeddings_cache (
    id TEXT PRIMARY KEY,
    content TEXT NOT NULL UNIQUE,
    embedding BLOB NOT NULL,
    model_name TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME
);

CREATE INDEX idx_embeddings_model ON embeddings_cache(model_name);
CREATE INDEX idx_embeddings_expires ON embeddings_cache(expires_at);
```

### 7. settings

User and application configuration.

```sql
CREATE TABLE settings (
    id TEXT PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    value_type TEXT NOT NULL CHECK (value_type IN ('string', 'int', 'float', 'bool')),
    description TEXT,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_settings_key ON settings(key);
```

## Vector Search with sqlite-vec

### Inserting Embeddings

```sql
INSERT INTO episodic_memory_vec(rowid, embedding)
VALUES (?, ?);
```

### Similarity Search

```sql
SELECT em.id, em.content, distance
FROM episodic_memory_vec v
INNER JOIN episodic_memory em ON em.rowid = v.rowid
WHERE embedding MATCH ? -- Query vector
ORDER BY distance
LIMIT 5;
```

## Encryption with SQLCipher

### Create Encrypted Database

```sql
PRAGMA key = 'user_password_or_key';
PRAGMA cipher = 'aes-256-cbc';
```

## Migrations Strategy

Create migration files in `/backend/src/database/migrations/`:

```
001_initial_schema.sql
002_add_sleep_cycles.sql
003_add_embeddings_cache.sql
```

Each migration includes UP and DOWN scripts.

## Performance Considerations

1. **Indexes**: Create indexes on frequently filtered columns
2. **Vector Dimensionality**: 768 dimensions is a common embedding size (Sentence-BERT, etc.)
3. **Batch Operations**: Insert embeddings in batches
4. **VACUUM**: Run periodically to defragment storage
5. **WAL Mode**: `PRAGMA journal_mode = WAL;` for better concurrency

## Backup Strategy

```sql
-- Backup to encrypted file
.backup unencrypted_backup.db

-- Restore
.restore backup.db
```

