// Vector search engine for similarity-based memory retrieval

use crate::models::memory::*;

/// Cosine similarity search for embeddings
pub struct VectorSearchEngine;

impl VectorSearchEngine {
    /// Calculate cosine similarity between two vectors
    pub fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
        if a.len() != b.len() || a.is_empty() {
            return 0.0;
        }

        let mut dot_product = 0.0;
        let mut norm_a = 0.0;
        let mut norm_b = 0.0;

        for (x, y) in a.iter().zip(b.iter()) {
            dot_product += x * y;
            norm_a += x * x;
            norm_b += y * y;
        }

        norm_a = norm_a.sqrt();
        norm_b = norm_b.sqrt();

        if norm_a == 0.0 || norm_b == 0.0 {
            return 0.0;
        }

        dot_product / (norm_a * norm_b)
    }

    /// Find most similar episodes given a query embedding
    pub fn find_similar_episodes(
        query_embedding: &[f32],
        episodes: &[EpisodicMemory],
        top_k: usize,
    ) -> Vec<(EpisodicMemory, f32)> {
        let mut scored: Vec<_> = episodes
            .iter()
            .map(|ep| {
                let similarity = Self::cosine_similarity(query_embedding, &ep.embedding);
                (ep.clone(), similarity)
            })
            .collect();

        scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
        scored.into_iter().take(top_k).collect()
    }

    /// Find most similar insights given a query embedding
    pub fn find_similar_insights(
        query_embedding: &[f32],
        insights: &[SemanticMemory],
        top_k: usize,
    ) -> Vec<(SemanticMemory, f32)> {
        let mut scored: Vec<_> = insights
            .iter()
            .map(|insight| {
                let similarity = Self::cosine_similarity(query_embedding, &insight.embedding);
                (insight.clone(), similarity)
            })
            .collect();

        scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
        scored.into_iter().take(top_k).collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cosine_similarity() {
        let a = vec![1.0, 0.0, 0.0];
        let b = vec![1.0, 0.0, 0.0];
        assert!((VectorSearchEngine::cosine_similarity(&a, &b) - 1.0).abs() < 0.0001);
    }

    #[test]
    fn test_cosine_similarity_orthogonal() {
        let a = vec![1.0, 0.0, 0.0];
        let b = vec![0.0, 1.0, 0.0];
        assert!(VectorSearchEngine::cosine_similarity(&a, &b).abs() < 0.0001);
    }

    #[test]
    fn test_find_similar_episodes() {
        let query = vec![1.0; 768];
        let ep1 = EpisodicMemory::new(ChatRole::User, "Hello".to_string(), vec![1.0; 768]);
        let ep2 = EpisodicMemory::new(ChatRole::User, "World".to_string(), vec![0.0; 768]);

        let episodes = vec![ep1, ep2];
        let results = VectorSearchEngine::find_similar_episodes(&query, &episodes, 1);

        assert_eq!(results.len(), 1);
        assert!(results[0].1 > 0.99); // Should be very similar
    }
}
