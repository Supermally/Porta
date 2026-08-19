use crate::vdf::{VdfParser, VdfValue};
use serde::{Deserialize, Serialize};
use std::fs::File;
use std::io::Write;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SteamUserAccount {
    pub steam_id_64: String,
    pub account_name: String,
    pub persona_name: String,
    pub is_most_recent: bool,
    pub remember_password: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SteamLibraryFolder {
    pub path: PathBuf,
    pub label: String,
    pub total_size_bytes: u64,
    pub installed_app_ids: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SteamGameDetails {
    pub app_id: String,
    pub name: String,
    pub install_dir_name: String,
    pub install_path: PathBuf,
    pub executable_path: PathBuf,
    pub is_native_macos: bool,
    pub size_bytes: u64,
    pub state_flags: u32, // 4 = Fully installed
    pub cloud_save_path: Option<PathBuf>,
    pub steam_header_image_url: String,
}

pub struct DeepSteamManager;

impl DeepSteamManager {
    pub fn get_steam_root_dir() -> PathBuf {
        dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Library/Application Support/Steam")
    }

    pub fn discover_active_steam_users() -> Vec<SteamUserAccount> {
        let login_users_path = Self::get_steam_root_dir().join("config/loginusers.vdf");
        if !login_users_path.exists() {
            return Vec::new();
        }

        let Ok(content) = std::fs::read_to_string(&login_users_path) else {
            return Vec::new();
        };

        let Ok(vdf) = VdfParser::parse(&content) else {
            return Vec::new();
        };

        let mut users = Vec::new();
        if let Some(VdfValue::Obj(users_obj)) = vdf.get("users") {
            for (steam_id, val) in users_obj {
                if let VdfValue::Obj(user_data) = val {
                    let account_name = user_data.get("AccountName").and_then(|v| v.as_str()).unwrap_or_default().to_string();
                    let persona_name = user_data.get("PersonaName").and_then(|v| v.as_str()).unwrap_or(&account_name).to_string();
                    let is_most_recent = user_data.get("MostRecent").and_then(|v| v.as_str()).map_or(false, |s| s == "1");
                    let remember = user_data.get("RememberPassword").and_then(|v| v.as_str()).map_or(false, |s| s == "1");

                    users.push(SteamUserAccount {
                        steam_id_64: steam_id.clone(),
                        account_name,
                        persona_name,
                        is_most_recent,
                        remember_password: remember,
                    });
                }
            }
        }

        users
    }

    pub fn discover_library_folders() -> Vec<SteamLibraryFolder> {
        let library_vdf = Self::get_steam_root_dir().join("steamapps/libraryfolders.vdf");
        let mut folders = Vec::new();

        // Always add the default Steam library
        let default_lib = Self::get_steam_root_dir().join("steamapps");
        if default_lib.exists() {
            folders.push(SteamLibraryFolder {
                path: default_lib,
                label: "Primary Mac Storage".to_string(),
                total_size_bytes: 0,
                installed_app_ids: Vec::new(),
            });
        }

        if library_vdf.exists() {
            if let Ok(content) = std::fs::read_to_string(&library_vdf) {
                if let Ok(vdf) = VdfParser::parse(&content) {
                    if let Some(VdfValue::Obj(lib_folders)) = vdf.get("libraryfolders") {
                        for (_idx, val) in lib_folders {
                            if let VdfValue::Obj(folder_data) = val {
                                if let Some(path_str) = folder_data.get("path").and_then(|v| v.as_str()) {
                                    let steamapps_path = PathBuf::from(path_str).join("steamapps");
                                    let label = folder_data.get("label").and_then(|v| v.as_str()).unwrap_or("Steam Library").to_string();

                                    let mut app_ids = Vec::new();
                                    if let Some(VdfValue::Obj(apps)) = folder_data.get("apps") {
                                        for (app_id, _) in apps {
                                            app_ids.push(app_id.clone());
                                        }
                                    }

                                    if !folders.iter().any(|f| f.path == steamapps_path) && steamapps_path.exists() {
                                        folders.push(SteamLibraryFolder {
                                            path: steamapps_path,
                                            label,
                                            total_size_bytes: 0,
                                            installed_app_ids: app_ids,
                                        });
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        folders
    }

    pub fn scan_all_installed_steam_games() -> Vec<SteamGameDetails> {
        let folders = Self::discover_library_folders();
        let mut games = Vec::new();

        for folder in folders {
            if let Ok(entries) = std::fs::read_dir(&folder.path) {
                for entry in entries.flatten() {
                    let path = entry.path();
                    let file_name = path.file_name().unwrap_or_default().to_string_lossy();

                    if file_name.starts_with("appmanifest_") && file_name.ends_with(".acf") {
                        if let Some(game) = Self::parse_manifest_file(&path, &folder.path) {
                            games.push(game);
                        }
                    }
                }
            }
        }

        games
    }

    pub fn parse_manifest_file(manifest_path: &Path, steamapps_dir: &Path) -> Option<SteamGameDetails> {
        let content = std::fs::read_to_string(manifest_path).ok()?;
        let vdf = VdfParser::parse(&content).ok()?;
        let app_state = vdf.get("AppState")?.as_obj()?;

        let app_id = app_state.get("appid")?.as_str()?.to_string();
        let name = app_state.get("name")?.as_str()?.to_string();
        let install_dir_name = app_state.get("installdir")?.as_str()?.to_string();
        let size_bytes = app_state.get("SizeOnDisk").and_then(|v| v.as_str()).and_then(|s| s.parse::<u64>().ok()).unwrap_or(0);
        let state_flags = app_state.get("StateFlags").and_then(|v| v.as_str()).and_then(|s| s.parse::<u32>().ok()).unwrap_or(4);

        let common_dir = steamapps_dir.join("common").join(&install_dir_name);
        if !common_dir.exists() {
            return None;
        }

        let (executable_path, is_native) = Self::resolve_game_binary(&common_dir);

        let steam_header_image_url = format!("https://cdn.cloudflare.steamstatic.com/steam/apps/{}/header.jpg", app_id);

        // Detect Steam Cloud Save Directory
        let cloud_save_path = Self::resolve_cloud_save_path(&app_id);

        Some(SteamGameDetails {
            app_id,
            name,
            install_dir_name,
            install_path: common_dir,
            executable_path,
            is_native_macos: is_native,
            size_bytes,
            state_flags,
            cloud_save_path,
            steam_header_image_url,
        })
    }

    fn resolve_game_binary(game_dir: &Path) -> (PathBuf, bool) {
        // 1. Check for native macOS app bundle
        if let Ok(entries) = std::fs::read_dir(game_dir) {
            for entry in entries.flatten() {
                let p = entry.path();
                if p.extension().map_or(false, |ext| ext == "app") {
                    return (p, true);
                }
            }
        }

        // 2. Check for Windows executable (.exe)
        let mut exe_candidates = Vec::new();
        for entry in walkdir::WalkDir::new(game_dir).max_depth(3).into_iter().flatten() {
            let p = entry.path();
            if p.extension().map_or(false, |ext| ext.to_string_lossy().to_lowercase() == "exe") {
                let stem = p.file_stem().unwrap_or_default().to_string_lossy().to_lowercase();
                if !stem.contains("unins") && !stem.contains("crash") && !stem.contains("setup") && !stem.contains("redist") {
                    exe_candidates.push(p.to_path_buf());
                }
            }
        }

        if let Some(first_exe) = exe_candidates.first() {
            return (first_exe.clone(), false);
        }

        (game_dir.to_path_buf(), false)
    }

    fn resolve_cloud_save_path(app_id: &str) -> Option<PathBuf> {
        let userdata_dir = Self::get_steam_root_dir().join("userdata");
        if !userdata_dir.exists() {
            return None;
        }

        if let Ok(entries) = std::fs::read_dir(&userdata_dir) {
            for entry in entries.flatten() {
                let save_candidate = entry.path().join(app_id).join("remote");
                if save_candidate.exists() {
                    return Some(save_candidate);
                }
            }
        }

        None
    }

    pub fn prepare_steam_api_environment(game: &SteamGameDetails, prefix_dir: &Path) -> Result<(), std::io::Error> {
        // Automatically create steam_appid.txt in game directory so SteamAPI initializes properly
        let appid_file = game.install_path.join("steam_appid.txt");
        let mut file = File::create(appid_file)?;
        file.write_all(game.app_id.as_bytes())?;

        // Also place it in prefix directory
        let prefix_appid = prefix_dir.join("steam_appid.txt");
        if let Ok(mut f) = File::create(prefix_appid) {
            let _ = f.write_all(game.app_id.as_bytes());
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_steam_root_and_discovery() {
        let root = DeepSteamManager::get_steam_root_dir();
        assert!(root.display().to_string().contains("Steam"));
        let _users = DeepSteamManager::discover_active_steam_users();
        let _folders = DeepSteamManager::discover_library_folders();
    }
}
