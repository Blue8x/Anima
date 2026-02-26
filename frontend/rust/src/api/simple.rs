use crate::ai;
use crate::db;
use chrono::{Local, TimeZone};
pub use crate::db::ChatMessage;
pub use crate::db::MemoryItem;
pub use crate::db::ProfileTrait;
use crate::frb_generated::StreamSink;
use std::panic::{self, AssertUnwindSafe};
use std::path::PathBuf;
use std::sync::mpsc;
use std::sync::{Mutex, OnceLock};
use std::thread;
use std::time::Duration;

static INIT_ERROR: OnceLock<Mutex<Option<String>>> = OnceLock::new();
const HISTORY_START_TAG: &str = "<ANIMA_HISTORY>";
const HISTORY_END_TAG: &str = "</ANIMA_HISTORY>";
const USER_START_TAG: &str = "<ANIMA_USER>";
const USER_END_TAG: &str = "</ANIMA_USER>";

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb]
pub fn send_message(message: String, temperature: f32, max_tokens: u32) -> String {
    if let Some(error) = current_init_error() {
        return format!("[Error del Sistema: Motor IA no cargado] {error}");
    }

    let (_user_message_id, relevant_context, model_prompt) = match prepare_message_context(&message) {
        Ok(values) => values,
        Err(detail) => {
            eprintln!("{detail}");
            return format!("Error: {detail}");
        }
    };

    let _requested_temperature = temperature;
    let effective_temperature = 0.7_f32;

    let safe_max_tokens = max_tokens.min(512);

    let generation_result = panic::catch_unwind(AssertUnwindSafe(|| {
        ai::generate_response_with_context(
            &model_prompt,
            &relevant_context,
            effective_temperature,
            safe_max_tokens,
        )
    }));

    let generated = match generation_result {
        Ok(Ok(output)) if !output.is_empty() => output,
        Ok(Ok(_)) => {
            "[Error: Límite de memoria alcanzado] Inferencia devolvió salida vacía.".to_string()
        }
        Ok(Err(error)) => {
            let detail = format!("Error al generar respuesta LLM: {error}");
            eprintln!("{detail}");
            format_generation_error(&detail)
        }
        Err(_) => {
            "[Error: Límite de memoria alcanzado] El motor de inferencia se detuvo por seguridad."
                .to_string()
        }
    };

    if let Err(error) = insert_message_with_timeout("assistant", &generated, Duration::from_secs(5)) {
        eprintln!("Failed to store assistant message safely: {error}");
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
        return Err(format!("[Error del Sistema: Motor IA no cargado] {error}"));
    }

    let (_user_message_id, relevant_context, model_prompt) = prepare_message_context(&message)?;

    let _requested_temperature = temperature;
    let effective_temperature = 0.7_f32;

    let safe_max_tokens = max_tokens.min(512);

    let generation_result = panic::catch_unwind(AssertUnwindSafe(|| {
        ai::generate_response_with_context_stream(
            &model_prompt,
            &relevant_context,
            effective_temperature,
            safe_max_tokens,
            |chunk| {
                let _ = sink.add(chunk.to_string());
                Ok(())
            },
        )
    }));

    let final_output = match generation_result {
        Ok(Ok(output)) => output,
        Ok(Err(error)) => {
            let detail = format!("Error al generar respuesta LLM: {error}");
            return Err(format_generation_error(&detail));
        }
        Err(_) => {
            return Err(
                "[Error: Límite de memoria alcanzado] El motor de inferencia se detuvo por seguridad."
                    .to_string(),
            );
        }
    };

    if final_output.trim().is_empty() {
        return Err("[Error: Límite de memoria alcanzado] Inferencia stream devolvió salida vacía.".to_string());
    }

    Ok(())
}

