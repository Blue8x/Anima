use chrono::Utc;
use rusqlite::{params, Connection, Result, TransactionBehavior};
use std::cmp::Ordering;
use std::path::Path;
use std::sync::OnceLock;
use std::thread::sleep;
use std::time::Duration;

const DB_PATH: &str = "anima_chat.db";
const MIN_SIMILARITY_THRESHOLD: f32 = 0.35;
const CORE_PROMPT_KEY: &str = "core_prompt";
const USER_NAME_KEY: &str = "user_name";
const APP_LANGUAGE_KEY: &str = "app_language";
const TEMPERATURE_KEY: &str = "temperature";
const DEFAULT_APP_LANGUAGE: &str = "Español";
const DEFAULT_TEMPERATURE: f32 = 0.7;
static SCHEMA_INITIALIZED: OnceLock<()> = OnceLock::new();

#[derive(Debug, Clone)]
pub struct ChatMessage {
    pub id: i64,
    pub role: String,
    pub content: String,
    pub timestamp: String,
}

#[derive(Debug, Clone)]
pub struct MemoryMatch {
    pub message_id: i64,
    pub role: String,
    pub content: String,
    pub similarity: f32,
    pub timestamp: String,
    pub memory_type: String,
    pub memory_unix_timestamp: i64,
}

#[derive(Debug, Clone)]
pub struct MemoryItem {
    pub id: i64,
    pub content: String,
    pub created_at: String,
}

#[derive(Debug, Clone)]
pub struct ProfileTrait {
    pub category: String,
    pub content: String,
}

pub fn init_db() -> Result<()> {
    let conn = Connection::open(DB_PATH)?;
    init_schema(&conn)?;
    let _ = SCHEMA_INITIALIZED.set(());
    Ok(())
}

pub fn insert_message(role: &str, content: &str) -> Result<i64> {
    let conn = open_connection()?;
    conn.execute(
        "INSERT INTO messages (role, content) VALUES (?1, ?2)",
        params![role, content],
    )?;
    Ok(conn.last_insert_rowid())
}

pub fn current_unix_timestamp() -> i64 {
    Utc::now().timestamp()
}

pub fn insert_memory(
    message_id: i64,
    embedding: &[f32],
    memory_type: &str,
    unix_timestamp: i64,
) -> Result<()> {
    let conn = open_connection()?;
    let embedding_blob = f32_slice_to_blob(embedding);
    let normalized_type = normalize_memory_type(memory_type);

    conn.execute(
        "INSERT OR REPLACE INTO memories (message_id, embedding, memory_type, timestamp) VALUES (?1, ?2, ?3, ?4)",
        params![message_id, embedding_blob, normalized_type, unix_timestamp],
    )?;

    Ok(())
}

pub fn find_top_similar_memories(
    query_embedding: &[f32],
    limit: usize,
    exclude_message_id: Option<i64>,
) -> Result<Vec<MemoryMatch>> {
    if query_embedding.is_empty() || limit == 0 {
        return Ok(Vec::new());
    }

    let conn = open_connection()?;
    let mut statement = conn.prepare(
        "SELECT m.message_id, msg.role, msg.content, msg.timestamp, m.embedding, m.memory_type, m.timestamp
         FROM memories m
         JOIN messages msg ON msg.id = m.message_id",
    )?;

    let rows = statement.query_map([], |row| {
        let embedding_blob: Vec<u8> = row.get(4)?;
        let embedding = blob_to_f32_vec(&embedding_blob);

        Ok((
            row.get::<_, i64>(0)?,
            row.get::<_, String>(1)?,
            row.get::<_, String>(2)?,
            row.get::<_, String>(3)?,
            embedding,
            row.get::<_, String>(5)?,
            row.get::<_, i64>(6)?,
        ))
    })?;

    let mut scored = Vec::<MemoryMatch>::new();
    for row in rows {
        let (message_id, role, content, timestamp, candidate_embedding, memory_type, memory_unix_timestamp) =
            row?;

        if exclude_message_id.is_some_and(|excluded| excluded == message_id) {
            continue;
        }

        let similarity = cosine_similarity(query_embedding, &candidate_embedding);
        if similarity.is_finite() && similarity >= MIN_SIMILARITY_THRESHOLD {
            scored.push(MemoryMatch {
                message_id,
                role,
                content,
                similarity,
                timestamp,
                memory_type,
                memory_unix_timestamp,
            });
        }
    }

    scored.sort_by(|a, b| {
        b.similarity
            .partial_cmp(&a.similarity)
            .unwrap_or(Ordering::Equal)
    });
    scored.truncate(limit);
    Ok(scored)
}

