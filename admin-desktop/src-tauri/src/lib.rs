use tauri::Manager;

#[tauri::command]
fn get_api_url() -> String {
    std::env::var("QUICKPASS_API_URL").unwrap_or_else(|_| "http://localhost:3000".to_string())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .setup(|app| {
            let window = app.get_webview_window("main").unwrap();
            window.set_title("Quickpass Admin").ok();
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![get_api_url])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
