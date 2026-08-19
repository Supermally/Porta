#[cfg(test)]
mod tests {
    use mac_gaming_core::{
        CrashCategory, LaunchOverrideOptions, MacGamingEngine, Troubleshooter,
    };
    use mac_gaming_profiles::CompatibilityStatus;
    use std::fs::{create_dir_all, File};
    use std::io::Write;
    use tempfile::tempdir;

    #[test]
    fn test_full_pipeline_with_mock_steam() {
        let temp_dir = tempdir().unwrap();
        let steam_dir = temp_dir.path().join("Steam");
        let steamapps_dir = steam_dir.join("steamapps");
        let common_dir = steamapps_dir.join("common");
        create_dir_all(&common_dir).unwrap();

        // 1. Create libraryfolders.vdf
        let mut vdf_file = File::create(steamapps_dir.join("libraryfolders.vdf")).unwrap();
        writeln!(
            vdf_file,
            r#"
"libraryfolders"
{{
    "0"
    {{
        "path" "{}"
    }}
}}
"#,
            steam_dir.display()
        )
        .unwrap();

        // 2. Create Elden Ring mock game
        let mut elden_acf = File::create(steamapps_dir.join("appmanifest_1245620.acf")).unwrap();
        writeln!(
            elden_acf,
            r#"
"AppState"
{{
    "appid" "1245620"
    "name" "ELDEN RING"
    "installdir" "ELDEN RING"
}}
"#
        )
        .unwrap();
        let elden_game_dir = common_dir.join("ELDEN RING");
        create_dir_all(&elden_game_dir).unwrap();
        File::create(elden_game_dir.join("eldenring.exe")).unwrap();

        // 3. Create Baldur's Gate 3 mock native game
        let mut bg3_acf = File::create(steamapps_dir.join("appmanifest_1086940.acf")).unwrap();
        writeln!(
            bg3_acf,
            r#"
"AppState"
{{
    "appid" "1086940"
    "name" "Baldur's Gate 3"
    "installdir" "Baldurs Gate 3"
}}
"#
        )
        .unwrap();
        let bg3_game_dir = common_dir.join("Baldurs Gate 3");
        create_dir_all(bg3_game_dir.join("Baldur's Gate 3.app")).unwrap();

        // Initialize Engine with storage in temp directory
        let engine = MacGamingEngine::init_with_storage(temp_dir.path()).unwrap();

        // Scan Steam
        let games = mac_gaming_scanner::SteamScanner::scan_steam(&steam_dir).unwrap();
        assert_eq!(games.len(), 2);

        for g in &games {
            engine.database.upsert_game(g).unwrap();
        }

        let all_games = engine.database.get_all_games().unwrap();
        assert_eq!(all_games.len(), 2);

        let bg3 = all_games.iter().find(|g| g.id == "steam_1086940").unwrap();
        assert!(bg3.is_native);
        assert_eq!(bg3.detected_status, CompatibilityStatus::Native);

        let elden = all_games.iter().find(|g| g.id == "steam_1245620").unwrap();
        assert!(!elden.is_native);

        // Prepare launch for Elden Ring
        let elden_env = engine.prepare_launch("steam_1245620").unwrap();
        assert_eq!(elden_env.command, "wine64");
        assert!(elden_env.environment_variables.contains_key("WINEPREFIX"));
        assert!(elden_env.prefix_path.is_some());
    }

    #[test]
    fn test_custom_game_import_and_overrides() {
        let temp_dir = tempdir().unwrap();
        let game_file = temp_dir.path().join("IndieGame.exe");
        File::create(&game_file).unwrap();

        let engine = MacGamingEngine::init_with_storage(temp_dir.path()).unwrap();
        let imported = engine
            .import_custom_game(&game_file, Some("My Custom Indie Game"))
            .unwrap();

        assert_eq!(imported.id, "local_my_custom_indie_game");
        assert_eq!(imported.title, "My Custom Indie Game");
        assert!(!imported.is_native);

        // Prepare launch with HUD and DXVK override options
        let opts = LaunchOverrideOptions {
            force_dxvk: Some(true),
            enable_hud: Some(true),
            ..Default::default()
        };

        let env = engine
            .prepare_launch_with_options("local_my_custom_indie_game", Some(&opts))
            .unwrap();
        assert_eq!(env.environment_variables.get("WINE_D3D_METAL"), Some(&"0".to_string()));
        assert_eq!(env.environment_variables.get("DXVK_HUD"), Some(&"devinfo,fps".to_string()));
        assert_eq!(env.environment_variables.get("MTL_HUD_ENABLED"), Some(&"1".to_string()));
    }

    #[test]
    fn test_troubleshooter_integration() {
        let error_log = r#"
            002c:err:module:import_dll Library MSVCP140.dll (which is needed by L"Z:\\Games\\Cyberpunk.exe") not found
            002c:err:d3d12:D3D12CreateDevice failed to create direct3d 12 pipeline
        "#;

        let report = Troubleshooter::analyze_logs(error_log);
        assert!(report.has_critical_issues);
        assert_eq!(report.findings.len(), 2);
        assert!(report
            .findings
            .iter()
            .any(|f| f.category == CrashCategory::MissingMsvcRuntime));
        assert!(report
            .findings
            .iter()
            .any(|f| f.category == CrashCategory::DirectXTranslationMismatch));
    }
}
