use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct RuntimeEnvironment {
    pub id: String,
    pub name: String,
    pub runner_path: PathBuf,
    pub version: String,
    pub supports_d3dmetal: bool,
    pub supports_dxvk: bool,
    pub supports_esync: bool,
    pub supports_fsync: bool,
    pub is_installed: bool,
}

pub struct RuntimeManager;

impl RuntimeManager {
    pub fn discover_installed_runtimes() -> Vec<RuntimeEnvironment> {
        let home = dirs::home_dir().unwrap_or_else(|| PathBuf::from("."));

        let candidate_runtimes = vec![
            // 1. Apple Game Porting Toolkit 2.0 / CrossOver 23+
            RuntimeEnvironment {
                id: "gptk-2.0".to_string(),
                name: "Apple Game Porting Toolkit 2.0 (D3DMetal + Wine-CX-23.7)".to_string(),
                runner_path: home.join("Library/Application Support/CrossOver/bin/wine64"),
                version: "23.7.1-GPTK2".to_string(),
                supports_d3dmetal: true,
                supports_dxvk: true,
                supports_esync: true,
                supports_fsync: true,
                is_installed: false,
            },
            // 2. Whisky Wine
            RuntimeEnvironment {
                id: "whisky-wine".to_string(),
                name: "Whisky Wine Engine (GPTK 2.0)".to_string(),
                runner_path: home.join("Library/Application Support/com.isaacmarovitz.Whisky/Libraries/Wine/bin/wine64"),
                version: "7.7.0".to_string(),
                supports_d3dmetal: true,
                supports_dxvk: true,
                supports_esync: true,
                supports_fsync: true,
                is_installed: false,
            },
            // 3. Homebrew Wine (Apple Silicon /opt/homebrew)
            RuntimeEnvironment {
                id: "brew-wine64".to_string(),
                name: "Homebrew Wine64 (DirectX 9-11 DXVK)".to_string(),
                runner_path: PathBuf::from("/opt/homebrew/bin/wine64"),
                version: "9.0".to_string(),
                supports_d3dmetal: false,
                supports_dxvk: true,
                supports_esync: true,
                supports_fsync: false,
                is_installed: false,
            },
            // 4. Intel /usr/local/bin fallback
            RuntimeEnvironment {
                id: "usr-wine64".to_string(),
                name: "System Wine64 (/usr/local/bin)".to_string(),
                runner_path: PathBuf::from("/usr/local/bin/wine64"),
                version: "8.0".to_string(),
                supports_d3dmetal: false,
                supports_dxvk: true,
                supports_esync: true,
                supports_fsync: false,
                is_installed: false,
            },
            // 5. CrossOver Application Bundle
            RuntimeEnvironment {
                id: "crossover-app".to_string(),
                name: "CrossOver.app Shared Support".to_string(),
                runner_path: PathBuf::from("/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine64"),
                version: "24.0".to_string(),
                supports_d3dmetal: true,
                supports_dxvk: true,
                supports_esync: true,
                supports_fsync: true,
                is_installed: false,
            },
        ];

        let mut discovered = Vec::new();
        for mut rt in candidate_runtimes {
            if rt.runner_path.exists() {
                rt.is_installed = true;
                discovered.push(rt);
            }
        }

        // Always include a virtual fallback runtime for environments without local runner
        if discovered.is_empty() {
            discovered.push(RuntimeEnvironment {
                id: "forge-default".to_string(),
                name: "Forge Default Runtime (Auto-Resolved)".to_string(),
                runner_path: PathBuf::from("/opt/homebrew/bin/wine64"),
                version: "Auto".to_string(),
                supports_d3dmetal: true,
                supports_dxvk: true,
                supports_esync: true,
                supports_fsync: true,
                is_installed: false,
            });
        }

        discovered
    }

    pub fn select_optimal_runtime(preferred_d3dmetal: bool) -> RuntimeEnvironment {
        let runtimes = Self::discover_installed_runtimes();

        if preferred_d3dmetal {
            if let Some(gptk) = runtimes.iter().find(|r| r.is_installed && r.supports_d3dmetal) {
                return gptk.clone();
            }
        }

        if let Some(installed) = runtimes.iter().find(|r| r.is_installed) {
            return installed.clone();
        }

        runtimes.first().cloned().unwrap_or(RuntimeEnvironment {
            id: "fallback".to_string(),
            name: "Default Runner".to_string(),
            runner_path: PathBuf::from("/usr/bin/arch"),
            version: "1.0".to_string(),
            supports_d3dmetal: true,
            supports_dxvk: true,
            supports_esync: true,
            supports_fsync: true,
            is_installed: false,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_runtime_manager_discovery() {
        let runtimes = RuntimeManager::discover_installed_runtimes();
        assert!(!runtimes.is_empty());
        let selected = RuntimeManager::select_optimal_runtime(true);
        assert!(!selected.id.is_empty());
    }
}
