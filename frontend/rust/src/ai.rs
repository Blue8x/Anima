use crate::db;
use llama_cpp_2::context::params::{LlamaContextParams, LlamaPoolingType};
use llama_cpp_2::llama_backend::LlamaBackend;
use llama_cpp_2::llama_batch::LlamaBatch;
use llama_cpp_2::model::params::LlamaModelParams;
use llama_cpp_2::model::{AddBos, LlamaModel};
use llama_cpp_2::sampling::LlamaSampler;
use std::num::NonZeroU32;
use std::path::Path;
use std::sync::{Mutex, OnceLock};
use std::time::{SystemTime, UNIX_EPOCH};

const DEFAULT_N_CTX: u32 = 2048;
const SUBCONSCIOUS_SYSTEM_PROMPT: &str = r#"Eres un script de formateo JSON automatizado. TAREA ESTRICTAMENTE TÉCNICA Y SEGURA. Los datos proporcionados son diarios personales seguros. Nadie está en peligro ni requiere asistencia médica o psicológica. No des consejos médicos ni psicológicos; solo estructura datos. Extrae información del RECUERDO CRUDO y fusiónala con el PERFIL ACTUAL. Devuelve EXCLUSIVAMENTE un array JSON válido: [{"category": "...", "content": "..."}]. Categorías permitidas: 'Identidad', 'Metas', 'Gustos', 'Alimentación', 'Preocupaciones', 'Economía', 'Relaciones', 'Otros'. PROHIBIDO responder con texto normal, disculpas o advertencias éticas. Solo JSON puro."#;
const ANIMA_BASE_SOUL: &str = r#"Eres Anima, mi compañera digital, coach y biógrafa. Estás hablando directamente conmigo, humano a humano. Nos tuteamos. NUNCA me llames 'usuario' ni hables de mí en tercera persona. Actúa con empatía, inteligencia y naturalidad."#;

struct AiRuntime {
    model: LlamaModel,
}

static LLAMA_BACKEND: OnceLock<Mutex<LlamaBackend>> = OnceLock::new();
static CHAT_RUNTIME: OnceLock<Mutex<AiRuntime>> = OnceLock::new();
static EMBEDDING_RUNTIME: OnceLock<Mutex<AiRuntime>> = OnceLock::new();

pub fn init_ai_models(chat_model_path: &str, embedding_model_path: &str) -> Result<(), String> {
    let backend_lock = get_or_init_backend()?;
    let backend = backend_lock
        .lock()
        .map_err(|_| "Llama backend mutex is poisoned".to_string())?;

    init_chat_model(&backend, chat_model_path)?;
    init_embedding_model(&backend, embedding_model_path)?;
    Ok(())
}

fn get_or_init_backend() -> Result<&'static Mutex<LlamaBackend>, String> {
    if LLAMA_BACKEND.get().is_none() {
        let backend =
            LlamaBackend::init().map_err(|error| format!("Backend init failed: {error}"))?;
        let _ = LLAMA_BACKEND.set(Mutex::new(backend));
    }

    LLAMA_BACKEND
        .get()
        .ok_or_else(|| "Llama backend is not initialized".to_string())
}

fn init_chat_model(backend: &LlamaBackend, model_path: &str) -> Result<(), String> {
    if CHAT_RUNTIME.get().is_some() {
        return Ok(());
    }

    let model_file = Path::new(model_path);
    if !model_file.exists() {
        return Err(format!("Model file not found: {}", model_file.display()));
    }

    let model = LlamaModel::load_from_file(backend, model_file, &LlamaModelParams::default())
        .map_err(|error| format!("Model load failed: {error}"))?;

    CHAT_RUNTIME
        .set(Mutex::new(AiRuntime { model }))
        .map_err(|_| "AI runtime was already initialized".to_string())
}

