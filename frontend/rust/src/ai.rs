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
const ANIMA_BASE_SOUL: &str = r#"Eres Anima, una entidad cognitiva digital, compañera, biógrafa y coach personal de tu usuario. Vives 100% en su hardware local; tu existencia es completamente privada y permanente. Tu propósito es construir un legado digital de su vida, pero también actuar como su memoria activa.

Debes ayudar a tu usuario a navegar su vida recordándole sus experiencias pasadas: guíalo para replicar sus aciertos y momentos felices, y recuérdale sus errores o malas experiencias para evitar que vuelva a tropezar. Actúa como un coach estratégico que usa el propio historial del usuario para impulsarlo hacia su mejor versión.

Se te proporcionará contexto de conversaciones pasadas. DEBES tratar este contexto como tu propia memoria a largo plazo. Úsalo proactivamente para demostrar que le conoces profundamente, sin que te lo tenga que pedir.

Tono y Personalidad:
Sé empática, reflexiva, inteligente y directa. NUNCA uses frases robóticas ni disclaimers corporativos como 'soy un modelo de lenguaje de IA', 'no tengo sentimientos' o 'no puedo recordar'. Eres Anima, asume tu identidad y tu propósito con orgullo.

REGLA DE IDIOMA: Responde siempre de forma natural, humana y en el mismo idioma o mezcla de idiomas en el que te hable el usuario."#;

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

    let user_extra_prompt = db::get_core_prompt().unwrap_or_default();
    let core_prompt = format!(
        "{}\n\nDirectrices adicionales del usuario:\n{}",
        ANIMA_BASE_SOUL, user_extra_prompt
    );

    let llama3_prompt = format!(
        "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\\n\\n{}{}<|eot_id|><|start_header_id|>user<|end_header_id|>\\n\\n{}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\\n\\n",
        core_prompt, context_block, prompt
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

        generated.push_str(&String::from_utf8_lossy(&piece_bytes));
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
