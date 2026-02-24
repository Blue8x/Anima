use llama_cpp_2::context::params::LlamaContextParams;
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

struct AiRuntime {
    backend: LlamaBackend,
    model: LlamaModel,
}

static AI_RUNTIME: OnceLock<Mutex<AiRuntime>> = OnceLock::new();

pub fn init_ai_model(model_path: &str) -> Result<(), String> {
    if AI_RUNTIME.get().is_some() {
        return Ok(());
    }

    let model_file = Path::new(model_path);
    if !model_file.exists() {
        return Err(format!("Model file not found: {}", model_file.display()));
    }

    let backend = LlamaBackend::init().map_err(|error| format!("Backend init failed: {error}"))?;
    let model = LlamaModel::load_from_file(&backend, model_file, &LlamaModelParams::default())
        .map_err(|error| format!("Model load failed: {error}"))?;

    AI_RUNTIME
        .set(Mutex::new(AiRuntime { backend, model }))
        .map_err(|_| "AI runtime was already initialized".to_string())
}

pub fn generate_response(prompt: &str, temperature: f32, max_tokens: u32) -> Result<String, String> {
    let runtime_lock = AI_RUNTIME
        .get()
        .ok_or_else(|| "AI runtime is not initialized".to_string())?;

    let runtime = runtime_lock
        .lock()
        .map_err(|_| "AI runtime mutex is poisoned".to_string())?;

    let context_params = LlamaContextParams::default().with_n_ctx(NonZeroU32::new(DEFAULT_N_CTX));
    let mut context = runtime
        .model
        .new_context(&runtime.backend, context_params)
        .map_err(|error| format!("Context creation failed: {error}"))?;

    let llama3_prompt = format!(
        "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\\n\\nEres Anima, una IA amigable, útil y concisa. Responde siempre en el mismo idioma en el que escribe el usuario. Si el usuario mezcla idiomas, prioriza el idioma dominante del ÚLTIMO mensaje del usuario. No traduzcas ni cambies de idioma a menos que el usuario lo pida explícitamente.<|eot_id|><|start_header_id|>user<|end_header_id|>\\n\\n{}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\\n\\n",
        prompt
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