pub fn cosine_similarity(query: &[f32], candidate: &[f32]) -> f32 {
    let dimensions = query.len().min(candidate.len());
    if dimensions == 0 {
        return 0.0;
    }

    let mut dot_product = 0.0_f32;
    let mut query_norm_sq = 0.0_f32;
    let mut candidate_norm_sq = 0.0_f32;

    for index in 0..dimensions {
        let q = query[index];
        let c = candidate[index];
        dot_product += q * c;
        query_norm_sq += q * q;
        candidate_norm_sq += c * c;
    }

    if query_norm_sq <= f32::EPSILON || candidate_norm_sq <= f32::EPSILON {
        return 0.0;
    }

    dot_product / (query_norm_sq.sqrt() * candidate_norm_sq.sqrt())
}

pub fn get_all_messages() -> Result<Vec<ChatMessage>> {
    let conn = open_connection()?;
    let mut statement = conn.prepare(
        "SELECT id, role, content, timestamp FROM messages ORDER BY datetime(timestamp) ASC, id ASC",
    )?;

    let rows = statement.query_map([], |row| {
        Ok(ChatMessage {
            id: row.get(0)?,
            role: row.get(1)?,
            content: row.get(2)?,
            timestamp: row.get(3)?,
        })
    })?;

    rows.collect()
}

pub fn get_all_memories() -> Result<Vec<MemoryItem>> {
    let conn = open_connection()?;
    let mut statement = conn.prepare(
        "SELECT msg.id, msg.content, mem.created_at
         FROM memories mem
         JOIN messages msg ON msg.id = mem.message_id
         ORDER BY datetime(mem.created_at) DESC, mem.message_id DESC",
    )?;

    let rows = statement.query_map([], |row| {
        Ok(MemoryItem {
            id: row.get(0)?,
            content: row.get(1)?,
            created_at: row.get(2)?,
        })
    })?;

    rows.collect()
}

pub fn search_memories(query: &str) -> Result<Vec<MemoryItem>> {
    let conn = open_connection()?;
    let normalized_query = query.trim();

    let mut statement = conn.prepare(
        "SELECT msg.id, msg.content, mem.created_at
         FROM memories mem
         JOIN messages msg ON msg.id = mem.message_id
         WHERE (?1 = '')
            OR msg.content LIKE '%' || ?1 || '%'
            OR mem.created_at LIKE '%' || ?1 || '%'
            OR CAST(mem.timestamp AS TEXT) LIKE '%' || ?1 || '%'
         ORDER BY mem.timestamp DESC, mem.message_id DESC",
    )?;

    let rows = statement.query_map(params![normalized_query], |row| {
        Ok(MemoryItem {
            id: row.get(0)?,
            content: row.get(1)?,
            created_at: row.get(2)?,
        })
    })?;

    rows.collect()
}

pub fn delete_memory(memory_id: i64) -> Result<()> {
    let conn = open_connection()?;
    conn.execute("DELETE FROM memories WHERE message_id = ?1", params![memory_id])?;
    Ok(())
}

pub fn clear_all_raw_memories() -> std::result::Result<bool, String> {
    let conn = open_connection().map_err(|error| format!("DB open failed: {error}"))?;
    conn.execute("DELETE FROM memories", [])
        .map_err(|error| format!("Raw memory purge failed: {error}"))?;
    Ok(true)
}

pub fn get_core_prompt() -> Result<String> {
    let conn = open_connection()?;
    let mut statement = conn.prepare("SELECT value FROM config WHERE key = ?1 LIMIT 1")?;
    let result = statement.query_row(params![CORE_PROMPT_KEY], |row| row.get::<_, String>(0));

    match result {
        Ok(value) => Ok(value),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(String::new()),
        Err(error) => Err(error),
    }
}

pub fn set_core_prompt(prompt: &str) -> Result<()> {
    let conn = open_connection()?;
    conn.execute(
        "INSERT INTO config(key, value)
         VALUES (?1, ?2)
         ON CONFLICT(key) DO UPDATE SET value = excluded.value",
        params![CORE_PROMPT_KEY, prompt],
    )?;
    Ok(())
}

pub fn get_user_name() -> Result<String> {
    let conn = open_connection()?;
    let mut statement = conn.prepare("SELECT value FROM config WHERE key = ?1 LIMIT 1")?;
    let result = statement.query_row(params![USER_NAME_KEY], |row| row.get::<_, String>(0));

    match result {
        Ok(value) => Ok(value),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(String::new()),
        Err(error) => Err(error),
    }
}

pub fn set_user_name(name: &str) -> Result<()> {
    let conn = open_connection()?;
    conn.execute(
        "INSERT INTO config(key, value)
         VALUES (?1, ?2)
         ON CONFLICT(key) DO UPDATE SET value = excluded.value",
        params![USER_NAME_KEY, name],
    )?;
    Ok(())
}