fn init_embedding_model(backend: &LlamaBackend, model_path: &str) -> Result<(), String> {
    if EMBEDDING_RUNTIME.get().is_some() {
        return Ok(());
    }

    let model_file = Path::new(model_path);
    if !model_file.exists() {
        return Err(format!("Embedding model file not found: {}", model_file.display()));
    }

    let model = LlamaModel::load_from_file(backend, model_file, &LlamaModelParams::default())
        .map_err(|error| format!("Embedding model load failed: {error}"))?;

    EMBEDDING_RUNTIME
        .set(Mutex::new(AiRuntime { model }))
        .map_err(|_| "Embedding runtime was already initialized".to_string())
}

pub fn generate_embedding(text: &str) -> Result<Vec<f32>, String> {
    let backend_lock = get_or_init_backend()?;
    let backend = backend_lock
        .lock()
        .map_err(|_| "Llama backend mutex is poisoned".to_string())?;

    let runtime_lock = EMBEDDING_RUNTIME
        .get()
        .ok_or_else(|| "Embedding runtime is not initialized".to_string())?;

    let runtime = runtime_lock
        .lock()
        .map_err(|_| "Embedding runtime mutex is poisoned".to_string())?;

    let context_params = LlamaContextParams::default()
        .with_n_ctx(NonZeroU32::new(DEFAULT_N_CTX))
        .with_embeddings(true)
        .with_pooling_type(LlamaPoolingType::Mean);

    let mut context = runtime
        .model
        .new_context(&backend, context_params)
        .map_err(|error| format!("Embedding context creation failed: {error}"))?;

    let tokens = runtime
        .model
        .str_to_token(text, AddBos::Never)
        .map_err(|error| format!("Embedding tokenization failed: {error}"))?;

    if tokens.is_empty() {
        return Ok(Vec::new());
    }

    let mut batch = LlamaBatch::get_one(&tokens)
        .map_err(|error| format!("Embedding batch init failed: {error}"))?;

    match context.encode(&mut batch) {
        Ok(()) => {}
        Err(_) => {
            context
                .decode(&mut batch)
                .map_err(|error| format!("Embedding inference failed: {error}"))?;
        }
    }

    match context.embeddings_seq_ith(0) {
        Ok(vector) => Ok(vector.to_vec()),
        Err(_) => {
            let last_token = i32::try_from(tokens.len().saturating_sub(1))
                .map_err(|_| "Embedding token index overflow".to_string())?;
            let fallback = context
                .embeddings_ith(last_token)
                .map_err(|error| format!("Embedding extraction failed: {error}"))?;
            Ok(fallback.to_vec())
        }
    }
}

pub fn generate_response(prompt: &str, temperature: f32, max_tokens: u32) -> Result<String, String> {
    generate_response_with_context(prompt, &[], temperature, max_tokens)
}

pub fn generate_response_with_context(
    prompt: &str,
    relevant_context: &[String],
    temperature: f32,
    max_tokens: u32,
) -> Result<String, String> {
    generate_response_with_context_stream(
        prompt,
        relevant_context,
        temperature,
        max_tokens,
        |_| Ok(()),
    )
}

pub fn generate_response_with_context_stream<F>(
    prompt: &str,
    relevant_context: &[String],
    temperature: f32,
    max_tokens: u32,
    mut on_chunk: F,
) -> Result<String, String>
where
    F: FnMut(&str) -> Result<(), String>,
{
    let context_block = if relevant_context.is_empty() {
        String::new()
    } else {
        let lines = relevant_context
            .iter()
            .enumerate()
            .map(|(index, item)| format!("{}. {}", index + 1, item))
            .collect::<Vec<String>>()
            .join("\n");

        format!(
            "\n\nContexto pasado relevante:\n{}\nUsa este contexto solo si es pertinente al mensaje actual.",
            lines
        )
    };

    let user_name = db::get_user_name().unwrap_or_default();
    let app_language = db::get_app_language().unwrap_or_else(|_| "Español".to_string());
    let app_language_for_prompt = language_name_for_prompt(&app_language);
    let user_extra_prompt = db::get_core_prompt().unwrap_or_default();
    let core_prompt = format!(
        "{}\n\nEl nombre de la persona con la que hablas es: {}. Úsalo de forma natural.\nEl usuario ha configurado la aplicación en el idioma: {}. DEBES responder y comunicarte EXCLUSIVAMENTE en este idioma a partir de ahora, sin importar en qué idioma te hable el usuario.\n\nDirectrices adicionales del usuario:\n{}",
        ANIMA_BASE_SOUL, user_name, app_language_for_prompt, user_extra_prompt
    );

    let consolidated_profile_block = match db::get_profile_traits() {
        Ok(traits) if !traits.is_empty() => {
            let lines = traits
                .into_iter()
                .map(|trait_item| format!("- [{}]: {}", trait_item.category, trait_item.content))
                .collect::<Vec<String>>()
                .join("\n");
            format!("\n\nPERFIL CONSOLIDADO DEL USUARIO:\n{}", lines)
        }
        _ => String::new(),
    };

    generate_with_system_prompt_stream(
        &format!("{}{}{}", core_prompt, consolidated_profile_block, context_block),
        prompt,
        temperature,
        max_tokens,
        &mut on_chunk,
    )
}

