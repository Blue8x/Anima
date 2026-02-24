// Database manager for Anima - SQLite with encryption

use crate::models::memory::*;
use chrono::{DateTime, Utc};
use rusqlite::{params, Connection, OptionalExtension, Result as SqlResult};
use std::path::Path;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum DbError {
    #[error("Database error: {0}")]
    SqliteError(#[from] rusqlite::Error),
    #[error("Serialization error: {0}")]
    SerializationError(#[from] serde_json::error::Error),
    #[error("Not found")]
    NotFound,
    #[error("Invalid argument: {0}")]
    InvalidArgument(String),
}

pub type DbResult<T> = Result<T, DbError>;

pub struct DatabaseManager {
    conn: Connection,
}

impl DatabaseManager {
    /// Open or create a database with encryption
    pub fn new(db_path: &Path, password: &str) -> DbResult<Self> {
        let conn = Connection::open(db_path)?;
        
        // Enable encryption with SQLCipher
        conn.pragma_update(None, "key", password)?;
        conn.pragma_update(None, "cipher", "aes-256-cbc")?;
        
        // Enable foreign keys
        conn.execute("PRAGMA foreign_keys = ON", [])?;
        
        // Enable WAL mode for better concurrency
        conn.execute("PRAGMA journal_mode = WAL", [])?;
        
        let manager = Self { conn };
        
        // Initialize schema on first run
        manager.init_schema()?;
        
        Ok(manager)
    }

    /// Initialize database schema
    fn init_schema(&self) -> DbResult<()> {
        // Episodic Memory Table
        self.conn.execute(
            r#"
            CREATE TABLE IF NOT EXISTS episodic_memory (
                id TEXT PRIMARY KEY,
                timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                role TEXT NOT NULL CHECK (role IN ('user', 'ai')),
                content TEXT NOT NULL,
                embedding BLOB NOT NULL,
                processed BOOLEAN NOT NULL DEFAULT FALSE,
                metadata JSON,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            "#,
            [],
        )?;

        self.conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_episodic_timestamp ON episodic_memory(timestamp)",
            [],
        )?;
        self.conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_episodic_processed ON episodic_memory(processed)",
            [],
        )?;

        // Semantic Memory Table
        self.conn.execute(
            r#"
            CREATE TABLE IF NOT EXISTS semantic_memory (
                id TEXT PRIMARY KEY,
                topic TEXT NOT NULL,
                insight TEXT NOT NULL,
                importance_score INTEGER NOT NULL CHECK (importance_score >= 1 AND importance_score <= 10),
                embedding BLOB NOT NULL,
                source_episodes TEXT,
                confidence_score REAL NOT NULL DEFAULT 0.5,
                last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            "#,
            [],
        )?;

        self.conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_semantic_topic ON semantic_memory(topic)",
            [],
        )?;

        // User Identity Table
        self.conn.execute(
            r#"
            CREATE TABLE IF NOT EXISTS user_identity (
                id TEXT PRIMARY KEY,
                trait_name TEXT NOT NULL,
                value TEXT NOT NULL,
                confidence_score INTEGER NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 100),
                category TEXT NOT NULL,
                evidence_count INTEGER NOT NULL DEFAULT 1,
                last_reinforced DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(trait_name, category)
            )
            "#,
            [],
        )?;

        self.conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_identity_category ON user_identity(category)",
            [],
        )?;

        // AI Self Model Table
        self.conn.execute(
            r#"
            CREATE TABLE IF NOT EXISTS ai_self_model (
                id TEXT PRIMARY KEY,
                parameter TEXT NOT NULL UNIQUE,
                current_state TEXT NOT NULL,
                delta_from_previous TEXT,
                reinforcement_count INTEGER NOT NULL DEFAULT 1,
                last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            "#,
            [],
        )?;

        // Sleep Cycles Table
        self.conn.execute(
            r#"
            CREATE TABLE IF NOT EXISTS sleep_cycles (
                id TEXT PRIMARY KEY,
                started_at DATETIME NOT NULL,
                completed_at DATETIME,
                episodes_processed INTEGER NOT NULL DEFAULT 0,
                insights_generated INTEGER NOT NULL DEFAULT 0,
                traits_updated INTEGER NOT NULL DEFAULT 0,
                status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
                error_message TEXT,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            "#,
            [],
        )?;

        self.conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_sleep_cycles_status ON sleep_cycles(status)",
            [],
        )?;

        // Settings Table
        self.conn.execute(
            r#"
            CREATE TABLE IF NOT EXISTS settings (
                id TEXT PRIMARY KEY,
                key TEXT NOT NULL UNIQUE,
                value TEXT NOT NULL,
                value_type TEXT NOT NULL CHECK (value_type IN ('string', 'int', 'float', 'bool')),
                description TEXT,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            "#,
            [],
        )?;

        Ok(())
    }

    // ===== Episodic Memory Operations =====

    pub fn insert_episodic_memory(&self, memory: &EpisodicMemory) -> DbResult<()> {
        let embedding_bytes = self.embed_to_bytes(&memory.embedding);
        let metadata_json = memory.metadata.as_ref().map(|m| m.to_string());
        let timestamp = memory.timestamp.to_rfc3339();

        self.conn.execute(
            r#"
            INSERT INTO episodic_memory (
                id, timestamp, role, content, embedding, processed, metadata
            ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
            "#,
            params![
                memory.id,
                timestamp,
                memory.role.to_string(),
                memory.content,
                embedding_bytes,
                memory.processed,
                metadata_json,
            ],
        )?;

        Ok(())
    }

    pub fn get_episodic_memory(&self, id: &str) -> DbResult<Option<EpisodicMemory>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, timestamp, role, content, embedding, processed, metadata FROM episodic_memory WHERE id = ?1"
        )?;

        let result = stmt.query_row(params![id], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
                row.get::<_, String>(3)?,
                row.get::<_, Vec<u8>>(4)?,
                row.get::<_, bool>(5)?,
                row.get::<_, Option<String>>(6)?,
            ))
        }).optional()?;

        let Some((id, timestamp, role, content, embedding_bytes, processed, metadata)) = result else {
            return Ok(None);
        };

        let timestamp: DateTime<Utc> = DateTime::parse_from_rfc3339(&timestamp)
            .map(|dt| dt.with_timezone(&Utc))
            .map_err(|_| DbError::InvalidArgument("Invalid timestamp".to_string()))?;

        let role = match role.as_str() {
            "user" => ChatRole::User,
            "ai" => ChatRole::Ai,
            _ => return Err(DbError::InvalidArgument("Invalid role".to_string())),
        };

        let embedding = self.bytes_to_embed(&embedding_bytes);
        let metadata = metadata.map(|m| serde_json::from_str(&m)).transpose()?;

        Ok(Some(EpisodicMemory {
            id,
            timestamp,
            role,
            content,
            embedding,
            processed,
            metadata,
        }))
    }

    pub fn get_unprocessed_episodes(&self, limit: u32) -> DbResult<Vec<EpisodicMemory>> {
        let mut stmt = self.conn.prepare(
            r#"
            SELECT id, timestamp, role, content, embedding, processed, metadata 
            FROM episodic_memory 
            WHERE processed = FALSE
            ORDER BY timestamp DESC
            LIMIT ?1
            "#
        )?;

        let memories = stmt.query_map(params![limit], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
                row.get::<_, String>(3)?,
                row.get::<_, Vec<u8>>(4)?,
                row.get::<_, bool>(5)?,
                row.get::<_, Option<String>>(6)?,
            ))
        })?;

        let mut result = Vec::new();
        for memory in memories {
            let (id, timestamp, role, content, embedding_bytes, processed, metadata) = memory?;
            
            let timestamp: DateTime<Utc> = DateTime::parse_from_rfc3339(&timestamp)
                .map(|dt| dt.with_timezone(&Utc))
                .map_err(|_| DbError::InvalidArgument("Invalid timestamp".to_string()))?;

            let role = match role.as_str() {
                "user" => ChatRole::User,
                "ai" => ChatRole::Ai,
                _ => return Err(DbError::InvalidArgument("Invalid role".to_string())),
            };

            let embedding = self.bytes_to_embed(&embedding_bytes);
            let metadata = metadata.map(|m| serde_json::from_str(&m)).transpose()?;

            result.push(EpisodicMemory {
                id,
                timestamp,
                role,
                content,
                embedding,
                processed,
                metadata,
            });
        }

        Ok(result)
    }

    pub fn get_recent_memories(&self, limit: u32) -> DbResult<Vec<EpisodicMemory>> {
        let mut stmt = self.conn.prepare(
            r#"
            SELECT id, timestamp, role, content, embedding, processed, metadata
            FROM episodic_memory
            ORDER BY timestamp DESC
            LIMIT ?1
            "#
        )?;

        let memories = stmt.query_map(params![limit], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
                row.get::<_, String>(3)?,
                row.get::<_, Vec<u8>>(4)?,
                row.get::<_, bool>(5)?,
                row.get::<_, Option<String>>(6)?,
            ))
        })?;

        let mut result = Vec::new();
        for memory in memories {
            let (id, timestamp, role, content, embedding_bytes, processed, metadata) = memory?;

            let timestamp: DateTime<Utc> = DateTime::parse_from_rfc3339(&timestamp)
                .map(|dt| dt.with_timezone(&Utc))
                .map_err(|_| DbError::InvalidArgument("Invalid timestamp".to_string()))?;

            let role = match role.as_str() {
                "user" => ChatRole::User,
                "ai" => ChatRole::Ai,
                _ => return Err(DbError::InvalidArgument("Invalid role".to_string())),
            };

            let embedding = self.bytes_to_embed(&embedding_bytes);
            let metadata = metadata.map(|m| serde_json::from_str(&m)).transpose()?;

            result.push(EpisodicMemory {
                id,
                timestamp,
                role,
                content,
                embedding,
                processed,
                metadata,
            });
        }

        Ok(result)
    }

    pub fn mark_episodes_processed(&self, ids: &[String]) -> DbResult<u32> {
        let mut count = 0;
        for id in ids {
            let updated = self.conn.execute(
                "UPDATE episodic_memory SET processed = TRUE WHERE id = ?1",
                params![id],
            )?;
            count += updated as u32;
        }
        Ok(count)
    }

    // ===== Semantic Memory Operations =====

    pub fn insert_semantic_memory(&self, memory: &SemanticMemory) -> DbResult<()> {
        let embedding_bytes = self.embed_to_bytes(&memory.embedding);
        let source_episodes = serde_json::to_string(&memory.source_episodes)?;
        let last_updated = memory.last_updated.to_rfc3339();

        self.conn.execute(
            r#"
            INSERT INTO semantic_memory (
                id, topic, insight, importance_score, embedding, source_episodes, confidence_score, last_updated
            ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
            "#,
            params![
                memory.id,
                memory.topic,
                memory.insight,
                memory.importance_score,
                embedding_bytes,
                source_episodes,
                memory.confidence_score,
                last_updated,
            ],
        )?;

        Ok(())
    }

    pub fn get_semantic_memory_by_topic(&self, topic: &str, limit: u32) -> DbResult<Vec<SemanticMemory>> {
        let mut stmt = self.conn.prepare(
            r#"
            SELECT id, topic, insight, importance_score, embedding, source_episodes, confidence_score, last_updated
            FROM semantic_memory
            WHERE topic = ?1
            ORDER BY importance_score DESC, confidence_score DESC
            LIMIT ?2
            "#
        )?;

        let memories = stmt.query_map(params![topic, limit], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
                row.get::<_, u8>(3)?,
                row.get::<_, Vec<u8>>(4)?,
                row.get::<_, String>(5)?,
                row.get::<_, f32>(6)?,
                row.get::<_, String>(7)?,
            ))
        })?;

        let mut result = Vec::new();
        for memory in memories {
            let (id, topic, insight, importance_score, embedding_bytes, source_episodes_str, confidence_score, last_updated) = memory?;
            
            let last_updated: DateTime<Utc> = DateTime::parse_from_rfc3339(&last_updated)
                .map(|dt| dt.with_timezone(&Utc))
                .map_err(|_| DbError::InvalidArgument("Invalid timestamp".to_string()))?;

            let embedding = self.bytes_to_embed(&embedding_bytes);
            let source_episodes = serde_json::from_str(&source_episodes_str)?;

            result.push(SemanticMemory {
                id,
                topic,
                insight,
                importance_score,
                embedding,
                source_episodes,
                confidence_score,
                last_updated,
            });
        }

        Ok(result)
    }

    // ===== User Identity Operations =====

    pub fn insert_user_identity(&self, identity: &UserIdentity) -> DbResult<()> {
        let last_reinforced = identity.last_reinforced.to_rfc3339();
        self.conn.execute(
            r#"
            INSERT INTO user_identity (
                id, trait_name, value, confidence_score, category, evidence_count, last_reinforced
            ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
            "#,
            params![
                identity.id,
                identity.trait_name,
                identity.value,
                identity.confidence_score,
                identity.category.to_string(),
                identity.evidence_count,
                last_reinforced,
            ],
        )?;

        Ok(())
    }

    pub fn get_user_identity_by_category(&self, category: &str) -> DbResult<Vec<UserIdentity>> {
        let mut stmt = self.conn.prepare(
            r#"
            SELECT id, trait_name, value, confidence_score, category, evidence_count, last_reinforced
            FROM user_identity
            WHERE category = ?1
            ORDER BY confidence_score DESC
            "#
        )?;

        let identities = stmt.query_map(params![category], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
                row.get::<_, u8>(3)?,
                row.get::<_, String>(4)?,
                row.get::<_, u32>(5)?,
                row.get::<_, String>(6)?,
            ))
        })?;

        let mut result = Vec::new();
        for identity in identities {
            let (id, trait_name, value, confidence_score, category_str, evidence_count, last_reinforced) = identity?;
            
            let last_reinforced: DateTime<Utc> = DateTime::parse_from_rfc3339(&last_reinforced)
                .map(|dt| dt.with_timezone(&Utc))
                .map_err(|_| DbError::InvalidArgument("Invalid timestamp".to_string()))?;

            let category = self.parse_identity_category(&category_str)?;

            result.push(UserIdentity {
                id,
                trait_name,
                value,
                confidence_score,
                category,
                evidence_count,
                last_reinforced,
            });
        }

        Ok(result)
    }

    pub fn get_all_user_identity(&self) -> DbResult<Vec<UserIdentity>> {
        let mut stmt = self.conn.prepare(
            r#"
            SELECT id, trait_name, value, confidence_score, category, evidence_count, last_reinforced
            FROM user_identity
            ORDER BY category, confidence_score DESC
            "#
        )?;

        let identities = stmt.query_map([], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
                row.get::<_, u8>(3)?,
                row.get::<_, String>(4)?,
                row.get::<_, u32>(5)?,
                row.get::<_, String>(6)?,
            ))
        })?;

        let mut result = Vec::new();
        for identity in identities {
            let (id, trait_name, value, confidence_score, category_str, evidence_count, last_reinforced) = identity?;
            
            let last_reinforced: DateTime<Utc> = DateTime::parse_from_rfc3339(&last_reinforced)
                .map(|dt| dt.with_timezone(&Utc))
                .map_err(|_| DbError::InvalidArgument("Invalid timestamp".to_string()))?;

            let category = self.parse_identity_category(&category_str)?;

            result.push(UserIdentity {
                id,
                trait_name,
                value,
                confidence_score,
                category,
                evidence_count,
                last_reinforced,
            });
        }

        Ok(result)
    }

    // ===== AI Self Model Operations =====

    pub fn insert_ai_self_model(&self, model: &AiSelfModel) -> DbResult<()> {
        let last_updated = model.last_updated.to_rfc3339();
        self.conn.execute(
            r#"
            INSERT INTO ai_self_model (
                id, parameter, current_state, delta_from_previous, reinforcement_count, last_updated
            ) VALUES (?1, ?2, ?3, ?4, ?5, ?6)
            "#,
            params![
                model.id,
                model.parameter,
                model.current_state,
                model.delta_from_previous,
                model.reinforcement_count,
                last_updated,
            ],
        )?;

        Ok(())
    }

    pub fn get_all_ai_self_model(&self) -> DbResult<Vec<AiSelfModel>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, parameter, current_state, delta_from_previous, reinforcement_count, last_updated FROM ai_self_model"
        )?;

        let models = stmt.query_map([], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
                row.get::<_, Option<String>>(3)?,
                row.get::<_, u32>(4)?,
                row.get::<_, String>(5)?,
            ))
        })?;

        let mut result = Vec::new();
        for model in models {
            let (id, parameter, current_state, delta_from_previous, reinforcement_count, last_updated) = model?;
            
            let last_updated: DateTime<Utc> = DateTime::parse_from_rfc3339(&last_updated)
                .map(|dt| dt.with_timezone(&Utc))
                .map_err(|_| DbError::InvalidArgument("Invalid timestamp".to_string()))?;

            result.push(AiSelfModel {
                id,
                parameter,
                current_state,
                delta_from_previous,
                reinforcement_count,
                last_updated,
            });
        }

        Ok(result)
    }

    // ===== Helper Methods =====

    fn embed_to_bytes(&self, embed: &[f32]) -> Vec<u8> {
        embed.iter().flat_map(|f| f.to_le_bytes()).collect()
    }

    fn bytes_to_embed(&self, bytes: &[u8]) -> Vec<f32> {
        bytes
            .chunks_exact(4)
            .map(|chunk| {
                let array: [u8; 4] = chunk.try_into().unwrap_or_default();
                f32::from_le_bytes(array)
            })
            .collect()
    }

    fn parse_identity_category(&self, category_str: &str) -> DbResult<IdentityCategory> {
        match category_str {
            "profession" => Ok(IdentityCategory::Profession),
            "personality" => Ok(IdentityCategory::Personality),
            "fear" => Ok(IdentityCategory::Fear),
            "hobby" => Ok(IdentityCategory::Hobby),
            "goal" => Ok(IdentityCategory::Goal),
            "relationship" => Ok(IdentityCategory::Relationship),
            "health" => Ok(IdentityCategory::Health),
            "education" => Ok(IdentityCategory::Education),
            "other" => Ok(IdentityCategory::Other),
            _ => Err(DbError::InvalidArgument(format!("Unknown category: {}", category_str))),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn test_database_creation() {
        let dir = tempdir().unwrap();
        let db_path = dir.path().join("test.db");
        let _manager = DatabaseManager::new(&db_path, "test_password").unwrap();
        assert!(db_path.exists());
    }

    #[test]
    fn test_insert_episodic_memory() {
        let dir = tempdir().unwrap();
        let db_path = dir.path().join("test.db");
        let manager = DatabaseManager::new(&db_path, "test_password").unwrap();

        let memory = EpisodicMemory::new(ChatRole::User, "Hello".to_string(), vec![0.1; 768]);
        manager.insert_episodic_memory(&memory).unwrap();

        let retrieved = manager.get_episodic_memory(&memory.id).unwrap();
        assert!(retrieved.is_some());
        assert_eq!(retrieved.unwrap().content, "Hello");
    }
}
