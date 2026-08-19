use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StudioDemandCampaign {
    pub game_id: String,
    pub title: String,
    pub publisher: String,
    pub total_mac_requests: u64,
    pub hardware_distribution: HashMap<String, u64>,
    pub memory_distribution: HashMap<String, u64>,
    pub status: String,
    pub commercial_opportunity_estimate: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NativeDeveloperSpotlight {
    pub game_id: String,
    pub title: String,
    pub studio: String,
    pub banner_tag: String,
    pub metal_technologies: Vec<String>,
    pub description: String,
    pub performance_highlight: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnonymousTelemetryReport {
    pub active_mac_gamers: u64,
    pub top_chips: HashMap<String, f32>,
    pub avg_frametime_ms: f32,
    pub crash_free_rate_pct: f32,
}

pub struct DeveloperEcosystemManager;

impl DeveloperEcosystemManager {
    pub fn get_featured_campaigns() -> Vec<StudioDemandCampaign> {
        vec![
            StudioDemandCampaign {
                game_id: "cyberpunk_2077".to_string(),
                title: "Cyberpunk 2077".to_string(),
                publisher: "CD PROJEKT RED".to_string(),
                total_mac_requests: 48920,
                hardware_distribution: [
                    ("Apple M4 / M3 Max".to_string(), 18200),
                    ("Apple M2 Pro / Max".to_string(), 19400),
                    ("Apple M1 / M2 Base".to_string(), 11320),
                ].into_iter().collect(),
                memory_distribution: [
                    ("16GB - 24GB Unified Memory".to_string(), 28400),
                    ("32GB - 128GB Unified Memory".to_string(), 16200),
                    ("8GB Unified Memory".to_string(), 4320),
                ].into_iter().collect(),
                status: "High Commercial Demand".to_string(),
                commercial_opportunity_estimate: "Estimated ~$3.2M incremental macOS launch revenue.".to_string(),
            },
            StudioDemandCampaign {
                game_id: "elden_ring".to_string(),
                title: "Elden Ring".to_string(),
                publisher: "Bandai Namco / FromSoftware".to_string(),
                total_mac_requests: 62140,
                hardware_distribution: [
                    ("Apple M3 / M4 Series".to_string(), 27400),
                    ("Apple M2 Series".to_string(), 22100),
                    ("Apple M1 Series".to_string(), 12640),
                ].into_iter().collect(),
                memory_distribution: [
                    ("16GB+ Unified Memory".to_string(), 51200),
                    ("8GB Unified Memory".to_string(), 10940),
                ].into_iter().collect(),
                status: "Top Requested RPG".to_string(),
                commercial_opportunity_estimate: "High overlap with Mac creative professional audience.".to_string(),
            },
            StudioDemandCampaign {
                game_id: "black_myth_wukong".to_string(),
                title: "Black Myth: Wukong".to_string(),
                publisher: "Game Science".to_string(),
                total_mac_requests: 39400,
                hardware_distribution: [
                    ("Apple M3 / M4 Max".to_string(), 18900),
                    ("Apple M2 Pro".to_string(), 14100),
                    ("Apple M1 Series".to_string(), 6400),
                ].into_iter().collect(),
                memory_distribution: [
                    ("16GB - 64GB Unified Memory".to_string(), 34800),
                    ("8GB Unified Memory".to_string(), 4600),
                ].into_iter().collect(),
                status: "Active Studio Petition".to_string(),
                commercial_opportunity_estimate: "High demand for native MetalFX Temporal upscaling port.".to_string(),
            },
        ]
    }

    pub fn get_native_spotlights() -> Vec<NativeDeveloperSpotlight> {
        vec![
            NativeDeveloperSpotlight {
                game_id: "baldurs_gate_3".to_string(),
                title: "Baldur's Gate 3".to_string(),
                studio: "Larian Studios".to_string(),
                banner_tag: "Native Apple Silicon Masterpiece".to_string(),
                metal_technologies: vec![
                    "Direct Metal 3 Pipeline".to_string(),
                    "Apple Silicon ARM64 Native".to_string(),
                    "DualSense Haptics & Game Controller API".to_string(),
                    "Spatial Audio".to_string(),
                ],
                description: "Larian Studios built a ground-up native macOS version with zero translation overhead, delivering 60-120 FPS across Apple Silicon Macs.".to_string(),
                performance_highlight: "Flawless native performance with full cross-save and Metal 3 shaders.".to_string(),
            },
            NativeDeveloperSpotlight {
                game_id: "death_stranding".to_string(),
                title: "Death Stranding Director's Cut".to_string(),
                studio: "Kojima Productions / 505 Games".to_string(),
                banner_tag: "MetalFX Upscaling Pioneer".to_string(),
                metal_technologies: vec![
                    "MetalFX Temporal Upscaling".to_string(),
                    "Metal 3 Mesh Shaders".to_string(),
                    "HDR Display Support".to_string(),
                    "Unified Memory Optimization".to_string(),
                ],
                description: "Optimized directly for Apple Silicon Unified Memory architecture, providing seamless 4K rendering on Mac Studio and MacBook Pro.".to_string(),
                performance_highlight: "Pristine visuals utilizing Apple MetalFX hardware acceleration.".to_string(),
            },
            NativeDeveloperSpotlight {
                game_id: "resident_evil_4".to_string(),
                title: "Resident Evil 4 (Remake)".to_string(),
                studio: "Capcom".to_string(),
                banner_tag: "RE Engine on Metal 3".to_string(),
                metal_technologies: vec![
                    "RE Engine Metal 3 Port".to_string(),
                    "MetalFX Spatial & Temporal".to_string(),
                    "ProMotion 120Hz".to_string(),
                ],
                description: "Capcom brought the full console AAA experience to macOS with incredible performance scaling from MacBook Air to Mac Pro.".to_string(),
                performance_highlight: "Console-parity AAA fidelity running natively on Apple Silicon.".to_string(),
            },
            NativeDeveloperSpotlight {
                game_id: "hades_2".to_string(),
                title: "Hades II".to_string(),
                studio: "Supergiant Games".to_string(),
                banner_tag: "Day-One macOS Support".to_string(),
                metal_technologies: vec![
                    "Native Mach-O ARM64".to_string(),
                    "ProMotion 120Hz Liquid Motion".to_string(),
                    "Low-Power Metal Pipeline".to_string(),
                ],
                description: "Supergiant Games continues their gold standard of macOS support with day-one native Apple Silicon builds.".to_string(),
                performance_highlight: "Locked 120 FPS with minimal battery consumption.".to_string(),
            },
        ]
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_campaigns_and_spotlights() {
        let campaigns = DeveloperEcosystemManager::get_featured_campaigns();
        assert!(!campaigns.is_empty());
        assert_eq!(campaigns[0].title, "Cyberpunk 2077");

        let spotlights = DeveloperEcosystemManager::get_native_spotlights();
        assert!(!spotlights.is_empty());
        assert_eq!(spotlights[0].studio, "Larian Studios");
    }
}
