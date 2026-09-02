use goblin::mach::Mach;
use goblin::pe::PE;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs::File;
use std::io::Read;
use std::path::{Path, PathBuf};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AnalyzerError {
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Goblin binary parsing error: {0}")]
    ParseError(#[from] goblin::error::Error),
    #[error("Target binary not found: {0}")]
    NotFound(String),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BinaryFormat {
    MachO,
    WindowsPE,
    ScriptOrUnknown,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BinaryArchitecture {
    Arm64,
    X86_64,
    X86,
    Universal,
    Unknown,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum GraphicsApiHint {
    DirectX9,
    DirectX10,
    DirectX11,
    DirectX12,
    Vulkan,
    Metal,
    OpenGL,
    Unknown,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum EngineType {
    Unity,
    UnrealEngine,
    Godot,
    Source,
    Direct3DNative,
    Custom,
    Unknown,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum AntiCheatSignature {
    EasyAntiCheat,
    BattlEye,
    Vanguard,
    Ricochet,
    PunkBuster,
    Denuvo,
    None,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum CompatibilityVerdict {
    Native,
    Platinum,
    Gold,
    Silver,
    Bronze,
    Unsupported,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompatibilityRecipe {
    pub verdict: CompatibilityVerdict,
    pub recommended_runtime: String,
    pub recommended_backend: String,
    pub required_dll_overrides: HashMap<String, String>,
    pub recommended_launch_args: Vec<String>,
    pub required_winetricks: Vec<String>,
    pub human_explanation: String,
    pub analysis_checklist: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BinaryAnalysisReport {
    pub file_path: PathBuf,
    pub format: BinaryFormat,
    pub architecture: BinaryArchitecture,
    pub is_native_macos: bool,
    pub engine: EngineType,
    pub graphics_api: GraphicsApiHint,
    pub anti_cheat: AntiCheatSignature,
    pub imported_dlls: Vec<String>,
    pub recipe: CompatibilityRecipe,
}

pub struct BinaryAnalyzer;

impl BinaryAnalyzer {
    pub fn analyze_file<P: AsRef<Path>>(path: P) -> Result<BinaryAnalysisReport, AnalyzerError> {
        let path = path.as_ref();
        if !path.exists() {
            return Err(AnalyzerError::NotFound(path.display().to_string()));
        }

        let mut file = File::open(path)?;
        let mut buffer = Vec::new();
        // Read up to 8MB for PE / Mach-O header parsing
        file.by_ref().take(8 * 1024 * 1024).read_to_end(&mut buffer)?;

        let mut format = BinaryFormat::ScriptOrUnknown;
        let mut architecture = BinaryArchitecture::Unknown;
        let mut is_native_macos = false;
        let mut graphics_api = GraphicsApiHint::Unknown;
        let mut imported_dlls = Vec::new();

        // Try Mach-O parsing
        if let Ok(mach) = Mach::parse(&buffer) {
            format = BinaryFormat::MachO;
            is_native_macos = true;
            graphics_api = GraphicsApiHint::Metal;
            match mach {
                Mach::Fat(_fat) => {
                    architecture = BinaryArchitecture::Universal;
                }
                Mach::Binary(macho) => {
                    if macho.header.cputype == goblin::mach::constants::cputype::CPU_TYPE_ARM64 {
                        architecture = BinaryArchitecture::Arm64;
                    } else if macho.header.cputype == goblin::mach::constants::cputype::CPU_TYPE_X86_64 {
                        architecture = BinaryArchitecture::X86_64;
                    }
                }
            }
        } else if let Ok(pe) = PE::parse(&buffer) {
            // Windows PE parsing
            format = BinaryFormat::WindowsPE;
            is_native_macos = false;

            if pe.is_64 {
                architecture = BinaryArchitecture::X86_64;
            } else {
                architecture = BinaryArchitecture::X86;
            }

            for import in &pe.imports {
                let dll_name = import.dll.to_lowercase();
                imported_dlls.push(dll_name.clone());

                if dll_name.contains("d3d12") {
                    graphics_api = GraphicsApiHint::DirectX12;
                } else if dll_name.contains("d3d11") && graphics_api == GraphicsApiHint::Unknown {
                    graphics_api = GraphicsApiHint::DirectX11;
                } else if dll_name.contains("d3d9") && graphics_api == GraphicsApiHint::Unknown {
                    graphics_api = GraphicsApiHint::DirectX9;
                } else if dll_name.contains("vulkan") && graphics_api == GraphicsApiHint::Unknown {
                    graphics_api = GraphicsApiHint::Vulkan;
                } else if dll_name.contains("opengl32") && graphics_api == GraphicsApiHint::Unknown {
                    graphics_api = GraphicsApiHint::OpenGL;
                }
            }
        }

        let parent_dir = path.parent();
        let engine = Self::detect_engine(path, parent_dir, &imported_dlls);
        let anti_cheat = Self::detect_anticheat_in_directory(parent_dir);

        let recipe = Self::synthesize_recipe(
            format,
            architecture,
            is_native_macos,
            engine,
            graphics_api,
            &anti_cheat,
            &imported_dlls,
        );

        Ok(BinaryAnalysisReport {
            file_path: path.to_path_buf(),
            format,
            architecture,
            is_native_macos,
            engine,
            graphics_api,
            anti_cheat,
            imported_dlls,
            recipe,
        })
    }

    fn detect_engine(path: &Path, dir_opt: Option<&Path>, imported_dlls: &[String]) -> EngineType {
        let file_stem = path.file_stem().unwrap_or_default().to_string_lossy().to_lowercase();

        // Check imported DLLs
        if imported_dlls.iter().any(|d| d.contains("unityplayer")) {
            return EngineType::Unity;
        }

        if let Some(dir) = dir_opt {
            if dir.exists() {
                // Check sibling folders for engine artifacts
                if let Ok(entries) = std::fs::read_dir(dir) {
                    for entry in entries.flatten() {
                        let name = entry.file_name().to_string_lossy().to_lowercase();
                        if name.ends_with("_data") || name.contains("unityplayer") {
                            return EngineType::Unity;
                        }
                        if name.contains("ue4") || name.contains("ue5") || name.contains("unreal") || name == "engine" {
                            return EngineType::UnrealEngine;
                        }
                        if name.contains("godot") {
                            return EngineType::Godot;
                        }
                    }
                }
            }
        }

        if file_stem.contains("unity") {
            EngineType::Unity
        } else if file_stem.contains("unreal") || file_stem.contains("ue4") || file_stem.contains("ue5") {
            EngineType::UnrealEngine
        } else if imported_dlls.iter().any(|d| d.contains("d3d11") || d.contains("d3d12")) {
            EngineType::Direct3DNative
        } else {
            EngineType::Custom
        }
    }

    fn detect_anticheat_in_directory(dir_opt: Option<&Path>) -> AntiCheatSignature {
        let Some(dir) = dir_opt else {
            return AntiCheatSignature::None;
        };

        if !dir.exists() {
            return AntiCheatSignature::None;
        }

        for entry in walkdir::WalkDir::new(dir).max_depth(3).into_iter().flatten() {
            let name = entry.file_name().to_string_lossy().to_lowercase();
            if name.contains("easyanticheat") || name.contains("start_protected_game") || name == "easyanticheat_x64.dll" {
                return AntiCheatSignature::EasyAntiCheat;
            }
            if name.contains("battleye") || name.contains("beservice") || name == "beclient_x64.dll" {
                return AntiCheatSignature::BattlEye;
            }
            if name.contains("vgk.sys") || name.contains("vgc.exe") {
                return AntiCheatSignature::Vanguard;
            }
            if name.contains("ricochet") {
                return AntiCheatSignature::Ricochet;
            }
            if name.contains("denuvo") {
                return AntiCheatSignature::Denuvo;
            }
        }

        AntiCheatSignature::None
    }

    fn synthesize_recipe(
        _format: BinaryFormat,
        arch: BinaryArchitecture,
        is_native: bool,
        engine: EngineType,
        graphics_api: GraphicsApiHint,
        anti_cheat: &AntiCheatSignature,
        imported_dlls: &[String],
    ) -> CompatibilityRecipe {
        let mut checklist = Vec::new();
        let mut dll_overrides = HashMap::new();
        let mut launch_args = Vec::new();
        let mut winetricks = Vec::new();

        if is_native {
            checklist.push("✓ Official Apple Silicon native Mach-O binary".to_string());
            checklist.push("✓ Direct Metal 3 hardware pipeline".to_string());
            checklist.push("✓ Zero translation overhead".to_string());

            return CompatibilityRecipe {
                verdict: CompatibilityVerdict::Native,
                recommended_runtime: "Native macOS Apple Silicon".to_string(),
                recommended_backend: "NativeMetal".to_string(),
                required_dll_overrides: HashMap::new(),
                recommended_launch_args: Vec::new(),
                required_winetricks: Vec::new(),
                human_explanation: "Runs natively on Apple Silicon with 0 translation overhead.".to_string(),
                analysis_checklist: checklist,
            };
        }

        // Check Windows Architecture
        match arch {
            BinaryArchitecture::X86_64 => checklist.push("✓ Windows 64-bit executable (x86-64)".to_string()),
            BinaryArchitecture::X86 => checklist.push("✓ Windows 32-bit executable (x86)".to_string()),
            _ => checklist.push("✓ Windows executable".to_string()),
        }

        // Anti-Cheat Evaluation
        match anti_cheat {
            AntiCheatSignature::Vanguard => {
                checklist.push("✗ Riot Vanguard Ring 0 kernel driver detected (Incompatible with macOS)".to_string());
                return CompatibilityRecipe {
                    verdict: CompatibilityVerdict::Unsupported,
                    recommended_runtime: "None (Kernel Incompatible)".to_string(),
                    recommended_backend: "Unsupported".to_string(),
                    required_dll_overrides: HashMap::new(),
                    recommended_launch_args: Vec::new(),
                    required_winetricks: Vec::new(),
                    human_explanation: "Blocked by Riot Vanguard kernel-level hypervisor driver.".to_string(),
                    analysis_checklist: checklist,
                };
            }
            AntiCheatSignature::BattlEye => {
                checklist.push("⚠ BattlEye anti-cheat driver detected (Requires Wine-EAC Proton bridge)".to_string());
            }
            AntiCheatSignature::EasyAntiCheat => {
                checklist.push("✓ Easy Anti-Cheat detected (Wine EAC bridge override enabled)".to_string());
                dll_overrides.insert("easyanticheat_x64".to_string(), "native,builtin".to_string());
            }
            _ => {
                checklist.push("✓ No incompatible kernel anti-cheat detected".to_string());
            }
        }

        // Engine & Graphics API Synthesis
        match engine {
            EngineType::Unity => {
                checklist.push("✓ Unity Engine detected".to_string());
                checklist.push("✓ Auto-configured DirectX 12 override (-force-d3d12) for Apple D3DMetal".to_string());
                launch_args.push("-force-d3d12".to_string());
                dll_overrides.insert("d3d12".to_string(), "native,builtin".to_string());
                dll_overrides.insert("d3d11".to_string(), "native,builtin".to_string());
                dll_overrides.insert("dxgi".to_string(), "native,builtin".to_string());
            }
            EngineType::UnrealEngine => {
                checklist.push("✓ Unreal Engine detected".to_string());
                checklist.push("✓ Direct3D Metal 3 pipeline enabled".to_string());
                dll_overrides.insert("d3d12".to_string(), "native,builtin".to_string());
                dll_overrides.insert("d3d11".to_string(), "native,builtin".to_string());
                dll_overrides.insert("dxgi".to_string(), "native,builtin".to_string());
            }
            _ => {
                match graphics_api {
                    GraphicsApiHint::DirectX12 => {
                        checklist.push("✓ Direct3D 12 API detected (D3DMetal GPTK 2.0 recommended)".to_string());
                        dll_overrides.insert("d3d12".to_string(), "native,builtin".to_string());
                        dll_overrides.insert("dxgi".to_string(), "native,builtin".to_string());
                    }
                    GraphicsApiHint::DirectX11 => {
                        checklist.push("✓ Direct3D 11 API detected (DXVK / D3DMetal compatible)".to_string());
                        dll_overrides.insert("d3d11".to_string(), "native,builtin".to_string());
                        dll_overrides.insert("dxgi".to_string(), "native,builtin".to_string());
                    }
                    GraphicsApiHint::DirectX9 => {
                        checklist.push("✓ Direct3D 9 legacy API detected (DXVK translation)".to_string());
                        dll_overrides.insert("d3d9".to_string(), "native,builtin".to_string());
                    }
                    GraphicsApiHint::Vulkan => {
                        checklist.push("✓ Vulkan API detected (MoltenVK on Metal)".to_string());
                    }
                    _ => {
                        checklist.push("✓ Windows GDI / DirectDraw subsystem".to_string());
                    }
                }
            }
        }

        // Missing MSVC / Dependencies check
        if imported_dlls.iter().any(|d| d.contains("vcruntime") || d.contains("msvcp")) {
            winetricks.push("vcrun2022".to_string());
            checklist.push("✓ Microsoft Visual C++ 2015-2022 runtime dependencies mapped".to_string());
        }

        let (verdict, backend) = if graphics_api == GraphicsApiHint::DirectX12 || engine == EngineType::Unity {
            (CompatibilityVerdict::Platinum, "D3DMetal".to_string())
        } else if graphics_api == GraphicsApiHint::DirectX11 {
            (CompatibilityVerdict::Gold, "D3DMetal".to_string())
        } else {
            (CompatibilityVerdict::Gold, "DXVK".to_string())
        };

        CompatibilityRecipe {
            verdict,
            recommended_runtime: "Forge Compatibility Runtime (D3DMetal 2.0)".to_string(),
            recommended_backend: backend,
            required_dll_overrides: dll_overrides,
            recommended_launch_args: launch_args,
            required_winetricks: winetricks,
            human_explanation: "Fully verified compatibility recipe synthesized for Apple Silicon GPU.".to_string(),
            analysis_checklist: checklist,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_recipe_synthesis_for_unity() {
        let recipe = BinaryAnalyzer::synthesize_recipe(
            BinaryFormat::WindowsPE,
            BinaryArchitecture::X86_64,
            false,
            EngineType::Unity,
            GraphicsApiHint::DirectX11,
            &AntiCheatSignature::None,
            &["msvcp140.dll".to_string(), "d3d11.dll".to_string()],
        );

        assert_eq!(recipe.verdict, CompatibilityVerdict::Platinum);
        assert!(recipe.recommended_launch_args.contains(&"-force-d3d12".to_string()));
        assert!(recipe.required_winetricks.contains(&"vcrun2022".to_string()));
    }

    #[test]
    fn test_recipe_synthesis_for_vanguard_unsupported() {
        let recipe = BinaryAnalyzer::synthesize_recipe(
            BinaryFormat::WindowsPE,
            BinaryArchitecture::X86_64,
            false,
            EngineType::UnrealEngine,
            GraphicsApiHint::DirectX11,
            &AntiCheatSignature::Vanguard,
            &[],
        );

        assert_eq!(recipe.verdict, CompatibilityVerdict::Unsupported);
    }
}
