use mac_gaming_core::{LaunchOverrideOptions, MacGamingEngine};
use serde_json::json;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

fn to_c_string<T: serde::Serialize>(val: &T) -> *mut c_char {
    let json_str = serde_json::to_string(val).unwrap_or_else(|e| {
        json!({ "error": format!("Serialization failed: {}", e) }).to_string()
    });
    CString::new(json_str).unwrap_or_default().into_raw()
}

fn error_to_c_string(err_msg: &str) -> *mut c_char {
    let json_str = json!({ "error": err_msg }).to_string();
    CString::new(json_str).unwrap_or_default().into_raw()
}

fn c_str_to_str<'a>(ptr: *const c_char) -> Option<&'a str> {
    if ptr.is_null() {
        None
    } else {
        unsafe { CStr::from_ptr(ptr).to_str().ok() }
    }
}

#[no_mangle]
pub extern "C" fn mac_gaming_engine_new() -> *mut MacGamingEngine {
    match MacGamingEngine::init() {
        Ok(engine) => Box::into_raw(Box::new(engine)),
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn mac_gaming_engine_free(handle: *mut MacGamingEngine) {
    if !handle.is_null() {
        unsafe {
            let _ = Box::from_raw(handle);
        }
    }
}

#[no_mangle]
pub extern "C" fn mac_gaming_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}

#[no_mangle]
pub extern "C" fn mac_gaming_diagnostics_json(handle: *mut MacGamingEngine) -> *mut c_char {
    if handle.is_null() {
        return error_to_c_string("Engine handle is null");
    }
    let engine = unsafe { &*handle };
    to_c_string(&engine.diagnostics)
}

#[no_mangle]
pub extern "C" fn mac_gaming_scan_all_json(handle: *mut MacGamingEngine) -> *mut c_char {
    if handle.is_null() {
        return error_to_c_string("Engine handle is null");
    }
    let engine = unsafe { &*handle };
    match engine.scan_all_storefronts() {
        Ok(games) => to_c_string(&games),
        Err(e) => error_to_c_string(&e.to_string()),
    }
}

#[no_mangle]
pub extern "C" fn mac_gaming_scan_storefront_json(
    handle: *mut MacGamingEngine,
    storefront_str: *const c_char,
) -> *mut c_char {
    if handle.is_null() {
        return error_to_c_string("Engine handle is null");
    }
    let engine = unsafe { &*handle };
    let sf = c_str_to_str(storefront_str).unwrap_or("all").to_lowercase();

    let res = match sf.as_str() {
        "steam" => engine.scan_steam(),
        "epic" => engine.scan_epic(),
        "gog" => engine.scan_gog(),
        "itch" => engine.scan_itch(),
        "ubisoft" => engine.scan_ubisoft(),
        "ea" => engine.scan_ea(),
        "battlenet" | "bnet" => engine.scan_battlenet(),
        _ => engine.scan_all_storefronts(),
    };

    match res {
        Ok(games) => to_c_string(&games),
        Err(e) => error_to_c_string(&e.to_string()),
    }
}

#[no_mangle]
pub extern "C" fn mac_gaming_get_all_games_json(handle: *mut MacGamingEngine) -> *mut c_char {
    if handle.is_null() {
        return error_to_c_string("Engine handle is null");
    }
    let engine = unsafe { &*handle };
    match engine.get_all_games() {
        Ok(games) => to_c_string(&games),
        Err(e) => error_to_c_string(&e.to_string()),
    }
}

#[no_mangle]
pub extern "C" fn mac_gaming_import_game_json(
    handle: *mut MacGamingEngine,
    path_ptr: *const c_char,
    title_ptr: *const c_char,
) -> *mut c_char {
    if handle.is_null() {
        return error_to_c_string("Engine handle is null");
    }
    let path = match c_str_to_str(path_ptr) {
        Some(p) => p,
        None => return error_to_c_string("Invalid path pointer"),
    };
    let title = c_str_to_str(title_ptr);

    let engine = unsafe { &*handle };
    match engine.import_custom_game(path, title) {
        Ok(game) => to_c_string(&game),
        Err(e) => error_to_c_string(&e.to_string()),
    }
}

#[no_mangle]
pub extern "C" fn mac_gaming_import_universal_app_json(
    handle: *mut MacGamingEngine,
    path_ptr: *const c_char,
    title_ptr: *const c_char,
) -> *mut c_char {
    if handle.is_null() {
        return error_to_c_string("Engine handle is null");
    }
    let path = match c_str_to_str(path_ptr) {
        Some(p) => p,
        None => return error_to_c_string("Invalid path pointer"),
    };
    let title = c_str_to_str(title_ptr);

    let engine = unsafe { &*handle };
    match engine.import_universal_application(path, title) {
        Ok(app) => to_c_string(&app),
        Err(e) => error_to_c_string(&e.to_string()),
    }
}

#[no_mangle]
pub extern "C" fn mac_gaming_prepare_launch_json(
    handle: *mut MacGamingEngine,
    game_id_ptr: *const c_char,
    force_d3dmetal: bool,
    force_dxvk: bool,
    enable_hud: bool,
    enable_esync: bool,
    enable_fsync: bool,
) -> *mut c_char {
    if handle.is_null() {
        return error_to_c_string("Engine handle is null");
    }
    let game_id = match c_str_to_str(game_id_ptr) {
        Some(id) => id,
        None => return error_to_c_string("Invalid game ID pointer"),
    };

    let override_opts = LaunchOverrideOptions {
        force_d3dmetal: if force_d3dmetal { Some(true) } else { None },
        force_dxvk: if force_dxvk { Some(true) } else { None },
        enable_hud: if enable_hud { Some(true) } else { None },
        enable_esync: Some(enable_esync),
        enable_fsync: Some(enable_fsync),
        extra_args: Vec::new(),
    };

    let engine = unsafe { &*handle };
    match engine.prepare_launch_with_options(game_id, Some(&override_opts)) {
        Ok(env) => to_c_string(&env),
        Err(e) => error_to_c_string(&e.to_string()),
    }
}

#[no_mangle]
pub extern "C" fn mac_gaming_troubleshoot_json(
    handle: *mut MacGamingEngine,
    log_text_ptr: *const c_char,
) -> *mut c_char {
    if handle.is_null() {
        return error_to_c_string("Engine handle is null");
    }
    let log_text = c_str_to_str(log_text_ptr).unwrap_or_default();
    let engine = unsafe { &*handle };
    let report = engine.troubleshoot_log(log_text);
    to_c_string(&report)
}

#[no_mangle]
pub extern "C" fn mac_gaming_sync_community_profiles_json(handle: *mut MacGamingEngine) -> *mut c_char {
    if handle.is_null() {
        return error_to_c_string("Engine handle is null");
    }
    let engine = unsafe { &mut *handle };
    match engine.sync_community_profiles() {
        Ok(res) => to_c_string(&res),
        Err(e) => error_to_c_string(&e.to_string()),
    }
}

#[no_mangle]
pub extern "C" fn mac_gaming_check_provisioning_json(
    handle: *mut MacGamingEngine,
    game_id_ptr: *const c_char,
) -> *mut c_char {
    if handle.is_null() {
        return error_to_c_string("Engine handle is null");
    }
    let game_id = match c_str_to_str(game_id_ptr) {
        Some(id) => id,
        None => return error_to_c_string("Invalid game ID pointer"),
    };
    let engine = unsafe { &*handle };
    match engine.check_game_provisioning(game_id) {
        Ok(plan) => to_c_string(&plan),
        Err(e) => error_to_c_string(&e.to_string()),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_bridge_engine_lifecycle_and_troubleshoot() {
        let handle = mac_gaming_engine_new();
        assert!(!handle.is_null());

        let diag_ptr = mac_gaming_diagnostics_json(handle);
        assert!(!diag_ptr.is_null());
        let diag_str = unsafe { CStr::from_ptr(diag_ptr).to_str().unwrap() };
        assert!(diag_str.contains("chip_name"));
        mac_gaming_free_string(diag_ptr);

        let log = CString::new("0024:err:module:import_dll Library MSVCP140.dll not found").unwrap();
        let report_ptr = mac_gaming_troubleshoot_json(handle, log.as_ptr());
        assert!(!report_ptr.is_null());
        let report_str = unsafe { CStr::from_ptr(report_ptr).to_str().unwrap() };
        assert!(report_str.contains("Missing Microsoft Visual C++ Runtime"));
        mac_gaming_free_string(report_ptr);

        mac_gaming_engine_free(handle);
    }
}