pub fn get_app_language() -> Result<String> {
    let conn = open_connection()?;
    let mut statement = conn.prepare("SELECT value FROM config WHERE key = ?1 LIMIT 1")?;
    let result = statement.query_row(params![APP_LANGUAGE_KEY], |row| row.get::<_, String>(0));

    match result {
        Ok(value) if !value.trim().is_empty() => Ok(value),
        Ok(_) => Ok(DEFAULT_APP_LANGUAGE.to_string()),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(DEFAULT_APP_LANGUAGE.to_string()),
        Err(error) => Err(error),
    }
}

pub fn set_app_language(lang: &str) -> Result<()> {
    let conn = open_connection()?;
    conn.execute(
        "INSERT INTO config(key, value)
         VALUES (?1, ?2)
         ON CONFLICT(key) DO UPDATE SET value = excluded.value",
        params![APP_LANGUAGE_KEY, lang],
    )?;
    Ok(())
}

pub fn get_temperature() -> Result<f32> {
    let conn = open_connection()?;
    let mut statement = conn.prepare("SELECT value FROM config WHERE key = ?1 LIMIT 1")?;
    let result = statement.query_row(params![TEMPERATURE_KEY], |row| row.get::<_, String>(0));

    match result {
        Ok(value) => Ok(parse_temperature(&value).unwrap_or(DEFAULT_TEMPERATURE)),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(DEFAULT_TEMPERATURE),
        Err(error) => Err(error),
    }
}

pub fn set_temperature(temperature: f32) -> Result<()> {
    let conn = open_connection()?;
    let sanitized = temperature.clamp(0.1, 1.0);
    conn.execute(
        "INSERT INTO config(key, value)
         VALUES (?1, ?2)
         ON CONFLICT(key) DO UPDATE SET value = excluded.value",
        params![TEMPERATURE_KEY, format!("{sanitized:.3}")],
    )?;
    Ok(())
}

pub fn clear_profile() -> Result<()> {
    let conn = open_connection()?;
    conn.execute("DELETE FROM profile_traits", [])?;
    Ok(())
}

pub fn add_profile_trait(category: &str, content: &str) -> Result<()> {
    let conn = open_connection()?;
    conn.execute(
        "INSERT INTO profile_traits (category, content) VALUES (?1, ?2)",
        params![category, content],
    )?;
    Ok(())
}

pub fn get_profile_traits() -> Result<Vec<ProfileTrait>> {
    let conn = open_connection()?;
    let mut statement = conn.prepare(
        "SELECT category, content
         FROM profile_traits
         ORDER BY datetime(created_at) ASC, id ASC",
    )?;

    let rows = statement.query_map([], |row| {
        Ok(ProfileTrait {
            category: row.get(0)?,
            content: row.get(1)?,
        })
    })?;

    rows.collect()
}

pub fn export_database(dest_path: &str) -> Result<bool> {
    let destination = Path::new(dest_path);
    if let Some(parent) = destination.parent() {
        if !parent.as_os_str().is_empty() && !parent.exists() {
            return Err(rusqlite::Error::InvalidPath(parent.to_path_buf()));
        }
    }

    if destination.exists() {
        std::fs::remove_file(destination)
            .map_err(|_| rusqlite::Error::InvalidPath(destination.to_path_buf()))?;
    }

    let conn = open_connection()?;
    conn.execute_batch("PRAGMA wal_checkpoint(FULL);")?;

    let escaped_path = dest_path.replace('\'', "''");
    let vacuum_query = format!("VACUUM INTO '{}';", escaped_path);
    conn.execute_batch(&vacuum_query)?;

    Ok(destination.exists())
}

pub fn factory_reset() -> std::result::Result<bool, String> {
    let mut last_error = String::new();

    for attempt in 0..3 {
        match factory_reset_once() {
            Ok(done) => return Ok(done),
            Err(error) => {
                let locked = error.contains("database is locked")
                    || error.contains("database table is locked")
                    || error.contains("SQLITE_BUSY")
                    || error.contains("SQLITE_LOCKED");

                if locked && attempt < 2 {
                    sleep(Duration::from_millis(250 * (attempt + 1) as u64));
                    last_error = error;
                    continue;
                }

                return Err(error);
            }
        }
    }

    Err(if last_error.is_empty() {
        "Factory reset failed after retries".to_string()
    } else {
        last_error
    })
}

