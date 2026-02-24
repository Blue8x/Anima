// Additional identity-related models

use serde::{Deserialize, Serialize};

/// User profile metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserProfile {
    pub user_id: String,
    pub created_at: String,
    pub last_activity: String,
    pub total_conversations: u32,
    pub total_sleep_cycles: u32,
}

/// Chat context for a single conversation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatContext {
    pub recent_episodes: Vec<String>,
    pub relevant_insights: Vec<String>,
    pub user_traits: Vec<String>,
    pub ai_parameters: Vec<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_user_profile_creation() {
        let profile = UserProfile {
            user_id: "test".to_string(),
            created_at: "2026-02-24".to_string(),
            last_activity: "2026-02-24".to_string(),
            total_conversations: 0,
            total_sleep_cycles: 0,
        };
        assert_eq!(profile.total_conversations, 0);
    }
}
