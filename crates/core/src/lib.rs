/// ForgeEngine Core implementation: Handles prefix management, game discovery, and execution lifecycle.
pub mod acquisition;
pub mod audit;
pub mod benchmark;
pub mod catalog;
pub mod community;
pub mod database;
pub mod developer;
pub mod diagnostics;
pub mod submissions;
pub mod troubleshooter;

pub use acquisition::{AcquisitionPath, WindowsLauncherManager};
pub use audit::{LibraryAuditEngine, LibraryStateAudit};
pub use benchmark::{BenchmarkEngine, BenchmarkMetric, BenchmarkSession, RegressionReport};
pub use catalog::{CatalogCompatibilityTier, CatalogEntry, UniversalCatalog};
pub use developer::{DeveloperEcosystemManager, NativeDeveloperSpotlight, StudioDemandCampaign};
pub use community::{CommunitySyncClient, CommunitySyncError, CommunitySyncResult};
use database::LocalDatabase;
use diagnostics::HostSystemDiagnostics;
pub use forge_prefix::{
    DependencyStatus, LaunchEnvironment, LaunchOverrideOptions, PrefixManager, PrefixProvisioner,
    ProvisioningPlan,
};
pub use forge_profiles::{CompatibilityProfile, ProfileStore};
pub use forge_scanner::{
    BattleNetScanner, CustomGameImporter, DiscoveredGame, EaAppScanner, EpicScanner, GogScanner,
    ItchScanner, LocalGameScanner, MultiStorefrontScanner, SteamScanner, Storefront,
    UbisoftScanner, UniversalAppScanner,
};
use std::path::{Path, PathBuf};
pub use submissions::{CompatibilityReport, CompatibilityTier, ProfileSubmission};
use thiserror::Error;
pub use troubleshooter::{CrashCategory, DiagnosticFinding, DiagnosticReport, DiagnosticSeverity, Troubleshooter};