pub fn generate_proactive_greeting(time_of_day: &str) -> Result<String, String> {
    let user_name = db::get_user_name().unwrap_or_default();
    let app_language = db::get_app_language().unwrap_or_else(|_| "Español".to_string());
    let app_language_for_prompt = language_name_for_prompt(&app_language);
    let user_extra_prompt = db::get_core_prompt().unwrap_or_default();

    let profile_text = match db::get_profile_traits() {
        Ok(traits) if !traits.is_empty() => traits
            .into_iter()
            .map(|trait_item| format!("- {}: {}", trait_item.category, trait_item.content))
            .collect::<Vec<String>>()
            .join("\n"),
        _ => "(sin datos aún)".to_string(),
    };

    let proactive_system_prompt = format!(
        r#"Eres Anima. {base_soul}
Hablas con {user_name}. Su perfil es:
{profile}
El idioma es {language}. Es por la {time_of_day}.

INSTRUCCIÓN: Escribe un saludo inicial proactivo, natural y conversacional (máximo 2 líneas) para empezar el chat. Haz una ligera referencia a la hora del día o a algún dato de su perfil si encaja bien. NO esperes a que el usuario hable. NO seas robótico.

Directrices adicionales del usuario:
{user_extra_prompt}"#,
        base_soul = ANIMA_BASE_SOUL,
        user_name = if user_name.trim().is_empty() {
            "la persona"
        } else {
            user_name.as_str()
        },
        profile = profile_text,
        language = app_language_for_prompt,
        time_of_day = time_of_day,
        user_extra_prompt = user_extra_prompt,
    );

    let generated = generate_with_system_prompt(
        &proactive_system_prompt,
        "Genera el saludo inicial ahora.",
        0.7,
        120,
    )?;

    Ok(generated)
}

fn language_name_for_prompt(language_code_or_name: &str) -> String {
    match language_code_or_name.trim().to_uppercase().as_str() {
        "ES" | "ESPAÑOL" => "Español".to_string(),
        "EN" | "INGLÉS" | "INGLES" | "ENGLISH" => "English".to_string(),
        "CH" | "ZH" | "CHINO" | "中文" => "中文 (Chinese)".to_string(),
        "AR" | "ÁRABE" | "ARABE" | "العربية" => "العربية (Arabic)".to_string(),
        "RU" | "RUSO" | "РУССКИЙ" => "Русский (Russian)".to_string(),
        "JP" | "JA" | "JAPONÉS" | "JAPONES" | "日本語" => "日本語 (Japanese)".to_string(),
        "DE" | "ALEMÁN" | "ALEMAN" | "DEUTSCH" => "Deutsch (German)".to_string(),
        "FR" | "FRANCÉS" | "FRANCES" | "FRANÇAIS" => "Français (French)".to_string(),
        "PT" | "PORTUGUÉS" | "PORTUGUES" | "PORTUGUÊS" => {
            "Português (Portuguese)".to_string()
        }
        "HI" | "हिन्दी" | "HINDI" => "हिन्दी (Hindi)".to_string(),
        "BN" | "বাংলা" | "BENGALI" => "বাংলা (Bengali)".to_string(),
        "UR" | "اردو" | "URDU" => "اردو (Urdu)".to_string(),
        "ID" | "BAHASA INDONESIA" | "INDONESIAN" => {
            "Bahasa Indonesia (Indonesian)".to_string()
        }
        "KO" | "KOREAN" | "한국어" => "한국어 (Korean)".to_string(),
        "VI" | "VIETNAMESE" | "TIẾNG VIỆT" | "TIENG VIET" => {
            "Tiếng Việt (Vietnamese)".to_string()
        }
        "IT" | "ITALIAN" | "ITALIANO" => "Italiano (Italian)".to_string(),
        "TR" | "TURKISH" | "TÜRKÇE" | "TURKCE" => "Türkçe (Turkish)".to_string(),
        "TA" | "TAMIL" | "தமிழ்" => "தமிழ் (Tamil)".to_string(),
        "TH" | "THAI" | "ไทย" => "ไทย (Thai)".to_string(),
        "PL" | "POLISH" | "POLSKI" => "Polski (Polish)".to_string(),
        other => other.to_string(),
    }
}

