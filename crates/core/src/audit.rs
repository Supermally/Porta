use forge_profiles::CompatibilityStatus;
use forge_scanner::DiscoveredGame;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LibraryStateAudit {
    pub total_games: usize,
    pub native_count: usize,
    pub native_pct: f32,
    pub compatible_count: usize,
    pub compatible_pct: f32,
    pub experimental_count: usize,
    pub experimental_pct: f32,
    pub unsupported_count: usize,
    pub unsupported_pct: f32,
    pub translation_reliance_pct: f32,
    pub storefront_distribution: HashMap<String, usize>,
    pub headline_insight: String,
    pub developer_callout: String,
}

pub struct LibraryAuditEngine;

impl LibraryAuditEngine {
    pub fn audit(games: &[DiscoveredGame]) -> LibraryStateAudit {
        let total = games.len();
        if total == 0 {
            return LibraryStateAudit {
                total_games: 0,
                native_count: 0,
                native_pct: 0.0,
                compatible_count: 0,
                compatible_pct: 0.0,
                experimental_count: 0,
                experimental_pct: 0.0,
                unsupported_count: 0,
                unsupported_pct: 0.0,
                translation_reliance_pct: 0.0,
                storefront_distribution: HashMap::new(),
                headline_insight: "No games discovered yet in library.".to_string(),
                developer_callout: "Connect your storefronts or import games to see your library audit.".to_string(),
            };
        }

        let mut native_count = 0;
        let mut compatible_count = 0;
        let mut experimental_count = 0;
        let mut unsupported_count = 0;
        let mut storefronts: HashMap<String, usize> = HashMap::new();

        for g in games {
            let sf_name = format!("{:?}", g.storefront);
            *storefronts.entry(sf_name).or_insert(0) += 1;

            if g.is_native || g.detected_status == CompatibilityStatus::Native {
                native_count += 1;
            } else {
                match g.detected_status {
                    CompatibilityStatus::Compatible => compatible_count += 1,
                    CompatibilityStatus::Experimental | CompatibilityStatus::CommunityFix => experimental_count += 1,
                    CompatibilityStatus::Unsupported => unsupported_count += 1,
                    _ => compatible_count += 1,
                }
            }
        }

        let native_pct = (native_count as f32 / total as f32) * 100.0;
        let compatible_pct = (compatible_count as f32 / total as f32) * 100.0;
        let experimental_pct = (experimental_count as f32 / total as f32) * 100.0;
        let unsupported_pct = (unsupported_count as f32 / total as f32) * 100.0;
        let translation_reliance_pct = ((total - native_count) as f32 / total as f32) * 100.0;

        let headline_insight = format!(
            "{:.0}% of your game library does not have a native macOS version and relies on Forge compatibility technologies.",
            translation_reliance_pct
        );

        let developer_callout = format!(
            "Out of {} total owned games, {} run natively, {} run via D3DMetal/DXVK translation, and {} are blocked by anti-cheat.",
            total, native_count, compatible_count + experimental_count, unsupported_count
        );

        LibraryStateAudit {
            total_games: total,
            native_count,
            native_pct,
            compatible_count,
            compatible_pct,
            experimental_count,
            experimental_pct,
            unsupported_count,
            unsupported_pct,
            translation_reliance_pct,
            storefront_distribution: storefronts,
            headline_insight,
            developer_callout,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use forge_scanner::Storefront;
    use std::path::PathBuf;

    #[test]
    fn test_library_audit_calculation() {
        let games = vec![
            DiscoveredGame {
                id: "1".to_string(),
                title: "Baldur's Gate 3".to_string(),
                storefront: Storefront::Steam,
                storefront_app_id: None,
                install_path: PathBuf::from("/"),
                executable_path: PathBuf::from("/"),
                is_native: true,
                is_universal_app: false,
                acquisition_path: "native_storefront".to_string(),
                detected_status: CompatibilityStatus::Native,
                analysis: None,
            },
            DiscoveredGame {
                id: "2".to_string(),
                title: "Elden Ring".to_string(),
                storefront: Storefront::Steam,
                storefront_app_id: None,
                install_path: PathBuf::from("/"),
                executable_path: PathBuf::from("/"),
                is_native: false,
                is_universal_app: false,
                acquisition_path: "storefront_integration".to_string(),
                detected_status: CompatibilityStatus::Compatible,
                analysis: None,
            },
        ];

        let audit = LibraryAuditEngine::audit(&games);
        assert_eq!(audit.total_games, 2);
        assert_eq!(audit.native_count, 1);
        assert_eq!(audit.compatible_count, 1);
        assert_eq!(audit.translation_reliance_pct, 50.0);
    }
}
