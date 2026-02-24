use rusqlite::{params, Connection, Result};

const DB_PATH: &str = "anima_chat.db";

#[derive(Debug, Clone)]
pub struct ChatMessage {
    pub id: i64,
    pub role: String,
    pub content: String,
    pub timestamp: String,
}

pub fn init_db() -> Result<()> {
    let conn = Connection::open(DB_PATH)?;
    init_schema(&conn)
}

pub fn insert_message(role: &str, content: &str) -> Result<()> {
    let conn = open_connection()?;
    conn.execute(
        "INSERT INTO messages (role, content) VALUES (?1, ?2)",
        params![role, content],
    )?;
    Ok(())
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

    Ok(())
}