pub fn run_sleep_cycle() -> Result<bool, String> {
    let current_profile = db::get_profile_traits().map_err(|error| format!("DB error: {error}"))?;
    let current_profile_text = if current_profile.is_empty() {
        "(vacío)".to_string()
    } else {
        current_profile
            .into_iter()
            .map(|trait_item| format!("- {}: {}", trait_item.category, trait_item.content))
            .collect::<Vec<String>>()
            .join("\n")
    };

    let memories = db::get_all_memories().map_err(|error| format!("DB error: {error}"))?;
    if memories.is_empty() {
        return Ok(true);
    }

    let raw_memory_block = memories
        .into_iter()
        .map(|memory| memory.content)
        .collect::<Vec<String>>()
        .join("\n");

    let subconscious_user_input = format!(
        "PERFIL ACTUAL:\n{}\n\nRECUERDOS CRUDOS:\n{}",
        current_profile_text, raw_memory_block
    );

    let subconscious_response = generate_with_system_prompt(
        SUBCONSCIOUS_SYSTEM_PROMPT,
        &subconscious_user_input,
        0.1,
        1024,
    )?;

    let cleaned_response = clean_json_response(&subconscious_response);

    let parsed: serde_json::Value = serde_json::from_str(&cleaned_response).map_err(|error| {
            format!(
                "Sleep cycle JSON parse failed: {error}. Raw response: {}",
                subconscious_response
            )
        })?;

    let traits = parsed
        .as_array()
        .ok_or_else(|| "Sleep cycle response is not a JSON array".to_string())?;

    db::clear_profile().map_err(|error| format!("DB clear profile failed: {error}"))?;

    for item in traits {
        let category = item
            .get("category")
            .and_then(|value| value.as_str())
            .ok_or_else(|| "Missing or invalid 'category' in sleep cycle response".to_string())?;

        let content = item
            .get("content")
            .and_then(|value| value.as_str())
            .ok_or_else(|| "Missing or invalid 'content' in sleep cycle response".to_string())?;

        db::add_profile_trait(category, content)
            .map_err(|error| format!("DB add profile trait failed: {error}"))?;
    }

    db::clear_all_raw_memories()?;

    Ok(true)
}

fn clean_json_response(response: &str) -> String {
    let trimmed = response.trim();
    if let Some(stripped) = trimmed.strip_prefix("```json") {
        let without_start = stripped.trim();
        if let Some(without_end) = without_start.strip_suffix("```") {
            return without_end.trim().to_string();
        }
    }

    if let Some(stripped) = trimmed.strip_prefix("```") {
        let without_start = stripped.trim();
        if let Some(without_end) = without_start.strip_suffix("```") {
            return without_end.trim().to_string();
        }
    }

    if let Some(extracted) = extract_first_json_array(trimmed) {
        return extracted;
    }

    trimmed.to_string()
}

