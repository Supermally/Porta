use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GogPlayTask {
    #[serde(default)]
    pub path: String,
    #[serde(default)]
    pub is_primary: bool,
    #[serde(rename = "type", default)]
    pub task_type: String,
    #[serde(default)]
    pub arguments: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GogInfoJson {
    #[serde(rename = "gameId", default)]
    pub game_id: String,
    #[serde(rename = "rootGameId", default)]
    pub root_game_id: String,
    #[serde(default)]
    pub name: String,
    #[serde(rename = "playTasks", default)]
    pub play_tasks: Vec<GogPlayTask>,
    #[serde(default)]
    pub version: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GogGameDetails {
    pub game_id: String,
    pub name: String,
    pub install_path: PathBuf,
    pub executable_path: PathBuf,
    pub is_native_macos: bool,
    pub cloud_save_path: Option<PathBuf>,
    pub store_url: String,
}

pub struct GogStorefrontManager;

impl GogStorefrontManager {
    pub fn get_gog_storage_dir() -> PathBuf {
        dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Library/Application Support/GOG.com/Galaxy")
    }

    pub fn scan_gog_games() -> Vec<GogGameDetails> {
        let mut games = Vec::new();
        let search_roots = [
            dirs::home_dir().unwrap_or_else(|| PathBuf::from(".")).join("GOG Games"),
            PathBuf::from("/Applications"),
            dirs::home_dir().unwrap_or_else(|| PathBuf::from(".")).join("Library/Application Support/Forge/prefixes"),
        ];

        for root in &search_roots {
            if !root.exists() {
                continue;
            }

            for entry in walkdir::WalkDir::new(root).max_depth(3).into_iter().flatten() {
                let path = entry.path();
                let file_name = path.file_name().unwrap_or_default().to_string_lossy();

                if file_name.starts_with("goggame-") && file_name.ends_with(".info") {
                    if let Some(game) = Self::parse_gog_info_file(path) {
                        if !games.iter().any(|g: &GogGameDetails| g.game_id == game.game_id) {
                            games.push(game);
                        }
                    }
                }
            }
        }

        games
    }

    pub fn parse_gog_info_file(info_path: &Path) -> Option<GogGameDetails> {
        let content = fs::read_to_string(info_path).ok()?;
        let info: GogInfoJson = serde_json::from_str(&content).ok()?;
        let game_dir = info_path.parent()?.to_path_buf();

        let mut exec_path = game_dir.clone();
        let mut is_native = false;

        if let Some(primary) = info.play_tasks.iter().find(|t| t.is_primary).or_else(|| info.play_tasks.first()) {
            let candidate = game_dir.join(&primary.path);
            if candidate.exists() {
                exec_path = candidate;
                is_native = exec_path.extension().map_or(false, |e| e == "app");
            }
        }

        if exec_path == game_dir {
            // Check for .app or .exe
            if let Ok(entries) = fs::read_dir(&game_dir) {
                for entry in entries.flatten() {
                    let p = entry.path();
                    if p.extension().map_or(false, |e| e == "app") {
                        exec_path = p;
                        is_native = true;
                        break;
                    } else if p.extension().map_or(false, |e| e.to_string_lossy().to_lowercase() == "exe") {
                        exec_path = p;
                        is_native = false;
                        break;
                    }
                }
            }
        }

        let store_url = format!("https://www.gog.com/game/{}", info.game_id);
        let cloud_save_path = dirs::home_dir()
            .map(|h| h.join("Library/Application Support/GOG.com/Galaxy/storage/saves").join(&info.game_id));

        Some(GogGameDetails {
            game_id: info.game_id,
            name: if info.name.is_empty() { game_dir.file_name().unwrap_or_default().to_string_lossy().to_string() } else { info.name },
            install_path: game_dir,
            executable_path: exec_path,
            is_native_macos: is_native,
            cloud_save_path: cloud_save_path.filter(|p| p.exists()),
            store_url,
        })
    }

    pub fn build_offline_installer_command(runner: &str, setup_path: &Path) -> (String, Vec<String>) {
        (
            runner.to_string(),
            vec![
                setup_path.display().to_string(),
                "/SILENT".to_string(),
                "/VERYSILENT".to_string(),
                "/SUPPRESSMSGBOXES".to_string(),
                "/NORESTART".to_string(),
            ],
        )
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EpicHeroicGameDetails {
    pub app_name: String,
    pub title: String,
    pub install_path: PathBuf,
    pub executable_path: PathBuf,
    pub version: String,
    pub is_native_macos: bool,
}

pub struct EpicHeroicStorefrontManager;

impl EpicHeroicStorefrontManager {
    pub fn scan_installed_epic_games() -> Vec<EpicHeroicGameDetails> {
        let mut games = Vec::new();

        // 1. Check Heroic / Legendary installed.json
        let heroic_installed_json = dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Library/Application Support/heroic/legendaryConfig/legendary/installed.json");

        if heroic_installed_json.exists() {
            if let Ok(content) = fs::read_to_string(&heroic_installed_json) {
                if let Ok(json_map) = serde_json::from_str::<serde_json::Value>(&content) {
                    if let Some(obj) = json_map.as_object() {
                        for (app_name, val) in obj {
                            let title = val.get("title").and_then(|v| v.as_str()).unwrap_or(app_name).to_string();
                            let install_path_str = val.get("install_path").and_then(|v| v.as_str()).unwrap_or_default();
                            let exe_str = val.get("executable").and_then(|v| v.as_str()).unwrap_or_default();
                            let version = val.get("version").and_then(|v| v.as_str()).unwrap_or("1.0").to_string();

                            let install_path = PathBuf::from(install_path_str);
                            let exec_path = if !exe_str.is_empty() {
                                install_path.join(exe_str)
                            } else {
                                install_path.clone()
                            };

                            let is_native = exec_path.extension().map_or(false, |e| e == "app");

                            if install_path.exists() {
                                games.push(EpicHeroicGameDetails {
                                    app_name: app_name.clone(),
                                    title,
                                    install_path,
                                    executable_path: exec_path,
                                    version,
                                    is_native_macos: is_native,
                                });
                            }
                        }
                    }
                }
            }
        }

        // 2. Check Epic Games Launcher Manifests (*.item)
        let epic_manifest_dir = dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Library/Application Support/Epic/EpicGamesLauncher/Data/Manifests");

        if epic_manifest_dir.exists() {
            if let Ok(entries) = fs::read_dir(epic_manifest_dir) {
                for entry in entries.flatten() {
                    let path = entry.path();
                    if path.extension().map_or(false, |e| e == "item") {
                        if let Ok(content) = fs::read_to_string(&path) {
                            if let Ok(json) = serde_json::from_str::<serde_json::Value>(&content) {
                                let app_name = json.get("AppName").and_then(|v| v.as_str()).unwrap_or_default().to_string();
                                let title = json.get("DisplayName").and_then(|v| v.as_str()).unwrap_or(&app_name).to_string();
                                let install_loc = json.get("InstallLocation").and_then(|v| v.as_str()).unwrap_or_default();
                                let launch_exe = json.get("LaunchExecutable").and_then(|v| v.as_str()).unwrap_or_default();

                                let install_path = PathBuf::from(install_loc);
                                let exec_path = install_path.join(launch_exe);
                                let is_native = exec_path.extension().map_or(false, |e| e == "app");

                                if install_path.exists() && !games.iter().any(|g| g.app_name == app_name) {
                                    games.push(EpicHeroicGameDetails {
                                        app_name,
                                        title,
                                        install_path,
                                        executable_path: exec_path,
                                        version: "Latest".to_string(),
                                        is_native_macos: is_native,
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }

        games
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn test_gog_info_parsing() {
        let temp = tempdir().unwrap();
        let gog_dir = temp.path().join("The Witcher 3");
        fs::create_dir_all(&gog_dir).unwrap();

        let info_file = gog_dir.join("goggame-1207664643.info");
        let sample = r#"{
            "gameId": "1207664643",
            "rootGameId": "1207664643",
            "name": "The Witcher 3: Wild Hunt",
            "playTasks": [
                {
                    "path": "bin/x64/witcher3.exe",
                    "isPrimary": true,
                    "type": "FileTask"
                }
            ]
        }"#;
        fs::write(&info_file, sample).unwrap();

        let parsed = GogStorefrontManager::parse_gog_info_file(&info_file).unwrap();
        assert_eq!(parsed.game_id, "1207664643");
        assert_eq!(parsed.name, "The Witcher 3: Wild Hunt");
    }

    #[test]
    fn test_gog_offline_installer_args() {
        let (runner, args) = GogStorefrontManager::build_offline_installer_command("wine64", Path::new("/path/to/setup.exe"));
        assert_eq!(runner, "wine64");
        assert!(args.contains(&"/SILENT".to_string()));
        assert!(args.contains(&"/VERYSILENT".to_string()));
    }
}
