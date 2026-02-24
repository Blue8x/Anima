use crate::ai;
use crate::db;
pub use crate::db::ChatMessage;
use std::path::PathBuf;

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb]
pub fn send_message(message: String, temperature: f32, max_tokens: u32) -> String {
    if let Err(error) = db::insert_message("user", &message) {
        eprintln!("Failed to store user message: {error}");
    }

    let generated = match ai::generate_response(&message, temperature, max_tokens) {
        Ok(output) if !output.is_empty() => output,
        Ok(_) => "I do not have a response yet.".to_string(),
        Err(error) => {
            eprintln!("LLM generation failed: {error}");
            format!("Anima fallback: {message}")
        }
    };

    if let Err(error) = db::insert_message("assistant", &generated) {
        eprintln!("Failed to store assistant message: {error}");
    }

    generated
}

#[flutter_rust_bridge::frb]
pub fn get_chat_history() -> Vec<ChatMessage> {
    match db::get_all_messages() {
        Ok(history) => history,
        Err(error) => {
            eprintln!("Failed to fetch chat history: {error}");
            Vec::new()
        }
    }
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();

    if let Err(error) = db::init_db() {
        eprintln!("Failed to initialize local SQLite DB: {error}");
    }

    let model_path = resolve_model_path();
    if let Err(error) = ai::init_ai_model(&model_path) {
        eprintln!("Failed to initialize AI model from {model_path}: {error}");
    }
}

fn resolve_model_path() -> String {
    let mut candidates = Vec::<PathBuf>::new();
    if let Ok(current_dir) = std::env::current_dir() {
        candidates.push(current_dir.join("models").join("anima_v1.gguf"));
        candidates.push(current_dir.join("..").join("models").join("anima_v1.gguf"));
        candidates.push(
            current_dir
                .join("..")
                .join("..")
                .join("models")
                .join("anima_v1.gguf"),
        );
    }

    candidates.push(PathBuf::from("models/anima_v1.gguf"));

    for candidate in candidates {
        if candidate.exists() {
            return candidate.to_string_lossy().to_string();
        }
    }

    "models/anima_v1.gguf".to_string()
}
