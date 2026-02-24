use crate::ai;
use crate::db;
pub use crate::db::ChatMessage;
use std::path::PathBuf;
use std::sync::{Mutex, OnceLock};

static INIT_ERROR: OnceLock<Mutex<Option<String>>> = OnceLock::new();

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb]
pub fn send_message(message: String, temperature: f32, max_tokens: u32) -> String {
    if let Some(error) = current_init_error() {
        return format!("Error: {error}");
    }

    let mut relevant_context = Vec::<String>::new();

    let user_message_id = match db::insert_message("user", &message) {
        Ok(message_id) => message_id,
        Err(error) => {
            let detail = format!("Error de DB al guardar mensaje de usuario: {error}");
            eprintln!("{detail}");
            return format!("Error: {detail}");
        }
    };

    match ai::generate_embedding(&message) {
        Ok(embedding) if !embedding.is_empty() => {
            if let Err(error) = db::insert_memory(user_message_id, &embedding) {
                let detail = format!("Error de DB al guardar embedding: {error}");
                eprintln!("{detail}");
                return format!("Error: {detail}");
            }

            match db::find_top_similar_memories(&embedding, 3, Some(user_message_id)) {
                Ok(matches) => {
                    relevant_context = matches
                        .into_iter()
                        .map(|memory| format!("[{}] {}", memory.role, memory.content))
                        .collect();
                }
                Err(error) => {
                    let detail = format!("Error al recuperar contexto semántico: {error}");
                    eprintln!("{detail}");
                    return format!("Error: {detail}");
                }
            }
        }
        Ok(_) => {}
        Err(error) => {
            let detail = format!("Error generando embedding: {error}");
            eprintln!("{detail}");
            return format!("Error: {detail}");
        }
    }

    let generated = match ai::generate_response_with_context(
        &message,
        &relevant_context,
        temperature,
        max_tokens,
    ) {
        Ok(output) if !output.is_empty() => output,
        Ok(_) => "I do not have a response yet.".to_string(),
        Err(error) => {
            let detail = format!("Error al generar respuesta LLM: {error}");
            eprintln!("{detail}");
            format!("Error: {detail}")
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

#[flutter_rust_bridge::frb]
pub fn init_app(chat_model_path: String, embedding_model_path: String) {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();

    if let Err(error) = db::init_db() {
        eprintln!("Failed to initialize local SQLite DB: {error}");
    }

    let resolved_chat = match resolve_model_path(&chat_model_path) {
        Ok(path) => path,
        Err(error) => {
            set_init_error(Some(error.clone()));
            eprintln!("{error}");
            return;
        }
    };

    let resolved_embedding = match resolve_model_path(&embedding_model_path) {
        Ok(path) => path,
        Err(error) => {
            set_init_error(Some(error.clone()));
            eprintln!("{error}");
            return;
        }
    };

    if let Err(error) = ai::init_ai_models(&resolved_chat, &resolved_embedding) {
        let detail = format!(
            "Failed to initialize AI models (chat: {resolved_chat}, embeddings: {resolved_embedding}): {error}"
        );
        set_init_error(Some(detail.clone()));
        eprintln!(
            "{detail}"
        );
        return;
    }

    set_init_error(None);
}

fn current_init_error() -> Option<String> {
    let lock = INIT_ERROR.get_or_init(|| Mutex::new(None));
    match lock.lock() {
        Ok(state) => state.clone(),
        Err(_) => Some("Error interno: estado de inicialización corrupto".to_string()),
    }
}

fn set_init_error(value: Option<String>) {
    let lock = INIT_ERROR.get_or_init(|| Mutex::new(None));
    if let Ok(mut state) = lock.lock() {
        *state = value;
    }
}

fn resolve_model_path(model_path: &str) -> Result<String, String> {
    let as_path = PathBuf::from(model_path);
    if as_path.is_absolute() && as_path.exists() {
        return Ok(as_path.to_string_lossy().to_string());
    }

    let cwd = std::env::current_dir().map_err(|error| {
        format!("No se pudo leer el directorio actual para resolver '{model_path}': {error}")
    })?;

    let candidates = vec![
        cwd.join(model_path),
        cwd.join("..").join(model_path),
        cwd.join("..").join("..").join(model_path),
        as_path,
    ];

    for candidate in &candidates {
        if candidate.exists() {
            return Ok(candidate.to_string_lossy().to_string());
        }
    }

    let tried = candidates
        .iter()
        .map(|path| path.to_string_lossy().to_string())
        .collect::<Vec<String>>()
        .join(" | ");

    Err(format!(
        "No se encontró el modelo '{model_path}'. CWD actual: '{}'. Rutas probadas: {tried}",
        cwd.display()
    ))
}
