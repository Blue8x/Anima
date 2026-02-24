use crate::db;
pub use crate::db::ChatMessage;

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb]
pub fn send_message(message: String) -> String {
    if let Err(error) = db::insert_message("user", &message) {
        eprintln!("Failed to store user message: {error}");
    }

    std::thread::sleep(std::time::Duration::from_millis(1500));

    let echo = format!("Anima echo: {message}");

    if let Err(error) = db::insert_message("assistant", &echo) {
        eprintln!("Failed to store assistant message: {error}");
    }

    echo
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
}
