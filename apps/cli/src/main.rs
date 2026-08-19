use anyhow::Result;
use clap::{Parser, Subcommand, ValueEnum};
use colored::*;
use mac_gaming_core::diagnostics::HostSystemDiagnostics;
use mac_gaming_core::{
    BenchmarkEngine, BenchmarkMetric, LaunchOverrideOptions, MacGamingEngine, Troubleshooter,
};
use mac_gaming_profiles::CompatibilityStatus;
use std::path::PathBuf;
use tabled::{Table, Tabled};

#[derive(Parser)]
#[command(name = "mac-gaming")]
#[command(about = "Mac Gaming - High-performance unified game compatibility engine for macOS", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Clone, Copy, ValueEnum)]
enum StorefrontChoice {
    All,
    Steam,
    Epic,
    Gog,
    Itch,
    Ubisoft,
    Ea,
    BattleNet,
}

#[derive(Subcommand)]
enum Commands {
    /// Probe host Mac hardware, Apple Silicon chip, Metal support, and Rosetta 2
    Diagnostics,
    /// Scan Steam, Epic, GOG, itch.io, Ubisoft, EA, Battle.net or local folders
    Scan {
        #[arg(short, long, value_enum, default_value_t = StorefrontChoice::All)]
        storefront: StorefrontChoice,
        #[arg(short, long)]
        path: Option<PathBuf>,
    },
    /// Import an arbitrary Windows .exe game or macOS .app bundle
    Import {
        path: PathBuf,
        #[arg(short, long)]
        title: Option<String>,
    },
    /// Import an arbitrary Windows application/productivity tool
    ImportApp {
        path: PathBuf,
        #[arg(short, long)]
        title: Option<String>,
    },
    /// Analyze Wine, D3DMetal, or DXVK logs and suggest automated 1-click fixes
    Troubleshoot {
        #[arg(short, long)]
        file: Option<PathBuf>,
        #[arg(short, long)]
        log_sample: Option<String>,
    },
    /// List all discovered and indexed games and applications
    List,
    /// Inspect binary headers, DirectX/Metal requirements, and anti-cheat for a game
    Info {
        game_id: String,
    },
    /// Generate launch environment and prefix configuration for a game
    Launch {
        game_id: String,
        #[arg(long, default_value_t = true)]
        dry_run: bool,
        #[arg(long)]
        hud: bool,
        #[arg(long)]
        dxvk: bool,
        #[arg(long)]
        d3dmetal: bool,
        #[arg(long, default_value_t = true)]
        esync: bool,
        #[arg(long, default_value_t = true)]
        fsync: bool,
    },
    /// Simulate running a hardware benchmark session for a game
    Benchmark {
        game_id: String,
        #[arg(short, long, default_value_t = 60)]
        target_fps: u32,
    },
    /// Install or inspect curated default compatibility profiles
    InitProfiles {
        #[arg(short, long)]
        source_dir: Option<PathBuf>,
    },
    /// Synchronize compatibility profiles and community ratings from remote repository
    Sync,
}

#[derive(Tabled)]
struct GameTableRow {
    #[tabled(rename = "Status")]
    status: String,
    #[tabled(rename = "Title")]
    title: String,
    #[tabled(rename = "Storefront")]
    storefront: String,
    #[tabled(rename = "ID")]
    id: String,
    #[tabled(rename = "Type")]
    game_type: String,
}

fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    let cli = Cli::parse();

    match cli.command {
        Commands::Diagnostics => {
            println!("{}", "══════════════════════════════════════════════".bright_cyan());
            println!("{}", "               MAC GAMING DIAGNOSTICS         ".bright_white().bold());
            println!("{}", "══════════════════════════════════════════════".bright_cyan());

            let diag = HostSystemDiagnostics::probe();
            println!("{}: {}", "Mac Hardware".bold(), diag.chip_name.green());
            println!("{}: {} Cores", "CPU Cores".bold(), diag.core_count);
            println!("{}: {} GB Unified Memory", "RAM".bold(), diag.total_memory_gb);
            println!("{}: {} ({})", "OS".bold(), diag.os_version.blue(), diag.os_build.dimmed());
            println!("{}: {}", "Graphics API".bold(), diag.metal_version.cyan());
            println!("\n{}", "Gaming Environment:".bold());
            println!("  {} Apple Silicon Architecture", if diag.is_apple_silicon { "✓".green() } else { "✗".red() });
            println!("  {} Metal Translation Layer", if diag.metal_supported { "✓".green() } else { "✗".red() });
            println!("  {} Rosetta 2 Emulation", if diag.rosetta_installed { "✓".green() } else { "✗".yellow() });
            println!("  {} Native Game Controller Framework", if diag.controller_support { "✓".green() } else { "✗".red() });
            println!("\n{}", "Compatibility Engine: Ready".bright_green().bold());
        }

        Commands::Scan { storefront, path } => {
            let engine = MacGamingEngine::init()?;
            println!("{}", "Scanning for installed games and software...".bright_blue());

            if let Some(custom_dir) = path {
                let games = engine.scan_custom_directory(&custom_dir)?;
                println!("Discovered {} items in custom directory: {}", games.len(), custom_dir.display());
            } else {
                match storefront {
                    StorefrontChoice::All => {
                        let games = engine.scan_all_storefronts()?;
                        println!("Discovered {} total games/apps across all launchers.", games.len());
                    }
                    StorefrontChoice::Steam => {
                        let games = engine.scan_steam()?;
                        println!("Discovered {} games from Steam.", games.len());
                    }
                    StorefrontChoice::Epic => {
                        let games = engine.scan_epic()?;
                        println!("Discovered {} games from Epic Games / Heroic.", games.len());
                    }
                    StorefrontChoice::Gog => {
                        let games = engine.scan_gog()?;
                        println!("Discovered {} games from GOG Galaxy.", games.len());
                    }
                    StorefrontChoice::Itch => {
                        let games = engine.scan_itch()?;
                        println!("Discovered {} games from itch.io.", games.len());
                    }
                    StorefrontChoice::Ubisoft => {
                        let games = engine.scan_ubisoft()?;
                        println!("Discovered {} games from Ubisoft Connect.", games.len());
                    }
                    StorefrontChoice::Ea => {
                        let games = engine.scan_ea()?;
                        println!("Discovered {} games from EA App.", games.len());
                    }
                    StorefrontChoice::BattleNet => {
                        let games = engine.scan_battlenet()?;
                        println!("Discovered {} games from Battle.net.", games.len());
                    }
                }
            }

            println!("{}", "Scan complete and local library database synchronized.".green());
        }

        Commands::Import { path, title } => {
            let engine = MacGamingEngine::init()?;
            println!("Importing game: {}", path.display());
            let game = engine.import_custom_game(&path, title.as_deref())?;

            println!("{}", "Game successfully imported into Mac Gaming!".bright_green().bold());
            println!("  ID: {}", game.id.cyan());
            println!("  Title: {}", game.title.bold());
            println!("  Storefront: {}", game.storefront.display_name());
            println!("  Type: {}", if game.is_native { "Native macOS".green() } else { "Windows (Wine Sandbox)".blue() });
            println!("  Status: {}", game.detected_status.display_label());
        }

        Commands::ImportApp { path, title } => {
            let engine = MacGamingEngine::init()?;
            println!("Importing universal application: {}", path.display());
            let app = engine.import_universal_application(&path, title.as_deref())?;

            println!("{}", "Universal Application successfully registered!".bright_green().bold());
            println!("  ID: {}", app.id.cyan());
            println!("  Title: {}", app.title.bold());
            println!("  Storefront: {}", app.storefront.display_name());
            println!("  Status: {}", app.detected_status.display_label());
        }

        Commands::Troubleshoot { file, log_sample } => {
            let log_text = if let Some(f) = file {
                std::fs::read_to_string(&f)?
            } else if let Some(sample) = log_sample {
                sample
            } else {
                println!("{}", "Please specify a log file with `--file <path>` or snippet with `--log-sample <string>`.".yellow());
                return Ok(());
            };

            println!("{}", "══════════════════════════════════════════════".bright_magenta());
            println!("{}", "         AUTOMATED TROUBLESHOOTING REPORT     ".bright_white().bold());
            println!("{}", "══════════════════════════════════════════════".bright_magenta());

            let report = Troubleshooter::analyze_logs(&log_text);
            println!("Summary: {}\n", report.summary.bold());

            if report.findings.is_empty() {
                println!("{}", "✓ No known crash signatures detected in the provided log.".green());
            } else {
                for (i, finding) in report.findings.iter().enumerate() {
                    let sev_colored = match finding.severity {
                        mac_gaming_core::DiagnosticSeverity::Critical => "CRITICAL".bright_red().bold(),
                        mac_gaming_core::DiagnosticSeverity::Warning => "WARNING".bright_yellow().bold(),
                        mac_gaming_core::DiagnosticSeverity::Info => "INFO".bright_blue().bold(),
                    };

                    println!("{}. [{}] {}", i + 1, sev_colored, finding.title.bold());
                    println!("   Description: {}", finding.description);
                    if let Some(ref snippet) = finding.log_snippet {
                        println!("   Log Trace: {}", snippet.dimmed());
                    }
                    println!("   Fix: {}", finding.recommended_action.bright_cyan());
                    if let Some(ref cmd) = finding.auto_fix_command {
                        println!("   Auto-Fix Command: {}", cmd.bright_green().bold());
                    }
                    println!();
                }
            }
        }

        Commands::Benchmark { game_id, target_fps } => {
            let engine = MacGamingEngine::init()?;
            println!("{}", "══════════════════════════════════════════════".bright_cyan());
            println!("       HARDWARE BENCHMARK & TELEMETRY         ");
            println!("{}", "══════════════════════════════════════════════".bright_cyan());
            println!("Game: {}", game_id.bold());
            println!("Host Chip: {}", engine.diagnostics.chip_name.green());
            println!("Target: {} FPS\n", target_fps);

            // Synthetic telemetry session
            let target_f = target_fps as f32;
            let sample_metrics = vec![
                BenchmarkMetric { timestamp_sec: 1.0, fps: target_f - 1.0, frametime_ms: 1000.0 / target_f, gpu_load_pct: 78.0 },
                BenchmarkMetric { timestamp_sec: 2.0, fps: target_f, frametime_ms: 1000.0 / target_f, gpu_load_pct: 79.0 },
                BenchmarkMetric { timestamp_sec: 3.0, fps: target_f + 1.0, frametime_ms: 1000.0 / (target_f + 1.0), gpu_load_pct: 80.0 },
                BenchmarkMetric { timestamp_sec: 4.0, fps: target_f - 0.5, frametime_ms: 1000.0 / (target_f - 0.5), gpu_load_pct: 81.0 },
                BenchmarkMetric { timestamp_sec: 5.0, fps: target_f, frametime_ms: 1000.0 / target_f, gpu_load_pct: 77.0 },
            ];

            let session = BenchmarkEngine::compute_session(
                &format!("sess_{}", game_id),
                &game_id,
                &engine.diagnostics.chip_name,
                sample_metrics,
            );

            println!("{}: {} FPS", "Average FPS".bold(), session.avg_fps.to_string().bright_green().bold());
            println!("{}: {} FPS", "1% Low FPS".bold(), session.one_percent_low_fps);
            println!("{}: {} FPS / {} FPS", "Min / Max FPS".bold(), session.min_fps, session.max_fps);
            println!("{}: {:.2} ms", "Avg Frametime".bold(), session.avg_frametime_ms);
            println!("{}: {} frames", "Sample Count".bold(), session.samples_count);
        }

        Commands::List => {
            let engine = MacGamingEngine::init()?;
            let games = engine.get_all_games()?;

            if games.is_empty() {
                println!("{}", "No games or apps indexed yet. Run `mac-gaming scan` to discover installed software.".yellow());
                return Ok(());
            }

            let rows: Vec<GameTableRow> = games
                .into_iter()
                .map(|g| {
                    let badge = match g.detected_status {
                        CompatibilityStatus::Native => "[Native]".to_string(),
                        CompatibilityStatus::Compatible => "[Ready]".to_string(),
                        CompatibilityStatus::Experimental => "[Experimental]".to_string(),
                        CompatibilityStatus::CommunityFix => "[Fix Required]".to_string(),
                        CompatibilityStatus::Unsupported => "[Blocked]".to_string(),
                    };

                    GameTableRow {
                        status: badge,
                        title: g.title,
                        storefront: g.storefront.display_name().to_string(),
                        id: g.id,
                        game_type: if g.is_native {
                            "Native macOS".to_string()
                        } else if g.is_universal_app {
                            "Universal Windows App".to_string()
                        } else {
                            "Windows Game (Wine/Metal)".to_string()
                        },
                    }
                })
                .collect();

            let table = Table::new(rows).to_string();
            println!("\n{}", table);
        }

        Commands::Info { game_id } => {
            let engine = MacGamingEngine::init()?;
            let games = engine.get_all_games()?;
            let game = games.iter().find(|g| g.id == game_id);

            match game {
                Some(g) => {
                    println!("{}", "══════════════════════════════════════════════".bright_cyan());
                    println!("  Software: {}", g.title.bright_white().bold());
                    println!("{}", "══════════════════════════════════════════════".bright_cyan());
                    println!("{}: {}", "ID".bold(), g.id);
                    println!("{}: {}", "Storefront".bold(), g.storefront.display_name());
                    println!("{}: {}", "Status".bold(), g.detected_status.display_label());
                    println!("{}: {}", "Executable".bold(), g.executable_path.display());

                    if let Some(profile) = engine.profile_store.get(&g.id) {
                        println!("\n{}", "Active Compatibility Profile:".bright_yellow().bold());
                        println!("  Wine Flavor: {}", profile.runtime.wine_flavor);
                        println!("  Windows Emulation: {}", profile.runtime.windows_version);
                        println!("  D3DMetal Translation: {}", profile.runtime.d3dmetal.enabled);
                        println!("  DXVK Translation: {}", profile.runtime.dxvk.enabled);

                        if let Some(rating) = profile.community_rating_percentage {
                            println!("  Community Rating: {}%", rating);
                        }

                        if let Some(rec) = profile.get_hardware_recommendation(&engine.diagnostics.chip_name) {
                            println!("\n{}", "Hardware Recommendations for Your Mac:".bright_green().bold());
                            if let Some(ref res) = rec.recommended_resolution {
                                println!("  Resolution: {}", res);
                            }
                            if let Some(fps) = rec.target_fps {
                                println!("  Target Framerate: {} FPS", fps);
                            }
                            if let Some(ref preset) = rec.settings_preset {
                                println!("  Preset: {}", preset);
                            }
                        }

                        if !profile.known_issues.is_empty() {
                            println!("\n{}", "Known Issues:".bright_red().bold());
                            for issue in &profile.known_issues {
                                println!("  • {}", issue);
                            }
                        }
                    }
                }
                None => {
                    println!("{}", format!("Item '{}' not found in database.", game_id).red());
                }
            }
        }

        Commands::Launch {
            game_id,
            dry_run,
            hud,
            dxvk,
            d3dmetal,
            esync,
            fsync,
        } => {
            let engine = MacGamingEngine::init()?;

            let override_opts = LaunchOverrideOptions {
                force_d3dmetal: if d3dmetal { Some(true) } else { None },
                force_dxvk: if dxvk { Some(true) } else { None },
                enable_hud: if hud { Some(true) } else { None },
                enable_esync: Some(esync),
                enable_fsync: Some(fsync),
                extra_args: Vec::new(),
            };

            let env = engine.prepare_launch_with_options(&game_id, Some(&override_opts))?;

            println!("{}", "Preparing compatibility sandbox environment...".bright_blue());
            println!("{}: {}", "Executable".bold(), env.command);
            println!("{}: {:?}", "Arguments".bold(), env.arguments);
            println!("{}: {}", "Working Directory".bold(), env.working_directory.display());

            if let Some(ref prefix) = env.prefix_path {
                println!("{}: {}", "Sandboxed Prefix".bold(), prefix.display());
            }

            println!("\n{}", "Configured Environment Variables:".bright_yellow().bold());
            for (k, v) in &env.environment_variables {
                println!("  {}={}", k, v);
            }

            if dry_run {
                println!("\n{}", "Dry-run launch command:".bright_green().bold());
                println!("{}", engine.prefix_manager.execute_dry_run(&env));
            }
        }

        Commands::InitProfiles { source_dir } => {
            let target_dir = dirs::home_dir()
                .unwrap_or_else(|| PathBuf::from("."))
                .join("Library/Application Support/MacGaming/profiles");
            std::fs::create_dir_all(&target_dir)?;

            let src = source_dir.unwrap_or_else(|| PathBuf::from("profiles"));
            if src.exists() {
                let mut count = 0;
                for entry in std::fs::read_dir(src)?.flatten() {
                    let p = entry.path();
                    if p.is_file() {
                        if let Some(name) = p.file_name() {
                            let dest = target_dir.join(name);
                            std::fs::copy(&p, &dest)?;
                            count += 1;
                        }
                    }
                }
                println!("Successfully installed {} compatibility profiles to {}", count, target_dir.display());
            } else {
                println!("Source directory {} not found.", src.display());
            }
        }

        Commands::Sync => {
            let mut engine = MacGamingEngine::init()?;
            println!("{}", "Connecting to Mac Gaming Community Repository...".bright_blue());
            let result = engine.sync_community_profiles()?;
            println!("{}", "✓ Community synchronization complete!".bright_green().bold());
            println!("  Profiles Synchronized: {}", result.updated_profiles_count);
            println!("  Games Indexed: {}", result.synced_game_ids.len());
            println!("  Status: {}", result.status_message);
        }
    }

    Ok(())
}