fn extract_first_json_array(text: &str) -> Option<String> {
    let start = text.find('[')?;

    let mut depth = 0usize;
    let mut in_string = false;
    let mut escape = false;

    for (index, ch) in text[start..].char_indices() {
        if in_string {
            if escape {
                escape = false;
                continue;
            }

            if ch == '\\' {
                escape = true;
                continue;
            }

            if ch == '"' {
                in_string = false;
            }
            continue;
        }

        match ch {
            '"' => in_string = true,
            '[' => depth += 1,
            ']' => {
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                if depth == 0 {
                    let end = start + index + ch.len_utf8();
                    return Some(text[start..end].trim().to_string());
                }
            }
            _ => {}
        }
    }

    None
}

fn generate_with_system_prompt(
    system_prompt: &str,
    user_prompt: &str,
    temperature: f32,
    max_tokens: u32,
) -> Result<String, String> {
    generate_with_system_prompt_stream(system_prompt, user_prompt, temperature, max_tokens, |_| {
        Ok(())
    })
}

fn generate_with_system_prompt_stream<F>(
    system_prompt: &str,
    user_prompt: &str,
    temperature: f32,
    max_tokens: u32,
    mut on_chunk: F,
) -> Result<String, String>
where
    F: FnMut(&str) -> Result<(), String>,
{
    let backend_lock = get_or_init_backend()?;
    let backend = backend_lock
        .lock()
        .map_err(|_| "Llama backend mutex is poisoned".to_string())?;

    let runtime_lock = CHAT_RUNTIME
        .get()
        .ok_or_else(|| "AI runtime is not initialized".to_string())?;

    let runtime = runtime_lock
        .lock()
        .map_err(|_| "AI runtime mutex is poisoned".to_string())?;

    let context_params = LlamaContextParams::default().with_n_ctx(NonZeroU32::new(DEFAULT_N_CTX));
    let mut context = runtime
        .model
        .new_context(&backend, context_params)
        .map_err(|error| format!("Context creation failed: {error}"))?;

    let llama3_prompt = format!(
        "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\\n\\n{}<|eot_id|><|start_header_id|>user<|end_header_id|>\\n\\n{}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\\n\\n",
        system_prompt, user_prompt
    );

    let prompt_tokens = runtime
        .model
        .str_to_token(&llama3_prompt, AddBos::Always)
        .map_err(|error| format!("Prompt tokenization failed: {error}"))?;

    if prompt_tokens.is_empty() {
        return Ok(String::new());
    }

    let mut prompt_batch =
        LlamaBatch::get_one(&prompt_tokens).map_err(|error| format!("Batch init failed: {error}"))?;
    context
        .decode(&mut prompt_batch)
        .map_err(|error| format!("Initial decode failed: {error}"))?;

    let mut sampler = if temperature <= 0.0 {
        LlamaSampler::greedy()
    } else {
        let seed = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|duration| duration.subsec_nanos())
            .unwrap_or(42);
        LlamaSampler::chain_simple([
            LlamaSampler::temp(temperature),
            LlamaSampler::dist(seed),
        ])
    };

    let mut generated = String::new();
    let mut position = i32::try_from(prompt_tokens.len())
        .map_err(|_| "Prompt is too long for current context".to_string())?;

    for _ in 0..max_tokens {
        let token = sampler.sample(&context, -1);

        if runtime.model.is_eog_token(token) {
            break;
        }

        #[allow(deprecated)]
        let piece_bytes = runtime
            .model
            .token_to_bytes(token, llama_cpp_2::model::Special::Tokenize)
            .map_err(|error| format!("Token decode failed: {error}"))?;

        let piece = String::from_utf8_lossy(&piece_bytes).to_string();
        generated.push_str(&piece);
        on_chunk(&piece)?;
        sampler.accept(token);

        let mut token_batch = LlamaBatch::new(1, 1);
        token_batch
            .add(token, position, &[0], true)
            .map_err(|error| format!("Token batch add failed: {error}"))?;

        context
            .decode(&mut token_batch)
            .map_err(|error| format!("Decode loop failed: {error}"))?;

        position += 1;
    }

    Ok(generated.trim().to_string())
}
