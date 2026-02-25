use crate::ai;
use crate::db;
pub use crate::db::ChatMessage;
pub use crate::db::MemoryItem;
pub use crate::db::ProfileTrait;
use crate::frb_generated::StreamSink;
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

    let (_user_message_id, relevant_context) = match prepare_message_context(&message) {
        Ok(values) => values,
        Err(detail) => {
            eprintln!("{detail}");
            return format!("Error: {detail}");
        }
    };

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
pub fn send_message_stream(
    message: String,
    temperature: f32,
    max_tokens: u32,
    sink: StreamSink<String>,
) -> Result<(), String> {
    if let Some(error) = current_init_error() {
        return Err(error);
    }

    let (_user_message_id, relevant_context) = prepare_message_context(&message)?;

    ai::generate_response_with_context_stream(
        &message,
        &relevant_context,
        temperature,
        max_tokens,
        |chunk| {
            let _ = sink.add(chunk.to_string());
            Ok(())
        },
    )?;

    Ok(())
}

#[flutter_rust_bridge::frb]
pub fn save_assistant_message(message: String) -> bool {
    match db::insert_message("assistant", &message) {
        Ok(_) => true,
        Err(error) => {
            eprintln!("Failed to store assistant message: {error}");
            false
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn generate_proactive_greeting(time_of_day: String) -> Result<String, String> {
    ai::generate_proactive_greeting(&time_of_day)
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
pub fn get_all_memories() -> Vec<MemoryItem> {
    match db::get_all_memories() {
        Ok(memories) => memories,
        Err(error) => {
            eprintln!("Failed to fetch memories: {error}");
            Vec::new()
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn delete_memory(id: i64) -> bool {
    match db::delete_memory(id) {
        Ok(()) => true,
        Err(error) => {
            eprintln!("Failed to delete memory {id}: {error}");
            false
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn get_core_prompt() -> String {
    match db::get_core_prompt() {
        Ok(prompt) => prompt,
        Err(error) => {
            eprintln!("Failed to load core prompt: {error}");
            String::new()
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn set_core_prompt(prompt: String) -> bool {
    match db::set_core_prompt(&prompt) {
        Ok(()) => true,
        Err(error) => {
            eprintln!("Failed to save core prompt: {error}");
            false
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn get_user_name() -> String {
    match db::get_user_name() {
        Ok(name) => name,
        Err(error) => {
            eprintln!("Failed to load user name: {error}");
            String::new()
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn set_user_name(name: String) -> bool {
    match db::set_user_name(&name) {
        Ok(()) => true,
        Err(error) => {
            eprintln!("Failed to save user name: {error}");
            false
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn get_app_language() -> String {
    match db::get_app_language() {
        Ok(lang) => lang,
        Err(error) => {
            eprintln!("Failed to load app language: {error}");
            "Español".to_string()
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn set_app_language(lang: String) -> bool {
    match db::set_app_language(&lang) {
        Ok(()) => true,
        Err(error) => {
            eprintln!("Failed to save app language: {error}");
            false
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn add_profile_trait(category: String, content: String) -> bool {
    match db::add_profile_trait(&category, &content) {
        Ok(()) => true,
        Err(error) => {
            eprintln!("Failed to add profile trait: {error}");
            false
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn export_database(dest_path: String) -> Result<bool, String> {
    db::export_database(&dest_path).map_err(|error| format!("Export failed: {error}"))
}

#[flutter_rust_bridge::frb]
pub fn factory_reset() -> Result<bool, String> {
    db::factory_reset()
}

#[flutter_rust_bridge::frb]
pub fn run_sleep_cycle() -> Result<bool, String> {
    ai::run_sleep_cycle()
}

#[flutter_rust_bridge::frb]
pub fn get_profile_traits() -> Vec<ProfileTrait> {
    match db::get_profile_traits() {
        Ok(traits) => traits,
        Err(error) => {
            eprintln!("Failed to fetch profile traits: {error}");
            Vec::new()
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn clear_profile() -> bool {
    match db::clear_profile() {
        Ok(()) => true,
        Err(error) => {
            eprintln!("Failed to clear profile: {error}");
            false
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

fn prepare_message_context(message: &str) -> Result<(i64, Vec<String>), String> {
    let user_message_id = db::insert_message("user", message)
        .map_err(|error| format!("Error de DB al guardar mensaje de usuario: {error}"))?;

    let mut relevant_context = Vec::<String>::new();

    match ai::generate_embedding(message) {
        Ok(embedding) if !embedding.is_empty() => {
            db::insert_memory(user_message_id, &embedding)
                .map_err(|error| format!("Error de DB al guardar embedding: {error}"))?;

            let matches = db::find_top_similar_memories(&embedding, 3, Some(user_message_id))
                .map_err(|error| format!("Error al recuperar contexto semántico: {error}"))?;

            relevant_context = matches
                .into_iter()
                .map(|memory| format!("[{}] {}", memory.role, memory.content))
                .collect();
        }
        Ok(_) => {}
        Err(error) => {
            return Err(format!("Error generando embedding: {error}"));
        }
    }

    Ok((user_message_id, relevant_context))
}
