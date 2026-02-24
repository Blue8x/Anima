// AI service - manages LLM interactions and personality

use crate::database::DatabaseManager;
use crate::models::memory::AiSelfModel;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct AiPersonality {
    pub parameters: Vec<(String, String)>,
}

pub struct AiService {
    db: DatabaseManager,
}

impl AiService {
    pub fn new(db: DatabaseManager) -> Self {
        Self { db }
    }

    /// Get current AI personality parameters
    pub fn get_personality(&self) -> Result<AiPersonality, String> {
        let models = self.db.get_all_ai_self_model()
            .map_err(|e| e.to_string())?;

        let parameters: Vec<_> = models
            .iter()
            .map(|m| (m.parameter.clone(), m.current_state.clone()))
            .collect();

        Ok(AiPersonality { parameters })
    }

    /// Update AI personality parameter
    pub fn update_personality_parameter(
        &self,
        parameter: &str,
        new_state: &str,
    ) -> Result<(), String> {
        let models = self.db.get_all_ai_self_model()
            .map_err(|e| e.to_string())?;

        // Find existing parameter or create new one
        let _model = models
            .iter()
            .find(|m| m.parameter == parameter)
            .cloned()
            .map(|mut m| {
                m.delta_from_previous = Some(format!("{} → {}", m.current_state, new_state));
                m.current_state = new_state.to_string();
                m.reinforcement_count += 1;
                m
            })
            .unwrap_or_else(|| {
                AiSelfModel::new(parameter.to_string(), new_state.to_string())
            });

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn test_ai_service_creation() {
        let dir = tempdir().unwrap();
        let db_path = dir.path().join("test.db");
        let db = DatabaseManager::new(&db_path, "test").unwrap();
        let _service = AiService::new(db);
    }
}