#[flutter_rust_bridge::frb]
pub fn get_temperature() -> f32 {
    match db::get_temperature() {
        Ok(temperature) => temperature,
        Err(error) => {
            eprintln!("Failed to load temperature: {error}");
            0.7
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn set_temperature(temperature: f32) -> bool {
    match db::set_temperature(temperature) {
        Ok(()) => true,
        Err(error) => {
            eprintln!("Failed to save temperature: {error}");
            false
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn export_brain() -> Result<String, String> {
    ai::export_brain()
}

#[flutter_rust_bridge::frb]
pub fn save_assistant_message(message: String) -> bool {
    match insert_message_with_timeout("assistant", &message, Duration::from_secs(5)) {
        Ok(_) => true,
        Err(error) => {
            eprintln!("Failed to store assistant message safely: {error}");
            false
        }
    }
}

#[flutter_rust_bridge::frb]
pub fn generate_proactive_greeting(time_of_day: String) -> Result<String, String> {
    if let Some(error) = current_init_error() {
        return Err(format!("[Error del Sistema: Motor IA no cargado] {error}"));
    }

    let generation_result = panic::catch_unwind(AssertUnwindSafe(|| {
        ai::generate_proactive_greeting(&time_of_day)
    }));

    match generation_result {
        Ok(Ok(output)) if output.trim().is_empty() => Err(
            "[Error del Sistema: Inferencia de saludo devolvió salida vacía (possible OOM, context limit, or sampling collapse)]"
                .to_string(),
        ),
        Ok(Ok(output)) => Ok(output),
        Ok(Err(error)) => Err(format!("Error al generar saludo LLM: {error}")),
        Err(_) => Err("Error interno del motor: panic during greeting inference".to_string()),
    }
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
pub fn search_memories(query: String) -> Result<Vec<MemoryItem>, String> {
    db::search_memories(&query).map_err(|error| format!("Memory search failed: {error}"))
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
    eprintln!("[factory_reset_api] request received");
    db::factory_reset().map(|_| {
        eprintln!("[factory_reset_api] completed");
        true
    })
}

#[flutter_rust_bridge::frb]
pub fn run_sleep_cycle() -> Result<bool, String> {
    ai::run_sleep_cycle().map(|_| true)
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
    if as_path.is_absolute() {
        if as_path.exists() {
            return Ok(as_path.to_string_lossy().to_string());
        }
        return Err(format!(
            "Model file not found exactly at: {}",
            as_path.display()
        ));
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

fn prepare_message_context(message: &str) -> Result<(i64, Vec<String>, String), String> {
    let (user_message, model_prompt) = parse_client_message_payload(message);

    let user_message_id = insert_message_with_timeout("user", &user_message, Duration::from_secs(5))
        .map_err(|error| format!("Error de DB al guardar mensaje de usuario: {error}"))?;

    let mut relevant_context = Vec::<String>::new();

    match ai::generate_embedding(&user_message) {
        Ok(embedding) if !embedding.is_empty() => {
            db::insert_memory(
                user_message_id,
                &embedding,
                "episodic",
                db::current_unix_timestamp(),
            )
                .map_err(|error| format!("Error de DB al guardar embedding: {error}"))?;

            let matches = db::find_top_similar_memories(&embedding, 3, Some(user_message_id))
                .map_err(|error| format!("Error al recuperar contexto semántico: {error}"))?;

            relevant_context = matches
                .into_iter()
                .map(|memory| {
                    if memory.memory_type == "semantic" {
                        format!("- {}", memory.content)
                    } else {
                        let dt = Local
                            .timestamp_opt(memory.memory_unix_timestamp, 0)
                            .single();
                        let date_label = dt
                            .map(|value| value.format("%Y-%m-%d").to_string())
                            .unwrap_or_else(|| "unknown-date".to_string());
                        format!("- [{}]: {}", date_label, memory.content)
                    }
                })
                .collect();
        }
        Ok(_) => {}
        Err(error) => {
            return Err(format!("Error generando embedding: {error}"));
        }
    }

    Ok((user_message_id, relevant_context, model_prompt))
}

fn parse_client_message_payload(payload: &str) -> (String, String) {
    let history = extract_tag_content(payload, HISTORY_START_TAG, HISTORY_END_TAG)
        .map(|content| content.trim().to_string())
        .unwrap_or_default();

    let user = extract_tag_content(payload, USER_START_TAG, USER_END_TAG)
        .map(|content| content.trim().to_string())
        .unwrap_or_else(|| payload.trim().to_string());

    if user.is_empty() {
        return (payload.trim().to_string(), payload.trim().to_string());
    }

    if history.is_empty() {
        return (user.clone(), user);
    }

    let model_prompt = format!(
        "Historial reciente (máximo 4 mensajes):\n{}\n\nMensaje actual del usuario:\n{}",
        history, user
    );

    (user, model_prompt)
}

fn extract_tag_content<'a>(input: &'a str, start_tag: &str, end_tag: &str) -> Option<&'a str> {
    let start_index = input.find(start_tag)? + start_tag.len();
    let end_index = input[start_index..].find(end_tag)? + start_index;
    Some(&input[start_index..end_index])
}

fn insert_message_with_timeout(role: &str, content: &str, timeout: Duration) -> Result<i64, String> {
    let role_owned = role.to_string();
    let content_owned = content.to_string();

    let (tx, rx) = mpsc::channel::<std::result::Result<i64, String>>();

    thread::spawn(move || {
        let result = db::insert_message(&role_owned, &content_owned)
            .map_err(|error| format!("DB insert failed: {error}"));
        let _ = tx.send(result);
    });

    match rx.recv_timeout(timeout) {
        Ok(result) => result,
        Err(mpsc::RecvTimeoutError::Timeout) => {
            Err(format!("DB insert timeout after {}s", timeout.as_secs()))
        }
        Err(error) => Err(format!("DB insert channel error: {error}")),
    }
}

fn format_generation_error(detail: &str) -> String {
    let lowered = detail.to_lowercase();
    if lowered.contains("memory")
        || lowered.contains("context")
        || lowered.contains("kv")
        || lowered.contains("oom")
    {
        return format!("[Error: Límite de memoria alcanzado] {detail}");
    }
    format!("[Error: Inferencia fallida] {detail}")
}
