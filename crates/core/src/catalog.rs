use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CatalogCompatibilityTier {
    Platinum,
    Gold,
    Silver,
    Bronze,
    Unsupported,
}

impl CatalogCompatibilityTier {
    pub fn display_name(&self) -> &'static str {
        match self {
            Self::Platinum => "Platinum (Flawless)",
            Self::Gold => "Gold (Minor Tweaks)",
            Self::Silver => "Silver (Playable with Quirks)",
            Self::Bronze => "Bronze (Experimental)",
            Self::Unsupported => "Unsupported (Blocked)",
        }
    }

    pub fn color_name(&self) -> &'static str {
        match self {
            Self::Platinum => "blue",
            Self::Gold => "green",
            Self::Silver => "orange",
            Self::Bronze => "yellow",
            Self::Unsupported => "red",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CatalogEntry {
    pub id: String,
    pub title: String,
    pub official_mac_native: bool,
    pub compatibility_tier: CatalogCompatibilityTier,
    pub available_storefronts: Vec<String>,
    pub recommendation: String,
    pub recommendation_reason: String,
    pub target_fps_by_chip: HashMap<String, u32>,
    pub known_issues: Vec<String>,
    pub anti_cheat_name: Option<String>,
}

pub struct UniversalCatalog;

impl UniversalCatalog {
    pub fn search(query: &str) -> Vec<CatalogEntry> {
        let all = Self::get_all_entries();
        if query.trim().is_empty() {
            return all;
        }

        let q = query.to_lowercase();
        all.into_iter()
            .filter(|e| e.title.to_lowercase().contains(&q) || e.id.contains(&q))
            .collect()
    }

    pub fn get_all_entries() -> Vec<CatalogEntry> {
        vec![
            CatalogEntry {
                id: "elden_ring".to_string(),
                title: "Elden Ring".to_string(),
                official_mac_native: false,
                compatibility_tier: CatalogCompatibilityTier::Platinum,
                available_storefronts: vec!["Steam".to_string()],
                recommendation: "D3DMetal + Wine-CX-23.7 (DirectX 12 Translation)".to_string(),
                recommendation_reason: "Flawless rendering via Apple D3DMetal; EAC Wine override applied automatically.".to_string(),
                target_fps_by_chip: [
                    ("Apple M1".to_string(), 45),
                    ("Apple M2".to_string(), 60),
                    ("Apple M3 Max".to_string(), 120),
                    ("Apple M4".to_string(), 90),
                ].into_iter().collect(),
                known_issues: vec!["Disable Ray Tracing in game settings for stable 60 FPS.".to_string()],
                anti_cheat_name: Some("Easy Anti-Cheat (Wine Compatible)".to_string()),
            },
            CatalogEntry {
                id: "baldurs_gate_3".to_string(),
                title: "Baldur's Gate 3".to_string(),
                official_mac_native: true,
                compatibility_tier: CatalogCompatibilityTier::Platinum,
                available_storefronts: vec!["Steam".to_string(), "GOG Galaxy".to_string()],
                recommendation: "Native macOS Apple Silicon (Zero Translation Overhead)".to_string(),
                recommendation_reason: "Official Apple Silicon native Mach-O build compiled directly for Metal 3.".to_string(),
                target_fps_by_chip: [
                    ("Apple M1".to_string(), 50),
                    ("Apple M2".to_string(), 60),
                    ("Apple M3 Max".to_string(), 120),
                ].into_iter().collect(),
                known_issues: vec![],
                anti_cheat_name: None,
            },
            CatalogEntry {
                id: "cyberpunk_2077".to_string(),
                title: "Cyberpunk 2077".to_string(),
                official_mac_native: false,
                compatibility_tier: CatalogCompatibilityTier::Gold,
                available_storefronts: vec!["Steam".to_string(), "GOG Galaxy".to_string(), "Epic Games".to_string()],
                recommendation: "D3DMetal 2.0 (DirectX 12) + FSR 2.1 Balanced".to_string(),
                recommendation_reason: "Runs smoothly with D3DMetal 2.0; Path Tracing unsupported.".to_string(),
                target_fps_by_chip: [
                    ("Apple M1".to_string(), 35),
                    ("Apple M2".to_string(), 55),
                    ("Apple M3 Max".to_string(), 95),
                ].into_iter().collect(),
                known_issues: vec!["Path Tracing must remain disabled.".to_string()],
                anti_cheat_name: None,
            },
            CatalogEntry {
                id: "minecraft".to_string(),
                title: "Minecraft (Java & Bedrock)".to_string(),
                official_mac_native: true,
                compatibility_tier: CatalogCompatibilityTier::Platinum,
                available_storefronts: vec!["Microsoft / Mojang".to_string()],
                recommendation: "Native macOS Java ARM64 Runtime".to_string(),
                recommendation_reason: "Runs natively with Apple Silicon ARM64 JVM and Metal rendering mods.".to_string(),
                target_fps_by_chip: [
                    ("Apple M1".to_string(), 120),
                    ("Apple M2".to_string(), 144),
                ].into_iter().collect(),
                known_issues: vec![],
                anti_cheat_name: None,
            },
            CatalogEntry {
                id: "fortnite".to_string(),
                title: "Fortnite".to_string(),
                official_mac_native: false,
                compatibility_tier: CatalogCompatibilityTier::Unsupported,
                available_storefronts: vec!["Epic Games".to_string()],
                recommendation: "Unsupported (Blocked by Kernel Anti-Cheat)".to_string(),
                recommendation_reason: "Requires Windows Ring 0 kernel driver (BattlEye / EAC) incompatible with macOS sandbox.".to_string(),
                target_fps_by_chip: HashMap::new(),
                known_issues: vec!["Kernel driver level anti-cheat prevents execution in Wine/macOS.".to_string()],
                anti_cheat_name: Some("BattlEye / Easy Anti-Cheat (Kernel Driver)".to_string()),
            },
            CatalogEntry {
                id: "valorant".to_string(),
                title: "Valorant".to_string(),
                official_mac_native: false,
                compatibility_tier: CatalogCompatibilityTier::Unsupported,
                available_storefronts: vec!["Riot Games".to_string()],
                recommendation: "Unsupported (Blocked by Riot Vanguard)".to_string(),
                recommendation_reason: "Requires Riot Vanguard hypervisor/kernel anti-cheat which cannot run on macOS.".to_string(),
                target_fps_by_chip: HashMap::new(),
                known_issues: vec!["Vanguard Ring 0 driver incompatible with macOS architecture.".to_string()],
                anti_cheat_name: Some("Riot Vanguard (Ring 0 Hypervisor)".to_string()),
            },
            CatalogEntry {
                id: "hades_2".to_string(),
                title: "Hades II".to_string(),
                official_mac_native: true,
                compatibility_tier: CatalogCompatibilityTier::Platinum,
                available_storefronts: vec!["Steam".to_string(), "Epic Games".to_string()],
                recommendation: "Native macOS Apple Silicon".to_string(),
                recommendation_reason: "Native macOS binary with 120Hz ProMotion support.".to_string(),
                target_fps_by_chip: [
                    ("Apple M1".to_string(), 120),
                    ("Apple M2".to_string(), 120),
                ].into_iter().collect(),
                known_issues: vec![],
                anti_cheat_name: None,
            },
            CatalogEntry {
                id: "witcher_3".to_string(),
                title: "The Witcher 3: Wild Hunt".to_string(),
                official_mac_native: false,
                compatibility_tier: CatalogCompatibilityTier::Platinum,
                available_storefronts: vec!["GOG Galaxy".to_string(), "Steam".to_string()],
                recommendation: "D3DMetal + Wine-CX-23.7 (DX12 Next-Gen)".to_string(),
                recommendation_reason: "DirectX 12 Next-Gen edition runs with high fidelity on Apple Silicon.".to_string(),
                target_fps_by_chip: [
                    ("Apple M1".to_string(), 45),
                    ("Apple M2".to_string(), 60),
                ].into_iter().collect(),
                known_issues: vec!["Disable HairWorks for +15 FPS boost on base chips.".to_string()],
                anti_cheat_name: None,
            },
            CatalogEntry {
                id: "black_myth_wukong".to_string(),
                title: "Black Myth: Wukong".to_string(),
                official_mac_native: false,
                compatibility_tier: CatalogCompatibilityTier::Gold,
                available_storefronts: vec!["Steam".to_string(), "Epic Games".to_string()],
                recommendation: "D3DMetal 2.0 + Unreal Engine 5.4 Profile".to_string(),
                recommendation_reason: "Playable at 1080p/1440p with TSR/FSR upscaling.".to_string(),
                target_fps_by_chip: [
                    ("Apple M2 Max".to_string(), 55),
                    ("Apple M3 Max".to_string(), 75),
                ].into_iter().collect(),
                known_issues: vec!["Requires minimum 16GB Unified Memory for high textures.".to_string()],
                anti_cheat_name: None,
            },
        ]
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_universal_catalog_search() {
        let results = UniversalCatalog::search("Elden");
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].title, "Elden Ring");
        assert_eq!(results[0].compatibility_tier, CatalogCompatibilityTier::Platinum);
    }

    #[test]
    fn test_unsupported_catalog_game() {
        let results = UniversalCatalog::search("Fortnite");
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].compatibility_tier, CatalogCompatibilityTier::Unsupported);
    }
}