#[derive(Error, Debug)]
pub enum EngineError {
    #[error("Database error: {0}")]
    Database(#[from] rusqlite::Error),
    #[error("Scanner error: {0}")]
    Scanner(#[from] forge_scanner::ScannerError),
    #[error("Prefix error: {0}")]
    Prefix(#[from] forge_prefix::PrefixError),
    #[error("Profile error: {0}")]
    Profile(#[from] forge_profiles::ProfileError),
    #[error("Community sync error: {0}")]
    Community(#[from] community::CommunitySyncError),
    #[error("Game not found: {0}")]
    GameNotFound(String),
}

pub struct ForgeEngine {
    pub diagnostics: HostSystemDiagnostics,
    pub profile_store: ProfileStore,
    pub prefix_manager: PrefixManager,
    pub database: LocalDatabase,
}

impl ForgeEngine {
    pub fn init() -> Result<Self, EngineError> {
        let diagnostics = HostSystemDiagnostics::probe();
        let mut profile_store = ProfileStore::new();

        // Load built-in / curated profiles
        let curated_profiles_dir = dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Library/Application Support/Forge/profiles");
        let _ = profile_store.load_from_directory(curated_profiles_dir);

        // Also check if workspace profiles directory exists
        let local_profiles = PathBuf::from("profiles");
        if local_profiles.exists() {
            let _ = profile_store.load_from_directory(local_profiles);
        }

        let prefix_manager = PrefixManager::new();

        let db_path = dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Library/Application Support/Forge/library.db");
        let database = LocalDatabase::open_or_create(db_path)?;

        Ok(Self {
            diagnostics,
            profile_store,
            prefix_manager,
            database,
        })
    }

    pub fn init_with_storage<P: AsRef<Path>>(storage_root: P) -> Result<Self, EngineError> {
        let diagnostics = HostSystemDiagnostics::probe();
        let mut profile_store = ProfileStore::new();

        let profiles_dir = storage_root.as_ref().join("profiles");
        let _ = profile_store.load_from_directory(&profiles_dir);

        let prefix_manager = PrefixManager::with_prefix_dir(storage_root.as_ref().join("prefixes"));
        let database = LocalDatabase::open_or_create(storage_root.as_ref().join("library.db"))?;

        Ok(Self {
            diagnostics,
            profile_store,
            prefix_manager,
            database,
        })
    }

    pub fn scan_all_storefronts(&self) -> Result<Vec<DiscoveredGame>, EngineError> {
        let games = MultiStorefrontScanner::scan_all()?;
        for game in &games {
            let mut adjusted = game.clone();
            if let Some(profile) = self.profile_store.get(&game.id) {
                if !game.is_native {
                    adjusted.detected_status = profile.status;
                }
            }
            self.database.upsert_game(&adjusted)?;
        }
        Ok(games)
    }

    pub fn scan_steam(&self) -> Result<Vec<DiscoveredGame>, EngineError> {
        let steam_dir = SteamScanner::default_steam_path();
        let games = SteamScanner::scan_steam(&steam_dir)?;
        for game in &games {
            let mut adjusted = game.clone();
            if let Some(profile) = self.profile_store.get(&game.id) {
                if !game.is_native {
                    adjusted.detected_status = profile.status;
                }
            }
            self.database.upsert_game(&adjusted)?;
        }
        Ok(games)
    }

    pub fn scan_epic(&self) -> Result<Vec<DiscoveredGame>, EngineError> {
        let epic_dir = EpicScanner::default_epic_manifests_path();
        let mut games = EpicScanner::scan_epic(&epic_dir)?;
        let heroic_cfg = EpicScanner::default_heroic_config_path();
        if let Ok(mut heroic_games) = EpicScanner::scan_heroic(&heroic_cfg) {
            games.append(&mut heroic_games);
        }

        for game in &games {
            let mut adjusted = game.clone();
            if let Some(profile) = self.profile_store.get(&game.id) {
                if !game.is_native {
                    adjusted.detected_status = profile.status;
                }
            }
            self.database.upsert_game(&adjusted)?;
        }
        Ok(games)
    }

    pub fn scan_gog(&self) -> Result<Vec<DiscoveredGame>, EngineError> {
        let gog_dir = GogScanner::default_gog_games_path();
        let games = GogScanner::scan_gog(&gog_dir)?;
        for game in &games {
            let mut adjusted = game.clone();
            if let Some(profile) = self.profile_store.get(&game.id) {
                if !game.is_native {
                    adjusted.detected_status = profile.status;
                }
            }
            self.database.upsert_game(&adjusted)?;
        }
        Ok(games)
    }

    pub fn scan_itch(&self) -> Result<Vec<DiscoveredGame>, EngineError> {
        let itch_dir = ItchScanner::default_itch_path();
        let games = ItchScanner::scan_itch(&itch_dir)?;
        for game in &games {
            self.database.upsert_game(game)?;
        }
        Ok(games)
    }

    pub fn scan_ubisoft(&self) -> Result<Vec<DiscoveredGame>, EngineError> {
        let ubi_dir = UbisoftScanner::default_ubisoft_path();
        let games = UbisoftScanner::scan_ubisoft(&ubi_dir)?;
        for game in &games {
            self.database.upsert_game(game)?;
        }
        Ok(games)
    }

    pub fn scan_ea(&self) -> Result<Vec<DiscoveredGame>, EngineError> {
        let ea_dir = EaAppScanner::default_ea_path();
        let games = EaAppScanner::scan_ea(&ea_dir)?;
        for game in &games {
            self.database.upsert_game(game)?;
        }
        Ok(games)
    }

    pub fn scan_battlenet(&self) -> Result<Vec<DiscoveredGame>, EngineError> {
        let bnet_dir = BattleNetScanner::default_battlenet_path();
        let games = BattleNetScanner::scan_battlenet(&bnet_dir)?;
        for game in &games {
            self.database.upsert_game(game)?;
        }
        Ok(games)
    }

    pub fn import_custom_game<P: AsRef<Path>>(
        &self,
        path: P,
        title_override: Option<&str>,
    ) -> Result<DiscoveredGame, EngineError> {
        let game = CustomGameImporter::import_file(path, title_override)?;
        let mut adjusted = game.clone();
        if let Some(profile) = self.profile_store.get(&game.id) {
            if !game.is_native {
                adjusted.detected_status = profile.status;
            }
        }
        self.database.upsert_game(&adjusted)?;
        Ok(adjusted)
    }

    pub fn import_universal_application<P: AsRef<Path>>(
        &self,
        path: P,
        title_override: Option<&str>,
    ) -> Result<DiscoveredGame, EngineError> {
        let app = UniversalAppScanner::import_application(path, title_override)?;
        self.database.upsert_game(&app)?;
        Ok(app)
    }

    pub fn scan_custom_directory<P: AsRef<Path>>(&self, dir: P) -> Result<Vec<DiscoveredGame>, EngineError> {
        let games = LocalGameScanner::scan_directory(dir);
        for game in &games {
            self.database.upsert_game(game)?;
        }
        Ok(games)
    }

    pub fn get_all_games(&self) -> Result<Vec<DiscoveredGame>, EngineError> {
        let mut games = self.database.get_all_games()?;
        for game in &mut games {
            if let Some(profile) = self.profile_store.get(&game.id) {
                if !game.is_native {
                    game.detected_status = profile.status;
                }
            }
        }
        Ok(games)
    }

    pub fn prepare_launch(&self, game_id: &str) -> Result<LaunchEnvironment, EngineError> {
        self.prepare_launch_with_options(game_id, None)
    }

    pub fn prepare_launch_with_options(
        &self,
        game_id: &str,
        options: Option<&LaunchOverrideOptions>,
    ) -> Result<LaunchEnvironment, EngineError> {
        let games = self.get_all_games()?;
        let game = games
            .iter()
            .find(|g| g.id == game_id)
            .ok_or_else(|| EngineError::GameNotFound(game_id.to_string()))?;

        let profile = self.profile_store.get(game_id);
        let launch_env = self.prefix_manager.build_launch_environment_with_options(game, profile, options)?;
        Ok(launch_env)
    }

    pub fn troubleshoot_log(&self, log_text: &str) -> DiagnosticReport {
        Troubleshooter::analyze_logs(log_text)
    }

    pub fn sync_community_profiles(&mut self) -> Result<CommunitySyncResult, EngineError> {
        let client = CommunitySyncClient::new();
        let result = client.sync_profiles(&mut self.profile_store)?;
        Ok(result)
    }

    pub fn check_game_provisioning(&self, game_id: &str) -> Result<ProvisioningPlan, EngineError> {
        let prefix = self.prefix_manager.get_prefix_dir(game_id);
        let deps = if let Some(profile) = self.profile_store.get(game_id) {
            profile.runtime.dependencies.clone()
        } else {
            vec!["vcrun2022".to_string()]
        };

        let plan = PrefixProvisioner::check_dependencies(prefix, game_id, &deps);
        Ok(plan)
    }
}
