pub mod provisioner;
pub mod runtime;

pub use provisioner::{DependencyStatus, PrefixProvisioner, ProvisioningPlan};
pub use runtime::{RuntimeEnvironment, RuntimeManager};

use mac_gaming_profiles::{CompatibilityProfile, RuntimeConfig};
use mac_gaming_scanner::DiscoveredGame;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum PrefixError {
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Runtime binary not found: {0}")]
    RuntimeNotFound(String),
    #[error("Execution failed: {0}")]
    ExecutionFailed(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LaunchEnvironment {
    pub command: String,
    pub arguments: Vec<String>,
    pub environment_variables: HashMap<String, String>,
    pub working_directory: PathBuf,
    pub prefix_path: Option<PathBuf>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct LaunchOverrideOptions {
    pub force_d3dmetal: Option<bool>,
    pub force_dxvk: Option<bool>,
    pub enable_hud: Option<bool>,
    pub enable_esync: Option<bool>,
    pub enable_fsync: Option<bool>,
    pub extra_args: Vec<String>,
}

pub struct PrefixManager {
    base_prefix_dir: PathBuf,
}

impl PrefixManager {
    pub fn new() -> Self {
        let base_prefix_dir = dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Library/Application Support/MacGaming/prefixes");
        Self { base_prefix_dir }
    }

    pub fn with_prefix_dir<P: Into<PathBuf>>(dir: P) -> Self {
        Self {
            base_prefix_dir: dir.into(),
        }
    }

    pub fn get_prefix_dir(&self, game_id: &str) -> PathBuf {
        self.base_prefix_dir.join(game_id)
    }

    pub fn ensure_prefix_exists(&self, game_id: &str) -> Result<PathBuf, PrefixError> {
        let prefix = self.get_prefix_dir(game_id);
        if !prefix.exists() {
            std::fs::create_dir_all(&prefix)?;
            tracing::info!("Created isolated Wine prefix at: {}", prefix.display());
        }
        Ok(prefix)
    }

    pub fn build_launch_environment(
        &self,
        game: &DiscoveredGame,
        profile: Option<&CompatibilityProfile>,
    ) -> Result<LaunchEnvironment, PrefixError> {
        self.build_launch_environment_with_options(game, profile, None)
    }

    pub fn build_launch_environment_with_options(
        &self,
        game: &DiscoveredGame,
        profile: Option<&CompatibilityProfile>,
        options: Option<&LaunchOverrideOptions>,
    ) -> Result<LaunchEnvironment, PrefixError> {
        if game.is_native {
            // Native macOS execution
            let working_dir = game.install_path.clone();
            let mut args = Vec::new();
            if let Some(prof) = profile {
                args.extend(prof.runtime.launch_arguments.clone());
            }
            if let Some(opts) = options {
                args.extend(opts.extra_args.clone());
            }

            let command = if game.executable_path.extension().map_or(false, |ext| ext == "app") {
                // Launch via macOS `open -n`
                args.insert(0, game.executable_path.display().to_string());
                args.insert(0, "-n".to_string());
                args.insert(0, "-a".to_string());
                "/usr/bin/open".to_string()
            } else {
                game.executable_path.display().to_string()
            };

            return Ok(LaunchEnvironment {
                command,
                arguments: args,
                environment_variables: HashMap::new(),
                working_directory: working_dir,
                prefix_path: None,
            });
        }

        // Windows Game via Wine / D3DMetal / DXVK
        let prefix = self.ensure_prefix_exists(&game.id)?;
        let mut env_vars = HashMap::new();

        env_vars.insert("WINEPREFIX".to_string(), prefix.display().to_string());
        env_vars.insert("WINEDEBUG".to_string(), "-all,fixme-all".to_string());
        env_vars.insert("WINEESYNC".to_string(), "1".to_string());
        env_vars.insert("WINEFSYNC".to_string(), "1".to_string());
        env_vars.insert("ROSETTA_DEBUGGER_PORT".to_string(), "0".to_string());

        // Default or profile-driven configuration
        let mut launch_args = Vec::new();
        let wine_bin = "wine64".to_string();

        if let Some(prof) = profile {
            self.apply_runtime_config(&prof.runtime, &mut env_vars);
            launch_args.extend(prof.runtime.launch_arguments.clone());
        } else {
            // Sane defaults for modern Apple Silicon + D3DMetal
            env_vars.insert("DXVK_HUD".to_string(), "0".to_string());
            env_vars.insert("WINE_D3D_METAL".to_string(), "1".to_string());
        }

        // Apply interactive user overrides if supplied
        if let Some(opts) = options {
            if let Some(d3dm) = opts.force_d3dmetal {
                if d3dm {
                    env_vars.insert("WINE_D3D_METAL".to_string(), "1".to_string());
                } else {
                    env_vars.insert("WINE_D3D_METAL".to_string(), "0".to_string());
                }
            }
            if let Some(dxvk) = opts.force_dxvk {
                if dxvk {
                    env_vars.insert("WINE_D3D_METAL".to_string(), "0".to_string());
                    if !env_vars.contains_key("DXVK_HUD") {
                        env_vars.insert("DXVK_HUD".to_string(), "devinfo,fps".to_string());
                    }
                }
            }
            if let Some(hud) = opts.enable_hud {
                if hud {
                    env_vars.insert("MTL_HUD_ENABLED".to_string(), "1".to_string());
                    env_vars.insert("DXVK_HUD".to_string(), "devinfo,fps".to_string());
                } else {
                    env_vars.insert("MTL_HUD_ENABLED".to_string(), "0".to_string());
                    env_vars.insert("DXVK_HUD".to_string(), "0".to_string());
                }
            }
            if let Some(esync) = opts.enable_esync {
                env_vars.insert("WINEESYNC".to_string(), if esync { "1".to_string() } else { "0".to_string() });
            }
            if let Some(fsync) = opts.enable_fsync {
                env_vars.insert("WINEFSYNC".to_string(), if fsync { "1".to_string() } else { "0".to_string() });
            }
            launch_args.extend(opts.extra_args.clone());
        }

        let mut final_args = vec![game.executable_path.display().to_string()];
        final_args.extend(launch_args);

        let working_dir = game
            .executable_path
            .parent()
            .map(|p| p.to_path_buf())
            .unwrap_or_else(|| game.install_path.clone());

        Ok(LaunchEnvironment {
            command: wine_bin,
            arguments: final_args,
            environment_variables: env_vars,
            working_directory: working_dir,
            prefix_path: Some(prefix),
        })
    }

    fn apply_runtime_config(
        &self,
        config: &RuntimeConfig,
        env_vars: &mut HashMap<String, String>,
    ) {
        for (k, v) in &config.environment {
            env_vars.insert(k.clone(), v.clone());
        }

        if config.d3dmetal.enabled {
            env_vars.insert("WINE_D3D_METAL".to_string(), "1".to_string());
            if config.d3dmetal.hud {
                env_vars.insert("MTL_HUD_ENABLED".to_string(), "1".to_string());
            }
            if config.d3dmetal.msync {
                env_vars.insert("WINE_MSYNC".to_string(), "1".to_string());
            }
        }

        if config.dxvk.enabled {
            env_vars.insert("WINE_D3D_METAL".to_string(), "0".to_string());
            if let Some(ref hud) = config.dxvk.hud {
                env_vars.insert("DXVK_HUD".to_string(), hud.clone());
            }
        }
    }

    pub fn execute_dry_run(&self, env: &LaunchEnvironment) -> String {
        let mut parts = Vec::new();
        for (k, v) in &env.environment_variables {
            parts.push(format!("{}={}", k, v));
        }
        parts.push(env.command.clone());
        parts.extend(env.arguments.clone());
        format!("cd {} && {}", env.working_directory.display(), parts.join(" "))
    }
}

impl Default for PrefixManager {
    fn default() -> Self {
        Self::new()
    }
}
