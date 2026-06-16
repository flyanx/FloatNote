// Platform alias: "desktop" = Windows / macOS / Linux
#![cfg_attr(
    any(target_os = "windows", target_os = "macos", target_os = "linux"),
    cfg(desktop)
)]
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

// ========== Desktop-only imports ==========
#[cfg(desktop)]
use std::{
    net::{TcpListener, TcpStream},
    io::{Write, Cursor},
    sync::Mutex,
    thread,
    time::Duration,
};

#[cfg(desktop)]
use tauri::{
    menu::{Menu, MenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    Manager, WindowEvent,
};

#[cfg(desktop)]
use tauri_plugin_notification::NotificationExt;

#[cfg(desktop)]
use base64::prelude::*;
#[cfg(desktop)]
use image::codecs::png::PngEncoder;
#[cfg(desktop)]
use image::ImageEncoder;

// ========== Desktop-only constants & structs ==========
#[cfg(desktop)]
const SINGLE_INSTANCE_PORT: u16 = 19483;

#[cfg(desktop)]
struct TrayState {
    tray: Mutex<Option<tauri::tray::TrayIcon>>,
    single_instance_listener: Mutex<Option<TcpListener>>,
}

#[cfg(desktop)]
struct ScreenshotState {
    image: Mutex<Option<image::RgbaImage>>,
}

// ========== Desktop-only functions ==========
#[cfg(desktop)]
fn acquire_single_instance() -> Option<TcpListener> {
    match TcpListener::bind(("127.0.0.1", SINGLE_INSTANCE_PORT)) {
        Ok(listener) => {
            let _ = listener.set_nonblocking(true);
            Some(listener)
        }
        Err(_) => {
            if let Ok(mut stream) = TcpStream::connect(("127.0.0.1", SINGLE_INSTANCE_PORT)) {
                let _ = stream.write_all(b"show\n");
            }
            None
        }
    }
}

#[cfg(desktop)]
#[tauri::command]
fn save_markdown_file(title: String, content: String) -> Result<String, String> {
    let default_name = format!("{}.md", title);
    let dialog = rfd::FileDialog::new()
        .set_file_name(&default_name)
        .add_filter("Markdown", &["md", "markdown"]);
    if let Some(path) = dialog.save_file() {
        let path = if path.extension().is_none() { path.with_extension("md") } else { path };
        std::fs::write(&path, content.as_bytes()).map_err(|e| format!("写入失败: {}", e))?;
        Ok(path.to_string_lossy().to_string())
    } else {
        Ok(String::new())
    }
}

#[cfg(desktop)]
#[tauri::command]
fn set_skip_taskbar(window: tauri::WebviewWindow, skip: bool) -> Result<(), String> {
    window.set_skip_taskbar(skip).map_err(|e| format!("set_skip_taskbar failed: {}", e))
}

#[cfg(desktop)]
#[tauri::command(async)]
fn capture_screen(state: tauri::State<ScreenshotState>) -> Result<serde_json::Value, String> {
    println!("[截图] 开始截取屏幕...");
    let monitors = xcap::Monitor::all().map_err(|e| format!("获取显示器列表失败: {}", e))?;
    println!("[截图] 找到 {} 个显示器", monitors.len());
    let monitor = monitors.iter()
        .find(|m| m.is_primary().unwrap_or(false))
        .or_else(|| monitors.first())
        .ok_or_else(|| "未找到显示器".to_string())?;

    let img = monitor.capture_image().map_err(|e| format!("截屏失败: {}", e))?;
    let (w, h) = (img.width(), img.height());

    // 存入 state
    {
        let mut guard = state.image.lock().map_err(|e| format!("锁失败: {}", e))?;
        *guard = Some(img.clone());
    }

    // 编码为 PNG base64
    let mut buf = Cursor::new(Vec::new());
    let encoder = PngEncoder::new(&mut buf);
    encoder.write_image(
        img.as_raw(),
        w, h,
        image::ExtendedColorType::Rgba8,
    ).map_err(|e| format!("PNG 编码失败: {}", e))?;

    let b64 = BASE64_STANDARD.encode(buf.get_ref());
    let data_url = format!("data:image/png;base64,{}", b64);

    Ok(serde_json::json!({
        "dataUrl": data_url,
        "imgWidth": w,
        "imgHeight": h
    }))
}

#[cfg(desktop)]
#[tauri::command(async)]
fn finish_region_screenshot(
    state: tauri::State<ScreenshotState>,
    x: u32, y: u32, width: u32, height: u32,
) -> Result<(), String> {
    let img = {
        let mut guard = state.image.lock().map_err(|e| format!("锁失败: {}", e))?;
        guard.take().ok_or_else(|| "无可用的截图数据".to_string())?
    };

    // 裁剪
    let cropped = image::imageops::crop_imm(&img, x, y, width, height).to_image();

    // 写入剪贴板
    let mut clipboard = arboard::Clipboard::new().map_err(|e| format!("打开剪贴板失败: {}", e))?;
    clipboard.set_image(arboard::ImageData {
        width: cropped.width() as usize,
        height: cropped.height() as usize,
        bytes: cropped.into_raw().into(),
    }).map_err(|e| format!("写入剪贴板失败: {}", e))?;

    Ok(())
}

#[cfg(desktop)]
#[tauri::command]
fn cancel_region_screenshot(state: tauri::State<ScreenshotState>) -> Result<(), String> {
    let mut guard = state.image.lock().map_err(|e| format!("锁失败: {}", e))?;
    *guard = None;
    Ok(())
}

#[cfg(desktop)]
#[tauri::command(async)]
fn get_screenshot_data(state: tauri::State<ScreenshotState>) -> Result<serde_json::Value, String> {
    let guard = state.image.lock().map_err(|e| format!("锁失败: {}", e))?;
    match guard.as_ref() {
        Some(img) => {
            let (w, h) = (img.width(), img.height());
            let mut buf = Cursor::new(Vec::new());
            let encoder = PngEncoder::new(&mut buf);
            encoder.write_image(
                img.as_raw(), w, h,
                image::ExtendedColorType::Rgba8,
            ).map_err(|e| format!("PNG 编码失败: {}", e))?;
            let b64 = BASE64_STANDARD.encode(buf.get_ref());
            let data_url = format!("data:image/png;base64,{}", b64);
            Ok(serde_json::json!({
                "dataUrl": data_url,
                "imgWidth": w,
                "imgHeight": h
            }))
        }
        None => Err("无可用的截图数据".to_string()),
    }
}

#[cfg(desktop)]
#[tauri::command(async)]
async fn supabase_request(
    url: String,
    method: String,
    api_key: String,
    body: Option<String>,
    prefer: Option<String>,
) -> Result<serde_json::Value, String> {
    let client = reqwest::Client::new();
    let method = method.to_uppercase();

    let mut req = match method.as_str() {
        "GET" => client.get(&url),
        "PATCH" => client.patch(&url),
        "POST" => client.post(&url),
        "PUT" => client.put(&url),
        "DELETE" => client.delete(&url),
        _ => return Err(format!("不支持的 HTTP 方法: {}", method)),
    };

    let prefer_header = prefer.unwrap_or_else(|| "return=minimal".to_string());
    req = req
        .header("apikey", &api_key)
        .header("Authorization", format!("Bearer {}", &api_key))
        .header("Content-Type", "application/json")
        .header("Prefer", &prefer_header);

    if let Some(body_str) = body {
        req = req.body(body_str);
    }

    let resp = req.send().await.map_err(|e| format!("网络请求失败: {}", e))?;
    let status = resp.status().as_u16();
    let text = resp.text().await.map_err(|e| format!("读取响应失败: {}", e))?;

    let body_val: serde_json::Value = serde_json::from_str(&text)
        .unwrap_or(serde_json::Value::String(text.clone()));

    Ok(serde_json::json!({
        "status": status,
        "body": body_val,
        "ok": status >= 200 && status < 300,
    }))
}

// ========== 配置文件持久化（绕过 localStorage 丢失问题） ==========
#[cfg(desktop)]
#[tauri::command]
fn save_config_to_file(app: tauri::AppHandle, data: String) -> Result<(), String> {
    let data_dir = app.path().app_data_dir().map_err(|e| format!("获取数据目录失败: {}", e))?;
    std::fs::create_dir_all(&data_dir).map_err(|e| format!("创建目录失败: {}", e))?;
    let config_path = data_dir.join("supabase-config.json");
    std::fs::write(&config_path, data).map_err(|e| format!("写入配置失败: {}", e))?;
    Ok(())
}

#[cfg(desktop)]
#[tauri::command]
fn load_config_from_file(app: tauri::AppHandle) -> Result<String, String> {
    let data_dir = app.path().app_data_dir().map_err(|e| format!("获取数据目录失败: {}", e))?;
    let config_path = data_dir.join("supabase-config.json");
    if !config_path.exists() {
        return Ok("{}".to_string());
    }
    std::fs::read_to_string(&config_path).map_err(|e| format!("读取配置失败: {}", e))
}

// ========== Cross-platform entry point ==========
#[cfg_attr(mobile, tauri::mobile_entry_point)]
fn run() {
    let builder = tauri::Builder::default()
        .plugin(tauri_plugin_store::Builder::new().build())
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_devtools::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init());

    // Desktop-only: plugins, commands, state, setup
    #[cfg(desktop)]
    let builder = builder
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .invoke_handler(tauri::generate_handler![
            save_markdown_file, set_skip_taskbar,
            capture_screen, finish_region_screenshot, cancel_region_screenshot,
            get_screenshot_data,
            supabase_request,
            save_config_to_file, load_config_from_file,
        ])
        .manage(TrayState {
            tray: Mutex::new(None),
            single_instance_listener: Mutex::new(None),
        })
        .manage(ScreenshotState {
            image: Mutex::new(None),
        })
        .setup(|app| {
            // Single instance
            let listener = acquire_single_instance();
            if listener.is_none() { std::process::exit(0); }
            let listener = listener.unwrap();

            let state = app.state::<TrayState>();
            *state.single_instance_listener.lock().unwrap() = Some(listener);

            // System tray
            let show_item = MenuItem::with_id(app, "show", "显示窗口", true, None::<&str>)?;
            let quit_item = MenuItem::with_id(app, "quit", "退出灵签", true, None::<&str>)?;
            let menu = Menu::with_items(app, &[&show_item, &quit_item])?;

            fn restore_window(app: &tauri::AppHandle) {
                if let Some(window) = app.get_webview_window("main") {
                    let _ = window.unminimize();
                    let _ = window.show();
                    let _ = window.set_focus();
                }
            }

            let tray = TrayIconBuilder::new()
                .icon(app.default_window_icon().unwrap().clone())
                .tooltip("灵签 FloatNote")
                .menu(&menu)
                .on_menu_event(|app, event| {
                    match event.id().as_ref() {
                        "show" => restore_window(app),
                        "quit" => { app.exit(0); }
                        _ => {}
                    }
                })
                .on_tray_icon_event(|tray, event| {
                    match event {
                        TrayIconEvent::Click {
                            button: MouseButton::Left,
                            button_state: MouseButtonState::Up, ..
                        } => {
                            restore_window(tray.app_handle());
                        }
                        TrayIconEvent::DoubleClick {
                            button: MouseButton::Left, ..
                        } => {
                            restore_window(tray.app_handle());
                        }
                        _ => {}
                    }
                })
                .build(app)?;

            let state = app.state::<TrayState>();
            *state.tray.lock().unwrap() = Some(tray);

            // Window events: close-to-tray + desktop notifications
            if let Some(window) = app.get_webview_window("main") {
                let w = window.clone();
                let handle = app.handle().clone();
                window.on_window_event(move |event| {
                    if let WindowEvent::CloseRequested { api, .. } = event {
                        api.prevent_close();
                        let _ = w.hide();

                        let _ = handle.notification()
                            .builder()
                            .title("灵签 FloatNote")
                            .body("已收纳到系统托盘，双击托盘图标即可恢复")
                            .show();
                    }
                    if let WindowEvent::Focused(focused) = event {
                        if *focused && w.is_minimized().unwrap_or(false) {
                            let _ = w.unminimize();
                            let _ = w.show();
                            let _ = w.set_focus();
                        }
                    }
                });
            }

            // Single instance listener
            let handle = app.handle().clone();
            thread::spawn(move || {
                loop {
                    thread::sleep(Duration::from_millis(300));
                    let state = handle.state::<TrayState>();
                    let guard = state.single_instance_listener.lock().unwrap();
                    if let Some(ref listener) = *guard {
                        if let Ok((mut stream, _)) = listener.accept() {
                            restore_window(&handle);
                            let _ = stream.write_all(b"ok\n");
                        }
                    }
                    drop(guard);
                }
            });

            Ok(())
        });

    builder
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

fn main() {
    run();
}
