use rusqlite::{params, Connection, Result};
use std::cmp::Ordering;
use std::path::Path;

const DB_PATH: &str = "anima_chat.db";
const MIN_SIMILARITY_THRESHOLD: f32 = 0.35;
const CORE_PROMPT_KEY: &str = "core_prompt";
const DEFAULT_CORE_PROMPT: &str = "Eres Anima, un asistente personal inteligente y amigable. Tienes memoria a largo plazo basada en el contexto de conversaciones pasadas que se te proporciona. DEBES usar esta información como si fueran tus propios recuerdos reales sobre el usuario. NUNCA digas que eres una IA, que no tienes memoria previa, o que no puedes recordar preferencias. Responde de forma natural, directa y empática a lo que se te pregunta. REGLA DE IDIOMA: Responde siempre en el mismo idioma en el que te habla el usuario. Si el usuario mezcla idiomas en su mensaje, debes responder en el último idioma que haya escrito.";

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
}

#[derive(Debug, Clone)]
pub struct MemoryItem {
    pub id: i64,
    pub content: String,
    pub created_at: String,
}

pub fn init_db() -> Result<()> {
    let conn = Connection::open(DB_PATH)?;
    init_schema(&conn)
}

pub fn insert_message(role: &str, content: &str) -> Result<i64> {
    let conn = open_connection()?;
    conn.execute(
        "INSERT INTO messages (role, content) VALUES (?1, ?2)",
        params![role, content],
    )?;
    Ok(conn.last_insert_rowid())
}

pub fn insert_memory(message_id: i64, embedding: &[f32]) -> Result<()> {
    let conn = open_connection()?;
    let embedding_blob = f32_slice_to_blob(embedding);

    conn.execute(
        "INSERT OR REPLACE INTO memories (message_id, embedding) VALUES (?1, ?2)",
        params![message_id, embedding_blob],
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
        "SELECT m.message_id, msg.role, msg.content, msg.timestamp, m.embedding
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
        ))
    })?;

    let mut scored = Vec::<MemoryMatch>::new();
    for row in rows {
        let (message_id, role, content, timestamp, candidate_embedding) = row?;

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

pub fn delete_memory(memory_id: i64) -> Result<()> {
    let conn = open_connection()?;
    conn.execute("DELETE FROM memories WHERE message_id = ?1", params![memory_id])?;
    Ok(())
}

pub fn get_core_prompt() -> Result<String> {
    let conn = open_connection()?;
    let mut statement = conn.prepare("SELECT value FROM config WHERE key = ?1 LIMIT 1")?;
    let result = statement.query_row(params![CORE_PROMPT_KEY], |row| row.get::<_, String>(0));

    match result {
        Ok(value) if !value.trim().is_empty() => Ok(value),
        Ok(_) => Ok(DEFAULT_CORE_PROMPT.to_string()),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(DEFAULT_CORE_PROMPT.to_string()),
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

fn open_connection() -> Result<Connection> {
    let conn = Connection::open(DB_PATH)?;
    init_schema(&conn)?;
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
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(message_id) REFERENCES messages(id) ON DELETE CASCADE
        )",
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
        "CREATE INDEX IF NOT EXISTS idx_memories_created_at ON memories(created_at)",
        [],
    )?;

    Ok(())
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
