use forge_profiles::CompatibilityStatus;
use forge_scanner::{DiscoveredGame, Storefront};
use rusqlite::{params, Connection, Result};
use std::path::{Path, PathBuf};

pub struct LocalDatabase {
    conn: Connection,
}

impl LocalDatabase {
    pub fn open_or_create<P: AsRef<Path>>(path: P) -> Result<Self> {
        if let Some(parent) = path.as_ref().parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        let conn = Connection::open(path)?;
        let db = Self { conn };
        db.init_tables()?;
        Ok(db)
    }

    pub fn open_in_memory() -> Result<Self> {
        let conn = Connection::open_in_memory()?;
        let db = Self { conn };
        db.init_tables()?;
        Ok(db)
    }

    fn init_tables(&self) -> Result<()> {
        self.conn.execute(
            "CREATE TABLE IF NOT EXISTS games (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                storefront TEXT NOT NULL,
                storefront_app_id TEXT,
                install_path TEXT NOT NULL,
                executable_path TEXT NOT NULL,
                is_native INTEGER NOT NULL,
                is_universal_app INTEGER NOT NULL DEFAULT 0,
                acquisition_path TEXT NOT NULL DEFAULT 'existing_files',
                status TEXT NOT NULL,
                last_scanned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                last_played_at DATETIME
            )",
            [],
        )?;

        self.conn.execute(
            "CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )",
            [],
        )?;

        let _ = self.conn.execute(
            "ALTER TABLE games ADD COLUMN is_universal_app INTEGER NOT NULL DEFAULT 0",
            [],
        );
        let _ = self.conn.execute(
            "ALTER TABLE games ADD COLUMN acquisition_path TEXT NOT NULL DEFAULT 'existing_files'",
            [],
        );

        Ok(())
    }

    pub fn upsert_game(&self, game: &DiscoveredGame) -> Result<()> {
        let storefront_str = format!("{:?}", game.storefront);
        let status_str = format!("{:?}", game.detected_status);

        self.conn.execute(
            "INSERT INTO games (
                id, title, storefront, storefront_app_id, install_path,
                executable_path, is_native, is_universal_app, acquisition_path, status, last_scanned_at
            ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, CURRENT_TIMESTAMP)
            ON CONFLICT(id) DO UPDATE SET
                title=excluded.title,
                storefront=excluded.storefront,
                install_path=excluded.install_path,
                executable_path=excluded.executable_path,
                is_native=excluded.is_native,
                is_universal_app=excluded.is_universal_app,
                acquisition_path=excluded.acquisition_path,
                status=excluded.status,
                last_scanned_at=CURRENT_TIMESTAMP",
            params![
                game.id,
                game.title,
                storefront_str,
                game.storefront_app_id,
                game.install_path.display().to_string(),
                game.executable_path.display().to_string(),
                if game.is_native { 1 } else { 0 },
                if game.is_universal_app { 1 } else { 0 },
                game.acquisition_path,
                status_str,
            ],
        )?;
        Ok(())
    }

    pub fn get_all_games(&self) -> Result<Vec<DiscoveredGame>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, title, storefront, storefront_app_id, install_path, executable_path, is_native, is_universal_app, acquisition_path, status FROM games ORDER BY title ASC"
        )?;

        let game_iter = stmt.query_map([], |row| {
            let id: String = row.get(0)?;
            let title: String = row.get(1)?;
            let storefront_str: String = row.get(2)?;
            let storefront_app_id: Option<String> = row.get(3)?;
            let install_path: String = row.get(4)?;
            let executable_path: String = row.get(5)?;
            let is_native: bool = row.get::<_, i64>(6)? != 0;
            let is_universal_app: bool = row.get::<_, i64>(7)? != 0;
            let acquisition_path: String = row.get(8)?;
            let status_str: String = row.get(9)?;

            let storefront = match storefront_str.as_str() {
                "Steam" => Storefront::Steam,
                "EpicGames" => Storefront::EpicGames,
                "Heroic" => Storefront::Heroic,
                "Gog" => Storefront::Gog,
                "ItchIo" => Storefront::ItchIo,
                "UbisoftConnect" => Storefront::UbisoftConnect,
                "EaApp" => Storefront::EaApp,
                "BattleNet" => Storefront::BattleNet,
                "UniversalApp" => Storefront::UniversalApp,
                _ => {
                    if id.starts_with("steam_") {
                        Storefront::Steam
                    } else if id.starts_with("epic_") {
                        Storefront::EpicGames
                    } else if id.starts_with("gog_") {
                        Storefront::Gog
                    } else if id.starts_with("itch_") {
                        Storefront::ItchIo
                    } else if id.starts_with("ubisoft_") {
                        Storefront::UbisoftConnect
                    } else if id.starts_with("ea_") {
                        Storefront::EaApp
                    } else if id.starts_with("bnet_") {
                        Storefront::BattleNet
                    } else if id.starts_with("app_") {
                        Storefront::UniversalApp
                    } else {
                        Storefront::Local
                    }
                }
            };

            let detected_status = match status_str.as_str() {
                "Native" => CompatibilityStatus::Native,
                "Experimental" => CompatibilityStatus::Experimental,
                "CommunityFix" => CompatibilityStatus::CommunityFix,
                "Unsupported" => CompatibilityStatus::Unsupported,
                _ => CompatibilityStatus::Compatible,
            };

            Ok(DiscoveredGame {
                id,
                title,
                storefront,
                storefront_app_id,
                install_path: PathBuf::from(install_path),
                executable_path: PathBuf::from(executable_path),
                is_native,
                is_universal_app,
                acquisition_path,
                detected_status,
                analysis: None,
            })
        })?;

        let mut games = Vec::new();
        for g in game_iter {
            games.push(g?);
        }
        Ok(games)
    }
}
