mod models;
mod database;
mod services;

use models::memory::*;
use database::DatabaseManager;
use services::{ChatService, SleepCycleService, AiService};

fn main() {
    println!("🧬 Anima - AI Biographer and Local Mentor");
    println!("Initializing backend...\n");

    // Initialize database
    let db_path = std::path::PathBuf::from("anima.db");
    let db = match DatabaseManager::new(&db_path, "default_password") {
        Ok(db) => {
            println!("✓ Database initialized: {:?}", db_path);
            db
        }
        Err(e) => {
            eprintln!("✗ Failed to initialize database: {}", e);
            return;
        }
    };

    // Initialize services
    let chat_service = ChatService::new(
        DatabaseManager::new(&db_path, "default_password").expect("Database init failed"),
    );
    let sleep_service = SleepCycleService::new(
        DatabaseManager::new(&db_path, "default_password").expect("Database init failed"),
    );
    let ai_service = AiService::new(
        DatabaseManager::new(&db_path, "default_password").expect("Database init failed"),
    );

    println!("✓ Services initialized");
    println!("  - Chat Service");
    println!("  - Sleep Cycle Service");
    println!("  - AI Service\n");

    // Test basic functionality
    println!("Running basic checks...\n");

    // Get AI personality
    match ai_service.get_personality() {
        Ok(personality) => {
            println!("✓ AI personality loaded");
            if personality.parameters.is_empty() {
                println!("  (Empty initialization - will be updated on the first sleep cycle)");
            }
        }
        Err(e) => eprintln!("✗ Failed to load personality: {}", e),
    }

    // Test memory creation
    let test_memory = EpisodicMemory::new(
        ChatRole::User,
        "This is a test message".to_string(),
        vec![0.1; 768],
    );

    match db.insert_episodic_memory(&test_memory) {
        Ok(_) => println!("✓ Test episodic memory saved"),
        Err(e) => eprintln!("✗ Failed to save memory: {}", e),
    }

    // Test identity creation
    let test_identity = UserIdentity::new(
        "Professional Role".to_string(),
        "Developer".to_string(),
        models::memory::IdentityCategory::Profession,
    );

    match db.insert_user_identity(&test_identity) {
        Ok(_) => println!("✓ User identity saved"),
        Err(e) => eprintln!("✗ Failed to save identity: {}", e),
    }

    println!("\n✓ Anima backend ready to run");
    println!("Waiting for connections...");
}
