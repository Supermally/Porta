use goblin::pe::PE;
use goblin::mach::Mach;
use serde::{Deserialize, Serialize};
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

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum AntiCheatSignature {
    EasyAntiCheat,
    BattlEye,
    Vanguard,
    Ricochet,
    PunkBuster,
    None,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BinaryAnalysisReport {
    pub file_path: PathBuf,
    pub format: BinaryFormat,
    pub architecture: BinaryArchitecture,
    pub is_native_macos: bool,
    pub graphics_api: GraphicsApiHint,
    pub anti_cheat: AntiCheatSignature,
    pub imported_dlls: Vec<String>,
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
            graphics_api = GraphicsApiHint::Metal; // Default assumption for modern Mac binaries
            match mach {
                Mach::Fat(fat) => {
                    architecture = BinaryArchitecture::Universal;
                    for arch in fat.iter_arches() {
                        if let Ok(_arch) = arch {
                            // Can contain arm64 + x86_64
                        }
                    }
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
            // Try Windows PE parsing
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

        // Anti-cheat detection from directory siblings
        let anti_cheat = Self::detect_anticheat_in_directory(path.parent());

        Ok(BinaryAnalysisReport {
            file_path: path.to_path_buf(),
            format,
            architecture,
            is_native_macos,
            graphics_api,
            anti_cheat,
            imported_dlls,
        })
    }

    fn detect_anticheat_in_directory(dir_opt: Option<&Path>) -> AntiCheatSignature {
        let Some(dir) = dir_opt else {
            return AntiCheatSignature::None;
        };

        if !dir.exists() {
            return AntiCheatSignature::None;
        }

        // Search directory shallowly for known AC files
        for entry in walkdir::WalkDir::new(dir).max_depth(2).into_iter().flatten() {
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
        }

        AntiCheatSignature::None
    }
}
