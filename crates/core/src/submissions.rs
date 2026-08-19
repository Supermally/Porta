use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CompatibilityTier {
    Platinum, // Works perfectly out of the box with zero tweaks
    Gold,     // Works flawlessly after minor config or DLL tweak
    Silver,   // Playable with minor glitches or non-critical stutters
    Bronze,   // Barely playable with major compromises
    Broken,   // Will not launch, crashes, or blocked by anti-cheat
}

impl CompatibilityTier {
    pub fn badge_label(&self) -> &'static str {
        match self {
            Self::Platinum => "Platinum",
            Self::Gold => "Gold",
            Self::Silver => "Silver",
            Self::Bronze => "Bronze",
            Self::Broken => "Broken",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompatibilityReport {
    pub id: String,
    pub game_id: String,
    pub user_handle: String,
    pub rating_stars: u32,
    pub tier: CompatibilityTier,
    pub chip_name: String,
    pub os_version: String,
    pub upvotes: u32,
    pub downvotes: u32,
    pub comment: String,
    pub created_at: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProfileSubmission {
    pub game_id: String,
    pub title: String,
    pub wine_flavor: String,
    pub windows_version: String,
    pub use_d3dmetal: bool,
    pub use_dxvk: bool,
    pub target_chip: String,
    pub recommended_preset: String,
    pub target_fps: u32,
    pub dll_overrides: HashMap<String, String>,
    pub known_notes: String,
}

impl ProfileSubmission {
    pub fn to_yaml(&self) -> Result<String, serde_yaml::Error> {
        let yaml_obj = serde_json::json!({
            "schema_version": "1.0.0",
            "game_id": self.game_id,
            "title": self.title,
            "status": if self.use_d3dmetal || self.use_dxvk { "compatible" } else { "native" },
            "runtime": {
                "wine_flavor": self.wine_flavor,
                "windows_version": self.windows_version,
                "dxvk": {
                    "enabled": self.use_dxvk,
                    "hud": "0"
                },
                "d3dmetal": {
                    "enabled": self.use_d3dmetal,
                    "hud": false,
                    "msync": true
                },
                "environment": self.dll_overrides
            },
            "hardware_recommendations": [{
                "match_pattern": self.target_chip,
                "recommended_resolution": "1440p",
                "target_fps": self.target_fps,
                "settings_preset": self.recommended_preset,
                "notes": self.known_notes
            }],
            "community_rating_percentage": 95
        });

        serde_yaml::to_string(&yaml_obj)
    }
}
