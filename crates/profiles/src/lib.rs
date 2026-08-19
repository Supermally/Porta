use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::Path;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ProfileError {
    #[error("Failed to read profile file: {0}")]
    Io(#[from] std::io::Error),
    #[error("Failed to parse YAML: {0}")]
    Yaml(#[from] serde_yaml::Error),
    #[error("Failed to parse JSON: {0}")]
    Json(#[from] serde_json::Error),
    #[error("Profile validation error: {0}")]
    Validation(String),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CompatibilityStatus {
    /// Native macOS build exists and runs directly without compatibility layers
    Native,
    /// Fully compatible through Wine/DirectX translation layer
    Compatible,
    /// Works with known glitches, reduced performance, or workarounds
    Experimental,
    /// Community profile/fix required before playing
    CommunityFix,
    /// Currently blocked (e.g. kernel anti-cheat, unsupported DRM)
    Unsupported,
}

impl CompatibilityStatus {
    pub fn badge_emoji(&self) -> &'static str {
        match self {
            Self::Native => "🟢",
            Self::Compatible => "🔵",
            Self::Experimental => "🟡",
            Self::CommunityFix => "🟠",
            Self::Unsupported => "🔴",
        }
    }

    pub fn display_label(&self) -> &'static str {
        match self {
            Self::Native => "Native macOS",
            Self::Compatible => "Compatible / Ready",
            Self::Experimental => "Experimental",
            Self::CommunityFix => "Community Fix Required",
            Self::Unsupported => "Unsupported / Blocked",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RuntimeConfig {
    pub wine_flavor: String,
    #[serde(default = "default_win_version")]
    pub windows_version: String,
    #[serde(default)]
    pub dxvk: DxvkConfig,
    #[serde(default)]
    pub d3dmetal: D3DMetalConfig,
    #[serde(default)]
    pub vkd3d: Vkd3dConfig,
    #[serde(default)]
    pub environment: HashMap<String, String>,
    #[serde(default)]
    pub launch_arguments: Vec<String>,
    #[serde(default)]
    pub winetricks: Vec<String>,
    #[serde(default, alias = "dependencies")]
    pub dependencies: Vec<String>,
}

fn default_win_version() -> String {
    "win10".to_string()
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct DxvkConfig {
    pub enabled: bool,
    #[serde(default)]
    pub version: Option<String>,
    #[serde(default)]
    pub hud: Option<String>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct D3DMetalConfig {
    pub enabled: bool,
    #[serde(default)]
    pub hud: bool,
    #[serde(default)]
    pub msync: bool,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Vkd3dConfig {
    pub enabled: bool,
    #[serde(default)]
    pub debug: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HardwareRecommendation {
    pub match_pattern: String,
    #[serde(default)]
    pub recommended_resolution: Option<String>,
    #[serde(default)]
    pub target_fps: Option<u32>,
    #[serde(default)]
    pub settings_preset: Option<String>,
    #[serde(default)]
    pub notes: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AntiCheatInfo {
    pub r#type: String,
    pub status: String,
    #[serde(default)]
    pub notes: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompatibilityProfile {
    pub schema_version: String,
    pub game_id: String,
    pub title: String,
    pub status: CompatibilityStatus,
    pub runtime: RuntimeConfig,
    #[serde(default)]
    pub hardware_recommendations: Vec<HardwareRecommendation>,
    #[serde(default)]
    pub anti_cheat: Option<AntiCheatInfo>,
    #[serde(default)]
    pub known_issues: Vec<String>,
    #[serde(default)]
    pub community_rating_percentage: Option<u32>,
}

impl CompatibilityProfile {
    pub fn from_yaml_str(content: &str) -> Result<Self, ProfileError> {
        let profile: CompatibilityProfile = serde_yaml::from_str(content)?;
        Ok(profile)
    }

    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self, ProfileError> {
        let content = std::fs::read_to_string(path)?;
        Self::from_yaml_str(&content)
    }

    pub fn get_hardware_recommendation(&self, chip_name: &str) -> Option<&HardwareRecommendation> {
        for rec in &self.hardware_recommendations {
            if let Ok(re) = regex::Regex::new(&rec.match_pattern) {
                if re.is_match(chip_name) {
                    return Some(rec);
                }
            } else if chip_name.contains(&rec.match_pattern) {
                return Some(rec);
            }
        }
        None
    }
}

pub struct ProfileStore {
    profiles: HashMap<String, CompatibilityProfile>,
}

impl ProfileStore {
    pub fn new() -> Self {
        Self {
            profiles: HashMap::new(),
        }
    }

    pub fn load_from_directory<P: AsRef<Path>>(&mut self, dir: P) -> Result<usize, ProfileError> {
        let mut count = 0;
        if !dir.as_ref().exists() {
            return Ok(0);
        }

        for entry in std::fs::read_dir(dir)? {
            let entry = entry?;
            let path = entry.path();
            if let Some(ext) = path.extension() {
                if ext == "yaml" || ext == "yml" || ext == "json" {
                    if let Ok(profile) = CompatibilityProfile::from_file(&path) {
                        self.profiles.insert(profile.game_id.clone(), profile);
                        count += 1;
                    }
                }
            }
        }
        Ok(count)
    }

    pub fn get(&self, game_id: &str) -> Option<&CompatibilityProfile> {
        self.profiles.get(game_id)
    }

    pub fn list_all(&self) -> Vec<&CompatibilityProfile> {
        self.profiles.values().collect()
    }

    pub fn insert(&mut self, profile: CompatibilityProfile) {
        self.profiles.insert(profile.game_id.clone(), profile);
    }
}

impl Default for ProfileStore {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_profile_deserialization() {
        let yaml = r#"
schema_version: "1.0.0"
game_id: "steam_1245620"
title: "Elden Ring"
status: "compatible"
runtime:
  wine_flavor: "wine-cx-23.7"
  windows_version: "win10"
  dxvk:
    enabled: false
  d3dmetal:
    enabled: true
    hud: false
    msync: true
  environment:
    WINEDLLOVERRIDES: "dinput8=n,b"
    WINEESYNC: "1"
hardware_recommendations:
  - match_pattern: "Apple M[1-4]"
    recommended_resolution: "1440p"
    target_fps: 60
    settings_preset: "Medium"
anti_cheat:
  type: "easy_anti_cheat"
  status: "supported"
known_issues:
  - "Shader compilation stutter on first visit"
community_rating_percentage: 94
"#;

        let profile = CompatibilityProfile::from_yaml_str(yaml).unwrap();
        assert_eq!(profile.title, "Elden Ring");
        assert_eq!(profile.status, CompatibilityStatus::Compatible);
        assert!(profile.runtime.d3dmetal.enabled);
        assert_eq!(profile.community_rating_percentage, Some(94));

        let rec = profile.get_hardware_recommendation("Apple M3 Max");
        assert!(rec.is_some());
        assert_eq!(rec.unwrap().settings_preset.as_deref(), Some("Medium"));
    }
}
