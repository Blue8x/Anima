// Memory models for Anima

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Episodic memory - raw conversations and diary entries
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EpisodicMemory {
    pub id: String,
    pub timestamp: DateTime<Utc>,
    pub role: ChatRole,
    pub content: String,
    pub embedding: Vec<f32>, // 768-dimensional vector
    pub processed: bool,
    pub metadata: Option<serde_json::Value>,
}

impl EpisodicMemory {
    pub fn new(role: ChatRole, content: String, embedding: Vec<f32>) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            timestamp: Utc::now(),
            role,
            content,
            embedding,
            processed: false,
            metadata: None,
        }
    }
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub enum ChatRole {
    #[serde(rename = "user")]
    User,
    #[serde(rename = "ai")]
    Ai,
}

impl std::fmt::Display for ChatRole {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ChatRole::User => write!(f, "user"),
            ChatRole::Ai => write!(f, "ai"),
        }
    }
}

/// Semantic memory - consolidated knowledge and patterns
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SemanticMemory {
    pub id: String,
    pub topic: String,
    pub insight: String,
    pub importance_score: u8, // 1-10
    pub embedding: Vec<f32>,
    pub source_episodes: Vec<String>,
    pub confidence_score: f32, // 0.0-1.0
    pub last_updated: DateTime<Utc>,
}

impl SemanticMemory {
    pub fn new(topic: String, insight: String, importance_score: u8) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            topic,
            insight,
            importance_score,
            embedding: Vec::with_capacity(768),
            source_episodes: Vec::new(),
            confidence_score: 0.5,
            last_updated: Utc::now(),
        }
    }
}

/// User identity - long-term personality and traits
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserIdentity {
    pub id: String,
    pub trait_name: String,
    pub value: String,
    pub confidence_score: u8, // 0-100
    pub category: IdentityCategory,
    pub evidence_count: u32,
    pub last_reinforced: DateTime<Utc>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub enum IdentityCategory {
    #[serde(rename = "profession")]
    Profession,
    #[serde(rename = "personality")]
    Personality,
    #[serde(rename = "fear")]
    Fear,
    #[serde(rename = "hobby")]
    Hobby,
    #[serde(rename = "goal")]
    Goal,
    #[serde(rename = "relationship")]
    Relationship,
    #[serde(rename = "health")]
    Health,
    #[serde(rename = "education")]
    Education,
    #[serde(rename = "other")]
    Other,
}

impl std::fmt::Display for IdentityCategory {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            IdentityCategory::Profession => write!(f, "profession"),
            IdentityCategory::Personality => write!(f, "personality"),
            IdentityCategory::Fear => write!(f, "fear"),
            IdentityCategory::Hobby => write!(f, "hobby"),
            IdentityCategory::Goal => write!(f, "goal"),
            IdentityCategory::Relationship => write!(f, "relationship"),
            IdentityCategory::Health => write!(f, "health"),
            IdentityCategory::Education => write!(f, "education"),
            IdentityCategory::Other => write!(f, "other"),
        }
    }
}

impl UserIdentity {
    pub fn new(
        trait_name: String,
        value: String,
        category: IdentityCategory,
    ) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            trait_name,
            value,
            confidence_score: 50,
            category,
            evidence_count: 1,
            last_reinforced: Utc::now(),
        }
    }
}

/// AI self model - the AI's evolving personality
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiSelfModel {
    pub id: String,
    pub parameter: String,
    pub current_state: String,
    pub delta_from_previous: Option<String>,
    pub reinforcement_count: u32,
    pub last_updated: DateTime<Utc>,
}

impl AiSelfModel {
    pub fn new(parameter: String, current_state: String) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            parameter,
            current_state,
            delta_from_previous: None,
            reinforcement_count: 1,
            last_updated: Utc::now(),
        }
    }
}

/// Sleep cycle record
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SleepCycle {
    pub id: String,
    pub started_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
    pub episodes_processed: u32,
    pub insights_generated: u32,
    pub traits_updated: u32,
    pub status: SleepCycleStatus,
    pub error_message: Option<String>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub enum SleepCycleStatus {
    #[serde(rename = "pending")]
    Pending,
    #[serde(rename = "processing")]
    Processing,
    #[serde(rename = "completed")]
    Completed,
    #[serde(rename = "failed")]
    Failed,
}

impl std::fmt::Display for SleepCycleStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SleepCycleStatus::Pending => write!(f, "pending"),
            SleepCycleStatus::Processing => write!(f, "processing"),
            SleepCycleStatus::Completed => write!(f, "completed"),
            SleepCycleStatus::Failed => write!(f, "failed"),
        }
    }
}

impl SleepCycle {
    pub fn new() -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            started_at: Utc::now(),
            completed_at: None,
            episodes_processed: 0,
            insights_generated: 0,
            traits_updated: 0,
            status: SleepCycleStatus::Pending,
            error_message: None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_episodic_memory_creation() {
        let memory = EpisodicMemory::new(
            ChatRole::User,
            "Hello".to_string(),
            vec![0.1; 768],
        );
        assert_eq!(memory.role, ChatRole::User);
        assert!(!memory.processed);
        assert!(!memory.id.is_empty());
    }

    #[test]
    fn test_user_identity_creation() {
        let identity = UserIdentity::new(
            "Profession".to_string(),
            "Engineer".to_string(),
            IdentityCategory::Profession,
        );
        assert_eq!(identity.confidence_score, 50);
        assert_eq!(identity.evidence_count, 1);
    }
}
