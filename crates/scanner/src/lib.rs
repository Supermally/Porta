pub mod steam_deep;
pub mod storefronts;
pub mod vdf;

pub use steam_deep::{DeepSteamManager, SteamGameDetails, SteamLibraryFolder, SteamUserAccount};
pub use storefronts::{EpicHeroicGameDetails, EpicHeroicStorefrontManager, GogGameDetails, GogStorefrontManager};

use forge_analyzer::{BinaryAnalysisReport, BinaryAnalyzer};
use forge_profiles::CompatibilityStatus;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use thiserror::Error;
use vdf::VdfParser;

#[derive(Error, Debug)]
pub enum ScannerError {
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
    #[error("VDF parse error: {0}")]
    Vdf(String),
    #[error("JSON parse error: {0}")]
    Json(#[from] serde_json::Error),
    #[error("Invalid target path: {0}")]
    InvalidPath(String),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Storefront {
    Steam,
    EpicGames,
    Heroic,
    Gog,
    ItchIo,
    UbisoftConnect,
    EaApp,
    BattleNet,
    UniversalApp,
    Local,
}

impl Storefront {
    pub fn display_name(&self) -> &'static str {
        match self {
            Self::Steam => "Steam",
            Self::EpicGames => "Epic Games",
            Self::Heroic => "Heroic Games",
            Self::Gog => "GOG Galaxy",
            Self::ItchIo => "itch.io",
            Self::UbisoftConnect => "Ubisoft Connect",
            Self::EaApp => "EA App",
            Self::BattleNet => "Battle.net",
            Self::UniversalApp => "Universal Windows App",
            Self::Local => "Local / Sideloaded",
        }
    }

    pub fn icon_name(&self) -> &'static str {
        match self {
            Self::Steam => "gamecontroller.fill",
            Self::EpicGames => "bolt.circle.fill",
            Self::Heroic => "shield.lefthalf.filled",
            Self::Gog => "globe.americas.fill",
            Self::ItchIo => "cube.transparent.fill",
            Self::UbisoftConnect => "circle.grid.cross.fill",
            Self::EaApp => "play.circle.fill",
            Self::BattleNet => "flame.fill",
            Self::UniversalApp => "macwindow.badge.plus",
            Self::Local => "folder.fill",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DiscoveredGame {
    pub id: String,
    pub title: String,
    pub storefront: Storefront,
    pub storefront_app_id: Option<String>,
    pub install_path: PathBuf,
    pub executable_path: PathBuf,
    pub is_native: bool,
    pub is_universal_app: bool,
    pub acquisition_path: String,
    pub detected_status: CompatibilityStatus,
    pub analysis: Option<BinaryAnalysisReport>,
}

// -----------------------------------------------------------------------------
// STEAM SCANNER
// -----------------------------------------------------------------------------
pub struct SteamScanner;

impl SteamScanner {
    pub fn default_steam_path() -> PathBuf {
        dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Library/Application Support/Steam")
    }

    pub fn scan_steam(steam_root: &Path) -> Result<Vec<DiscoveredGame>, ScannerError> {
        let mut games = Vec::new();
        let library_folders_file = steam_root.join("steamapps/libraryfolders.vdf");

        let mut library_paths = Vec::new();
        library_paths.push(steam_root.to_path_buf());

        if library_folders_file.exists() {
            if let Ok(content) = std::fs::read_to_string(&library_folders_file) {
                if let Ok(parsed) = VdfParser::parse(&content) {
                    if let Some(folders) = parsed.get("libraryfolders").and_then(|v| v.as_obj()) {
                        for (_idx, folder_obj) in folders {
                            if let Some(obj) = folder_obj.as_obj() {
                                if let Some(p) = obj.get("path").and_then(|v| v.as_str()) {
                                    let pb = PathBuf::from(p);
                                    if pb.exists() && !library_paths.contains(&pb) {
                                        library_paths.push(pb);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        for lib_path in library_paths {
            let steamapps = lib_path.join("steamapps");
            if !steamapps.exists() {
                continue;
            }

            let entries = match std::fs::read_dir(&steamapps) {
                Ok(e) => e,
                Err(_) => continue,
            };

            for entry in entries.flatten() {
                let file_name = entry.file_name().to_string_lossy().to_string();
                if file_name.starts_with("appmanifest_") && file_name.ends_with(".acf") {
                    if let Ok(content) = std::fs::read_to_string(entry.path()) {
                        if let Ok(parsed) = VdfParser::parse(&content) {
                            if let Some(app_state) = parsed.get("AppState").and_then(|v| v.as_obj()) {
                                let app_id = app_state.get("appid").and_then(|v| v.as_str()).unwrap_or_default();
                                let name = app_state.get("name").and_then(|v| v.as_str()).unwrap_or_default();
                                let install_dir_name = app_state.get("installdir").and_then(|v| v.as_str()).unwrap_or_default();

                                if app_id.is_empty() || name.is_empty() || install_dir_name.is_empty() {
                                    continue;
                                }

                                if name.contains("Steam Linux Runtime") || name.contains("Proton") || name.contains("Steamworks") {
                                    continue;
                                }

                                let game_dir = steamapps.join("common").join(install_dir_name);
                                if !game_dir.exists() {
                                    continue;
                                }

                                if let Some(game) = Self::inspect_steam_game(app_id, name, &game_dir) {
                                    games.push(game);
                                }
                            }
                        }
                    }
                }
            }
        }

        Ok(games)
    }

    fn inspect_steam_game(app_id: &str, title: &str, game_dir: &Path) -> Option<DiscoveredGame> {
        let mut candidates = Vec::new();

        for entry in walkdir::WalkDir::new(game_dir).max_depth(3).into_iter().flatten() {
            let path = entry.path();
            if path.is_file() {
                if let Some(ext) = path.extension() {
                    let ext_str = ext.to_string_lossy().to_lowercase();
                    if ext_str == "exe" {
                        candidates.push((path.to_path_buf(), false));
                    }
                }
            } else if path.is_dir() {
                if let Some(ext) = path.extension() {
                    if ext.to_string_lossy().to_lowercase() == "app" {
                        candidates.push((path.to_path_buf(), true));
                    }
                }
            }
        }

        // Prioritize native .app
        if let Some((native_path, _)) = candidates.iter().find(|(_, is_app)| *is_app) {
            return Some(DiscoveredGame {
                id: format!("steam_{}", app_id),
                title: title.to_string(),
                storefront: Storefront::Steam,
                storefront_app_id: Some(app_id.to_string()),
                install_path: game_dir.to_path_buf(),
                executable_path: native_path.clone(),
                is_native: true,
                is_universal_app: false,
                acquisition_path: "native_storefront".to_string(),
                detected_status: CompatibilityStatus::Native,
                analysis: None,
            });
        }

        // Windows .exe
        if let Some((exe_path, _)) = candidates.iter().find(|(p, _)| {
            let name = p.file_stem().unwrap_or_default().to_string_lossy().to_lowercase();
            !name.contains("unins") && !name.contains("crash") && !name.contains("redist")
        }) {
            let analysis = BinaryAnalyzer::analyze_file(exe_path).ok();
            let mut detected_status = CompatibilityStatus::Compatible;

            if let Some(ref rep) = analysis {
                if rep.anti_cheat == forge_analyzer::AntiCheatSignature::Vanguard {
                    detected_status = CompatibilityStatus::Unsupported;
                }
            }

            return Some(DiscoveredGame {
                id: format!("steam_{}", app_id),
                title: title.to_string(),
                storefront: Storefront::Steam,
                storefront_app_id: Some(app_id.to_string()),
                install_path: game_dir.to_path_buf(),
                executable_path: exe_path.clone(),
                is_native: false,
                is_universal_app: false,
                acquisition_path: "storefront_integration".to_string(),
                detected_status,
                analysis,
            });
        }

        None
    }
}

// -----------------------------------------------------------------------------
// EPIC GAMES & HEROIC SCANNER
// -----------------------------------------------------------------------------
pub struct EpicScanner;

#[derive(Deserialize)]
struct EpicManifestItem {
    #[serde(rename = "DisplayName")]
    display_name: Option<String>,
    #[serde(rename = "AppName")]
    app_name: Option<String>,
    #[serde(rename = "InstallLocation")]
    install_location: Option<String>,
    #[serde(rename = "LaunchExecutable")]
    launch_executable: Option<String>,
}

#[derive(Deserialize)]
struct HeroicInstalledGame {
    app_name: Option<String>,
    title: Option<String>,
    install_path: Option<String>,
    executable: Option<String>,
    is_installed: Option<bool>,
}

#[derive(Deserialize)]
struct HeroicInstalledRoot {
    #[serde(default)]
    installed: Vec<HeroicInstalledGame>,
}

impl EpicScanner {
    pub fn default_epic_manifests_path() -> PathBuf {
        dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Library/Application Support/Epic/EpicGamesLauncher/Data/Manifests")
    }

    pub fn default_heroic_config_path() -> PathBuf {
        dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join(".config/heroic/store/installed.json")
    }

    pub fn scan_epic(manifests_dir: &Path) -> Result<Vec<DiscoveredGame>, ScannerError> {
        let mut games = Vec::new();
        if !manifests_dir.exists() {
            return Ok(games);
        }

        let entries = std::fs::read_dir(manifests_dir)?;
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension().map_or(false, |ext| ext == "item") {
                if let Ok(content) = std::fs::read_to_string(&path) {
                    if let Ok(item) = serde_json::from_str::<EpicManifestItem>(&content) {
                        if let (Some(title), Some(app_name), Some(install_loc)) =
                            (item.display_name, item.app_name, item.install_location)
                        {
                            let install_path = PathBuf::from(&install_loc);
                            if !install_path.exists() {
                                continue;
                            }

                            let mut exec_path = if let Some(launch_exe) = item.launch_executable {
                                install_path.join(launch_exe)
                            } else {
                                install_path.clone()
                            };

                            if !exec_path.exists() {
                                for e in walkdir::WalkDir::new(&install_path).max_depth(3).into_iter().flatten() {
                                    let p = e.path();
                                    if p.extension().map_or(false, |ext| ext == "exe" || ext == "app") {
                                        exec_path = p.to_path_buf();
                                        break;
                                    }
                                }
                            }

                            if exec_path.exists() {
                                let is_native = exec_path.extension().map_or(false, |ext| ext == "app");
                                let analysis = if !is_native {
                                    BinaryAnalyzer::analyze_file(&exec_path).ok()
                                } else {
                                    None
                                };

                                games.push(DiscoveredGame {
                                    id: format!("epic_{}", app_name.to_lowercase()),
                                    title,
                                    storefront: Storefront::EpicGames,
                                    storefront_app_id: Some(app_name.clone()),
                                    install_path,
                                    executable_path: exec_path,
                                    is_native,
                                    is_universal_app: false,
                                    acquisition_path: if is_native { "native_storefront".to_string() } else { "storefront_integration".to_string() },
                                    detected_status: if is_native {
                                        CompatibilityStatus::Native
                                    } else {
                                        CompatibilityStatus::Compatible
                                    },
                                    analysis,
                                });
                            }
                        }
                    }
                }
            }
        }

        Ok(games)
    }

    pub fn scan_heroic(config_file: &Path) -> Result<Vec<DiscoveredGame>, ScannerError> {
        let mut games = Vec::new();
        if !config_file.exists() {
            return Ok(games);
        }

        if let Ok(content) = std::fs::read_to_string(config_file) {
            if let Ok(root) = serde_json::from_str::<HeroicInstalledRoot>(&content) {
                for g in root.installed {
                    if g.is_installed.unwrap_or(true) {
                        if let (Some(app_name), Some(title), Some(inst)) = (g.app_name, g.title, g.install_path) {
                            let install_path = PathBuf::from(inst);
                            let exec_path = if let Some(exe) = g.executable {
                                PathBuf::from(exe)
                            } else {
                                install_path.clone()
                            };

                            if install_path.exists() {
                                let is_native = exec_path.extension().map_or(false, |ext| ext == "app");
                                let analysis = if !is_native && exec_path.is_file() {
                                    BinaryAnalyzer::analyze_file(&exec_path).ok()
                                } else {
                                    None
                                };

                                games.push(DiscoveredGame {
                                    id: format!("heroic_{}", app_name.to_lowercase()),
                                    title,
                                    storefront: Storefront::Heroic,
                                    storefront_app_id: Some(app_name),
                                    install_path,
                                    executable_path: exec_path,
                                    is_native,
                                    is_universal_app: false,
                                    acquisition_path: if is_native { "native_storefront".to_string() } else { "storefront_integration".to_string() },
                                    detected_status: if is_native {
                                        CompatibilityStatus::Native
                                    } else {
                                        CompatibilityStatus::Compatible
                                    },
                                    analysis,
                                });
                            }
                        }
                    }
                }
            }
        }

        Ok(games)
    }
}

// -----------------------------------------------------------------------------
// GOG GALAXY SCANNER
// -----------------------------------------------------------------------------
pub struct GogScanner;

#[derive(Deserialize)]
struct GogGameInfo {
    #[serde(rename = "gameId")]
    game_id: Option<String>,
    name: Option<String>,
    #[serde(rename = "rootGameName")]
    root_game_name: Option<String>,
    #[serde(rename = "playTasks")]
    play_tasks: Option<Vec<GogPlayTask>>,
}

#[derive(Deserialize)]
struct GogPlayTask {
    path: Option<String>,
    #[serde(rename = "isPrimary")]
    is_primary: Option<bool>,
}

impl GogScanner {
    pub fn default_gog_games_path() -> PathBuf {
        PathBuf::from("/Users/Shared/GOG.com/Galaxy/games")
    }

    pub fn scan_gog(gog_root: &Path) -> Result<Vec<DiscoveredGame>, ScannerError> {
        let mut games = Vec::new();
        if !gog_root.exists() {
            return Ok(games);
        }

        for entry in walkdir::WalkDir::new(gog_root).max_depth(3).into_iter().flatten() {
            let path = entry.path();
            if path.is_file() {
                let file_name = path.file_name().unwrap_or_default().to_string_lossy();
                if file_name.starts_with("goggame-") && file_name.ends_with(".info") {
                    if let Ok(content) = std::fs::read_to_string(path) {
                        if let Ok(info) = serde_json::from_str::<GogGameInfo>(&content) {
                            let game_id = info.game_id.unwrap_or_else(|| "unknown".to_string());
                            let title = info
                                .name
                                .or(info.root_game_name)
                                .unwrap_or_else(|| format!("GOG Game {}", game_id));

                            let game_dir = path.parent().unwrap_or(path).to_path_buf();
                            let mut exec_path = game_dir.clone();

                            if let Some(tasks) = info.play_tasks {
                                if let Some(primary) = tasks.iter().find(|t| t.is_primary.unwrap_or(false)) {
                                    if let Some(ref p) = primary.path {
                                        exec_path = game_dir.join(p);
                                    }
                                } else if let Some(first) = tasks.first() {
                                    if let Some(ref p) = first.path {
                                        exec_path = game_dir.join(p);
                                    }
                                }
                            }

                            if !exec_path.exists() || exec_path.is_dir() {
                                for e in walkdir::WalkDir::new(&game_dir).max_depth(2).into_iter().flatten() {
                                    let p = e.path();
                                    if p.extension().map_or(false, |ext| ext == "app" || ext == "exe") {
                                        exec_path = p.to_path_buf();
                                        break;
                                    }
                                }
                            }

                            let is_native = exec_path.extension().map_or(false, |ext| ext == "app");
                            let analysis = if !is_native && exec_path.is_file() {
                                BinaryAnalyzer::analyze_file(&exec_path).ok()
                            } else {
                                None
                            };

                            games.push(DiscoveredGame {
                                id: format!("gog_{}", game_id),
                                title,
                                storefront: Storefront::Gog,
                                storefront_app_id: Some(game_id),
                                install_path: game_dir,
                                executable_path: exec_path,
                                is_native,
                                is_universal_app: false,
                                acquisition_path: if is_native { "native_storefront".to_string() } else { "storefront_integration".to_string() },
                                detected_status: if is_native {
                                    CompatibilityStatus::Native
                                } else {
                                    CompatibilityStatus::Compatible
                                },
                                analysis,
                            });
                        }
                    }
                }
            }
        }

        Ok(games)
    }
}

// -----------------------------------------------------------------------------
// ITCH.IO SCANNER
// -----------------------------------------------------------------------------
pub struct ItchScanner;

#[derive(Deserialize)]
struct ItchReceipt {
    game: Option<ItchGameMeta>,
}

#[derive(Deserialize)]
struct ItchGameMeta {
    id: Option<u64>,
    title: Option<String>,
}

impl ItchScanner {
    pub fn default_itch_path() -> PathBuf {
        dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Library/Application Support/itch/apps")
    }

    pub fn scan_itch(itch_root: &Path) -> Result<Vec<DiscoveredGame>, ScannerError> {
        let mut games = Vec::new();
        if !itch_root.exists() {
            return Ok(games);
        }

        for entry in std::fs::read_dir(itch_root)?.flatten() {
            let app_dir = entry.path();
            if app_dir.is_dir() {
                let stem = app_dir.file_name().unwrap_or_default().to_string_lossy().to_string();
                let mut title = stem.clone();
                let mut game_id = format!("itch_{}", stem.to_lowercase().replace(' ', "_"));

                // Check for receipt.json
                let receipt_path = app_dir.join(".itch/receipt.json");
                if receipt_path.exists() {
                    if let Ok(content) = std::fs::read_to_string(receipt_path) {
                        if let Ok(r) = serde_json::from_str::<ItchReceipt>(&content) {
                            if let Some(g) = r.game {
                                if let Some(t) = g.title {
                                    title = t;
                                }
                                if let Some(gid) = g.id {
                                    game_id = format!("itch_{}", gid);
                                }
                            }
                        }
                    }
                }

                // Find candidate executable
                for e in walkdir::WalkDir::new(&app_dir).max_depth(3).into_iter().flatten() {
                    let p = e.path();
                    let ext = p.extension().map(|s| s.to_string_lossy().to_lowercase());
                    if ext.as_deref() == Some("app") || ext.as_deref() == Some("exe") {
                        let is_native = ext.as_deref() == Some("app");
                        let analysis = if !is_native && p.is_file() {
                            BinaryAnalyzer::analyze_file(p).ok()
                        } else {
                            None
                        };

                        games.push(DiscoveredGame {
                            id: game_id.clone(),
                            title: title.clone(),
                            storefront: Storefront::ItchIo,
                            storefront_app_id: None,
                            install_path: app_dir.clone(),
                            executable_path: p.to_path_buf(),
                            is_native,
                            is_universal_app: false,
                            acquisition_path: if is_native { "native_storefront".to_string() } else { "storefront_integration".to_string() },
                            detected_status: if is_native {
                                CompatibilityStatus::Native
                            } else {
                                CompatibilityStatus::Compatible
                            },
                            analysis,
                        });
                        break;
                    }
                }
            }
        }

        Ok(games)
    }
}

// -----------------------------------------------------------------------------
// UBISOFT CONNECT SCANNER
// -----------------------------------------------------------------------------
pub struct UbisoftScanner;

impl UbisoftScanner {
    pub fn default_ubisoft_path() -> PathBuf {
        dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Library/Application Support/Ubisoft/Ubisoft Game Launcher/games")
    }

    pub fn scan_ubisoft(ubisoft_root: &Path) -> Result<Vec<DiscoveredGame>, ScannerError> {
        let mut games = Vec::new();
        if !ubisoft_root.exists() {
            return Ok(games);
        }

        for entry in std::fs::read_dir(ubisoft_root)?.flatten() {
            let game_dir = entry.path();
            if game_dir.is_dir() {
                let title = game_dir.file_name().unwrap_or_default().to_string_lossy().to_string();
                let slug = title.to_lowercase().replace(' ', "_");

                for e in walkdir::WalkDir::new(&game_dir).max_depth(3).into_iter().flatten() {
                    let p = e.path();
                    if p.is_file() && p.extension().map_or(false, |ext| ext == "exe") {
                        let stem = p.file_stem().unwrap_or_default().to_string_lossy().to_lowercase();
                        if !stem.contains("unins") && !stem.contains("uplay") && !stem.contains("crash") {
                            let analysis = BinaryAnalyzer::analyze_file(p).ok();
                            games.push(DiscoveredGame {
                                id: format!("ubisoft_{}", slug),
                                title: title.clone(),
                                storefront: Storefront::UbisoftConnect,
                                storefront_app_id: None,
                                install_path: game_dir.clone(),
                                executable_path: p.to_path_buf(),
                                is_native: false,
                                is_universal_app: false,
                                acquisition_path: "storefront_integration".to_string(),
                                detected_status: CompatibilityStatus::Compatible,
                                analysis,
                            });
                            break;
                        }
                    }
                }
            }
        }

        Ok(games)
    }
}

// -----------------------------------------------------------------------------
// EA APP SCANNER
// -----------------------------------------------------------------------------
pub struct EaAppScanner;

impl EaAppScanner {
    pub fn default_ea_path() -> PathBuf {
        dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Library/Application Support/Electronic Arts/EA Desktop/games")
    }

    pub fn scan_ea(ea_root: &Path) -> Result<Vec<DiscoveredGame>, ScannerError> {
        let mut games = Vec::new();
        if !ea_root.exists() {
            return Ok(games);
        }

        for entry in std::fs::read_dir(ea_root)?.flatten() {
            let game_dir = entry.path();
            if game_dir.is_dir() {
                let title = game_dir.file_name().unwrap_or_default().to_string_lossy().to_string();
                let slug = title.to_lowercase().replace(' ', "_");

                for e in walkdir::WalkDir::new(&game_dir).max_depth(3).into_iter().flatten() {
                    let p = e.path();
                    if p.is_file() && p.extension().map_or(false, |ext| ext == "exe") {
                        let stem = p.file_stem().unwrap_or_default().to_string_lossy().to_lowercase();
                        if !stem.contains("cleanup") && !stem.contains("eaconnect") && !stem.contains("installer") {
                            let analysis = BinaryAnalyzer::analyze_file(p).ok();
                            games.push(DiscoveredGame {
                                id: format!("ea_{}", slug),
                                title: title.clone(),
                                storefront: Storefront::EaApp,
                                storefront_app_id: None,
                                install_path: game_dir.clone(),
                                executable_path: p.to_path_buf(),
                                is_native: false,
                                is_universal_app: false,
                                acquisition_path: "storefront_integration".to_string(),
                                detected_status: CompatibilityStatus::Compatible,
                                analysis,
                            });
                            break;
                        }
                    }
                }
            }
        }

        Ok(games)
    }
}

// -----------------------------------------------------------------------------
// BATTLE.NET SCANNER
// -----------------------------------------------------------------------------
pub struct BattleNetScanner;

impl BattleNetScanner {
    pub fn default_battlenet_path() -> PathBuf {
        PathBuf::from("/Applications/Battle.net")
    }

    pub fn scan_battlenet(bnet_root: &Path) -> Result<Vec<DiscoveredGame>, ScannerError> {
        let mut games = Vec::new();
        if !bnet_root.exists() {
            return Ok(games);
        }

        let known_titles = [
            ("World of Warcraft", "wow"),
            ("Diablo IV", "diablo_iv"),
            ("Diablo II Resurrected", "diablo_ii"),
            ("Overwatch", "overwatch"),
            ("StarCraft II", "sc2"),
            ("Hearthstone", "hearthstone"),
        ];

        for (title, slug) in &known_titles {
            let candidate_dir = bnet_root.join(title);
            if candidate_dir.exists() {
                for e in walkdir::WalkDir::new(&candidate_dir).max_depth(3).into_iter().flatten() {
                    let p = e.path();
                    let ext = p.extension().map(|s| s.to_string_lossy().to_lowercase());
                    if ext.as_deref() == Some("app") || ext.as_deref() == Some("exe") {
                        let is_native = ext.as_deref() == Some("app");
                        let analysis = if !is_native && p.is_file() {
                            BinaryAnalyzer::analyze_file(p).ok()
                        } else {
                            None
                        };

                        games.push(DiscoveredGame {
                            id: format!("bnet_{}", slug),
                            title: title.to_string(),
                            storefront: Storefront::BattleNet,
                            storefront_app_id: Some(slug.to_string()),
                            install_path: candidate_dir.clone(),
                            executable_path: p.to_path_buf(),
                            is_native,
                            is_universal_app: false,
                            acquisition_path: if is_native { "native_storefront".to_string() } else { "storefront_integration".to_string() },
                            detected_status: if is_native {
                                CompatibilityStatus::Native
                            } else {
                                CompatibilityStatus::Compatible
                            },
                            analysis,
                        });
                        break;
                    }
                }
            }
        }

        Ok(games)
    }
}

// -----------------------------------------------------------------------------
// UNIVERSAL WINDOWS APPLICATION SCANNER & IMPORTER
// -----------------------------------------------------------------------------
pub struct UniversalAppScanner;

impl UniversalAppScanner {
    pub fn import_application<P: AsRef<Path>>(
        path: P,
        title_override: Option<&str>,
    ) -> Result<DiscoveredGame, ScannerError> {
        let path = path.as_ref();
        if !path.exists() {
            return Err(ScannerError::InvalidPath(format!(
                "Application file does not exist: {}",
                path.display()
            )));
        }

        let stem = path.file_stem().unwrap_or_default().to_string_lossy().to_string();
        let title = title_override.map(|s| s.to_string()).unwrap_or(stem);
        let slug = title
            .to_lowercase()
            .replace(|c: char| !c.is_alphanumeric() && c != '_', "_");

        let is_app = path.is_dir() && path.extension().map_or(false, |ext| ext == "app");
        let analysis = if !is_app && path.is_file() {
            BinaryAnalyzer::analyze_file(path).ok()
        } else {
            None
        };

        Ok(DiscoveredGame {
            id: format!("app_{}", slug),
            title,
            storefront: Storefront::UniversalApp,
            storefront_app_id: None,
            install_path: path.parent().unwrap_or(path).to_path_buf(),
            executable_path: path.to_path_buf(),
            is_native: is_app,
            is_universal_app: true,
            acquisition_path: if is_app { "native_storefront".to_string() } else { "existing_files".to_string() },
            detected_status: if is_native_ext(path) {
                CompatibilityStatus::Native
            } else {
                CompatibilityStatus::Compatible
            },
            analysis,
        })
    }
}

fn is_native_ext(path: &Path) -> bool {
    path.extension().map_or(false, |ext| ext == "app")
}

// -----------------------------------------------------------------------------
// CUSTOM GAME IMPORTER
// -----------------------------------------------------------------------------
pub struct CustomGameImporter;

impl CustomGameImporter {
    pub fn import_file<P: AsRef<Path>>(
        path: P,
        title_override: Option<&str>,
    ) -> Result<DiscoveredGame, ScannerError> {
        let path = path.as_ref();
        if !path.exists() {
            return Err(ScannerError::InvalidPath(format!(
                "File does not exist at: {}",
                path.display()
            )));
        }

        let is_app = path.is_dir() && path.extension().map_or(false, |ext| ext == "app");
        let is_exe = path.is_file() && path.extension().map_or(false, |ext| ext == "exe");

        if !is_app && !is_exe {
            return Err(ScannerError::InvalidPath(
                "Provided path must be a Windows .exe binary or macOS .app bundle".to_string(),
            ));
        }

        let stem = path.file_stem().unwrap_or_default().to_string_lossy().to_string();
        let title = title_override.map(|s| s.to_string()).unwrap_or(stem);
        let slug = title
            .to_lowercase()
            .replace(|c: char| !c.is_alphanumeric() && c != '_', "_");
        let game_id = format!("local_{}", slug);

        let install_path = path.parent().unwrap_or(path).to_path_buf();
        let analysis = if is_exe {
            BinaryAnalyzer::analyze_file(path).ok()
        } else {
            None
        };

        let detected_status = if is_app {
            CompatibilityStatus::Native
        } else {
            CompatibilityStatus::Compatible
        };

        Ok(DiscoveredGame {
            id: game_id,
            title,
            storefront: Storefront::Local,
            storefront_app_id: None,
            install_path,
            executable_path: path.to_path_buf(),
            is_native: is_app,
            is_universal_app: false,
            acquisition_path: if is_app { "native_storefront".to_string() } else { "existing_files".to_string() },
            detected_status,
            analysis,
        })
    }
}

// -----------------------------------------------------------------------------
// UNIFIED MULTI-STOREFRONT SCANNER
// -----------------------------------------------------------------------------
pub struct MultiStorefrontScanner;

impl MultiStorefrontScanner {
    pub fn scan_all() -> Result<Vec<DiscoveredGame>, ScannerError> {
        let mut all_games = Vec::new();

        // 1. Steam
        let steam_path = SteamScanner::default_steam_path();
        if steam_path.exists() {
            if let Ok(mut steam_games) = SteamScanner::scan_steam(&steam_path) {
                all_games.append(&mut steam_games);
            }
        }

        // 2. Epic Games
        let epic_path = EpicScanner::default_epic_manifests_path();
        if epic_path.exists() {
            if let Ok(mut epic_games) = EpicScanner::scan_epic(&epic_path) {
                all_games.append(&mut epic_games);
            }
        }

        // 3. Heroic
        let heroic_path = EpicScanner::default_heroic_config_path();
        if heroic_path.exists() {
            if let Ok(mut heroic_games) = EpicScanner::scan_heroic(&heroic_path) {
                all_games.append(&mut heroic_games);
            }
        }

        // 4. GOG Galaxy
        let gog_path = GogScanner::default_gog_games_path();
        if gog_path.exists() {
            if let Ok(mut gog_games) = GogScanner::scan_gog(&gog_path) {
                all_games.append(&mut gog_games);
            }
        }

        // 5. itch.io
        let itch_path = ItchScanner::default_itch_path();
        if itch_path.exists() {
            if let Ok(mut itch_games) = ItchScanner::scan_itch(&itch_path) {
                all_games.append(&mut itch_games);
            }
        }

        // 6. Ubisoft Connect
        let ubisoft_path = UbisoftScanner::default_ubisoft_path();
        if ubisoft_path.exists() {
            if let Ok(mut ubi_games) = UbisoftScanner::scan_ubisoft(&ubisoft_path) {
                all_games.append(&mut ubi_games);
            }
        }

        // 7. EA App
        let ea_path = EaAppScanner::default_ea_path();
        if ea_path.exists() {
            if let Ok(mut ea_games) = EaAppScanner::scan_ea(&ea_path) {
                all_games.append(&mut ea_games);
            }
        }

        // 8. Battle.net
        let bnet_path = BattleNetScanner::default_battlenet_path();
        if bnet_path.exists() {
            if let Ok(mut bnet_games) = BattleNetScanner::scan_battlenet(&bnet_path) {
                all_games.append(&mut bnet_games);
            }
        }

        Ok(all_games)
    }
}

pub struct LocalGameScanner;

impl LocalGameScanner {
    pub fn scan_directory<P: AsRef<Path>>(dir: P) -> Vec<DiscoveredGame> {
        let mut results = Vec::new();
        let dir = dir.as_ref();
        if !dir.exists() {
            return results;
        }

        for entry in walkdir::WalkDir::new(dir).max_depth(3).into_iter().flatten() {
            let path = entry.path();
            if path.is_file() {
                if let Some(ext) = path.extension() {
                    if ext.to_string_lossy().to_lowercase() == "exe" {
                        let stem = path.file_stem().unwrap_or_default().to_string_lossy().to_string();
                        let analysis = BinaryAnalyzer::analyze_file(path).ok();
                        results.push(DiscoveredGame {
                            id: format!("local_{}", stem.to_lowercase().replace(' ', "_")),
                            title: stem,
                            storefront: Storefront::Local,
                            storefront_app_id: None,
                            install_path: path.parent().unwrap_or(path).to_path_buf(),
                            executable_path: path.to_path_buf(),
                            is_native: false,
                            is_universal_app: false,
                            acquisition_path: "existing_files".to_string(),
                            detected_status: CompatibilityStatus::Compatible,
                            analysis,
                        });
                    }
                }
            }
        }

        results
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_custom_game_importer_app() {
        let temp_dir = tempfile::tempdir().unwrap();
        let mock_app = temp_dir.path().join("SuperGame.app");
        std::fs::create_dir_all(&mock_app).unwrap();

        let game = CustomGameImporter::import_file(&mock_app, Some("Super Game HD")).unwrap();
        assert_eq!(game.id, "local_super_game_hd");
        assert_eq!(game.title, "Super Game HD");
        assert!(game.is_native);
        assert_eq!(game.detected_status, CompatibilityStatus::Native);
        assert_eq!(game.storefront, Storefront::Local);
    }

    #[test]
    fn test_itch_scanner() {
        let temp_dir = tempfile::tempdir().unwrap();
        let game_dir = temp_dir.path().join("Celeste");
        std::fs::create_dir_all(&game_dir).unwrap();
        let exe_file = game_dir.join("Celeste.exe");
        std::fs::write(&exe_file, b"MZ dummy exe").unwrap();

        let scanned = ItchScanner::scan_itch(temp_dir.path()).unwrap();
        assert_eq!(scanned.len(), 1);
        assert_eq!(scanned[0].storefront, Storefront::ItchIo);
        assert_eq!(scanned[0].executable_path, exe_file);
    }

    #[test]
    fn test_universal_app_importer() {
        let temp_dir = tempfile::tempdir().unwrap();
        let app_file = temp_dir.path().join("NotepadPlusPlus.exe");
        std::fs::write(&app_file, b"MZ dummy exe").unwrap();

        let app = UniversalAppScanner::import_application(&app_file, Some("Notepad++")).unwrap();
        assert_eq!(app.id, "app_notepad__");
        assert_eq!(app.title, "Notepad++");
        assert_eq!(app.storefront, Storefront::UniversalApp);
        assert!(app.is_universal_app);
    }
}
