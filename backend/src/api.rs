use crate::database::DatabaseManager;
use crate::models::memory::{ChatRole, EpisodicMemory};
use std::path::Path;

#[derive(Debug, Clone)]
pub struct EpisodicMemoryDto {
    pub id: String,
    pub timestamp: String,
    pub role: String,
    pub content: String,
    pub processed: bool,
}

fn open_db() -> Result<DatabaseManager, String> {
    let db_path = Path::new("anima.db");
    let password = "default_password";
    DatabaseManager::new(db_path, password).map_err(|e| e.to_string())
}

#[flutter_rust_bridge::frb]
pub fn save_user_message(content: String) -> Result<String, String> {
    let db = open_db()?;
    let memory = EpisodicMemory::new(ChatRole::User, content, Vec::new());

    db.insert_episodic_memory(&memory)
        .map_err(|e| e.to_string())?;

    Ok(memory.id)
}

#[flutter_rust_bridge::frb]
pub fn get_recent_memories(limit: u32) -> Result<Vec<EpisodicMemoryDto>, String> {
    let db = open_db()?;
    let memories = db.get_recent_memories(limit).map_err(|e| e.to_string())?;

    let result = memories
        .into_iter()
        .map(|memory| EpisodicMemoryDto {
            id: memory.id,
            timestamp: memory.timestamp.to_rfc3339(),
            role: memory.role.to_string(),
            content: memory.content,
            processed: memory.processed,
        })
        .collect();

    Ok(result)
}
