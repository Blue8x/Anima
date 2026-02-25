# Database Schema - Anima

## Overview

Anima’s current database is implemented in `frontend/rust/src/db.rs` and uses local SQLite.

## Current Tables

## 1) `messages`

Stores chat history.

```sql
CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    timestamp TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

## 2) `memories`

Associates each message with its embedding for semantic retrieval.

```sql
CREATE TABLE IF NOT EXISTS memories (
    message_id INTEGER PRIMARY KEY,
    embedding BLOB NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(message_id) REFERENCES messages(id) ON DELETE CASCADE
);
```

## 3) `config`

Simple global key/value configuration.

```sql
CREATE TABLE IF NOT EXISTS config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL DEFAULT ''
);
```

Keys currently used:
- `user_name`
- `core_prompt`
- `app_language`

## 4) `profile_traits`

Consolidated cognitive profile traits by category.

```sql
CREATE TABLE IF NOT EXISTS profile_traits (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

## Current Indexes

```sql
CREATE INDEX IF NOT EXISTS idx_profile_traits_category ON profile_traits(category);
CREATE INDEX IF NOT EXISTS idx_memories_created_at ON memories(created_at);
```

## Important Operations

### Factory reset

Deletes cognitive/config state in a transaction:

```sql
DELETE FROM memories;
DELETE FROM profile_traits;
DELETE FROM config;
```

### Database export

Uses `VACUUM INTO 'path'` to export a consistent copy.

## Technical Notes

- Embeddings are stored as little-endian `f32` `BLOB`s.
- Similarity search is computed in Rust (cosine), not through a SQL vector extension.
- Schema is initialized automatically when opening a connection (`init_schema`).

---

Last updated: February 25, 2026