fn factory_reset_once() -> std::result::Result<bool, String> {
    let mut conn = open_connection().map_err(|error| format!("DB open failed: {error}"))?;
    let transaction = conn
        .transaction_with_behavior(TransactionBehavior::Immediate)
        .map_err(|error| format!("DB transaction start failed: {error}"))?;

    transaction
        .execute("DELETE FROM memories", [])
        .map_err(|error| format!("Factory reset failed clearing memories: {error}"))?;
    transaction
        .execute("DELETE FROM profile_traits", [])
        .map_err(|error| format!("Factory reset failed clearing profile_traits: {error}"))?;
    transaction
        .execute("DELETE FROM config", [])
        .map_err(|error| format!("Factory reset failed clearing config: {error}"))?;
    transaction
        .execute("DELETE FROM messages", [])
        .map_err(|error| format!("Factory reset failed clearing messages: {error}"))?;

    match transaction.execute("DELETE FROM sqlite_sequence", []) {
        Ok(_) => {}
        Err(rusqlite::Error::SqliteFailure(_, Some(message)))
            if message.contains("no such table: sqlite_sequence") => {}
        Err(error) => {
            return Err(format!(
                "Factory reset failed resetting sqlite sequences: {error}"
            ));
        }
    }

    transaction
        .commit()
        .map_err(|error| format!("Factory reset commit failed: {error}"))?;

    Ok(true)
}

fn open_connection() -> Result<Connection> {
    let conn = Connection::open(DB_PATH)?;
    conn.busy_timeout(Duration::from_secs(8))?;
    conn.pragma_update(None, "foreign_keys", "ON")?;

    if SCHEMA_INITIALIZED.get().is_none() {
        init_schema(&conn)?;
        let _ = SCHEMA_INITIALIZED.set(());
    }

    Ok(conn)
}

fn init_schema(conn: &Connection) -> Result<()> {
    conn.execute(
        "CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )",
        [],
    )?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS memories (
            message_id INTEGER PRIMARY KEY,
            embedding BLOB NOT NULL,
            memory_type TEXT NOT NULL DEFAULT 'episodic' CHECK(memory_type IN ('semantic','episodic')),
            timestamp INTEGER NOT NULL DEFAULT (strftime('%s','now')),
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(message_id) REFERENCES messages(id) ON DELETE CASCADE
        )",
        [],
    )?;

    if !table_has_column(conn, "memories", "memory_type")? {
        conn.execute(
            "ALTER TABLE memories ADD COLUMN memory_type TEXT NOT NULL DEFAULT 'episodic' CHECK(memory_type IN ('semantic','episodic'))",
            [],
        )?;
    }

    if !table_has_column(conn, "memories", "timestamp")? {
        conn.execute(
            "ALTER TABLE memories ADD COLUMN timestamp INTEGER NOT NULL DEFAULT (strftime('%s','now'))",
            [],
        )?;
    }

    conn.execute(
        "UPDATE memories
         SET memory_type = CASE
             WHEN lower(trim(memory_type)) = 'semantic' THEN 'semantic'
             ELSE 'episodic'
         END",
        [],
    )?;

    conn.execute(
        "UPDATE memories
         SET timestamp = strftime('%s', COALESCE(created_at, CURRENT_TIMESTAMP))
         WHERE timestamp IS NULL OR timestamp <= 0",
        [],
    )?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS config (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL DEFAULT ''
        )",
        [],
    )?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS profile_traits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )",
        [],
    )?;

    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_profile_traits_category ON profile_traits(category)",
        [],
    )?;

    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_memories_created_at ON memories(created_at)",
        [],
    )?;

    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_memories_type_timestamp ON memories(memory_type, timestamp DESC)",
        [],
    )?;

    conn.execute(
        "INSERT OR IGNORE INTO config (key, value) VALUES (?1, ?2)",
        params![TEMPERATURE_KEY, DEFAULT_TEMPERATURE.to_string()],
    )?;

    Ok(())
}

fn parse_temperature(value: &str) -> Option<f32> {
    let parsed = value.trim().parse::<f32>().ok()?;
    if parsed.is_finite() {
        Some(parsed.clamp(0.1, 1.0))
    } else {
        None
    }
}

fn normalize_memory_type(memory_type: &str) -> &'static str {
    if memory_type.trim().eq_ignore_ascii_case("semantic") {
        "semantic"
    } else {
        "episodic"
    }
}

fn table_has_column(conn: &Connection, table: &str, column: &str) -> Result<bool> {
    let pragma = format!("PRAGMA table_info({table})");
    let mut statement = conn.prepare(&pragma)?;
    let mut rows = statement.query([])?;

    while let Some(row) = rows.next()? {
        let name: String = row.get(1)?;
        if name.eq_ignore_ascii_case(column) {
            return Ok(true);
        }
    }

    Ok(false)
}

fn f32_slice_to_blob(vector: &[f32]) -> Vec<u8> {
    let mut bytes = Vec::with_capacity(vector.len() * std::mem::size_of::<f32>());
    for value in vector {
        bytes.extend_from_slice(&value.to_le_bytes());
    }
    bytes
}

fn blob_to_f32_vec(blob: &[u8]) -> Vec<f32> {
    blob.chunks_exact(4)
        .map(|chunk| f32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]))
        .collect()
}
