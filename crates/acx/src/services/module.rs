use crate::error::{AcxError, AcxResult};
use serde::{Deserialize, Serialize};
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleMetadata {
    pub name: String,
    pub path: String,
    pub architecture: String,
    pub is_translated: bool,
    pub origin: String,
    pub file_size_bytes: u64,
    pub load_status: String,
}

pub struct ModuleService;

impl ModuleService {
    /// Inspects an executable module on disk and classifies its architecture and origin
    pub fn inspect_module(file_path: impl AsRef<Path>) -> AcxResult<ModuleMetadata> {
        let path = file_path.as_ref();
        if !path.exists() {
            return Err(AcxError::CapabilityUnavailable(format!(
                "Module does not exist at path: {}",
                path.display()
            )));
        }

        let metadata = std::fs::metadata(path)
            .map_err(|e| AcxError::PermissionDenied(format!("Failed to read module metadata: {}", e)))?;

        let name = path
            .file_name()
            .map(|n| n.to_string_lossy().to_string())
            .unwrap_or_else(|| "unknown_module".to_string());

        // Read binary magic bytes to detect PE vs Mach-O
        let mut buffer = [0u8; 4];
        let (architecture, is_translated, origin) = if let Ok(mut file) = std::fs::File::open(path) {
            use std::io::Read;
            if file.read_exact(&mut buffer).is_ok() {
                if buffer[0] == b'M' && buffer[1] == b'Z' {
                    ("x86_64 (Windows PE)".to_string(), true, "Wine / Forge Prefix".to_string())
                } else if buffer == [0xcf, 0xfa, 0xed, 0xfe] || buffer == [0xfe, 0xed, 0xfa, 0xcf] {
                    ("arm64 (macOS Mach-O 64)".to_string(), false, "Native macOS".to_string())
                } else {
                    ("Universal / Static Asset".to_string(), false, "Host Filesystem".to_string())
                }
            } else {
                ("Unknown Architecture".to_string(), false, "Unknown".to_string())
            }
        } else {
            ("Inaccessible".to_string(), false, "Unknown".to_string())
        };

        Ok(ModuleMetadata {
            name,
            path: path.to_string_lossy().to_string(),
            architecture,
            is_translated,
            origin,
            file_size_bytes: metadata.len(),
            load_status: "VERIFIED_ON_DISK".to_string(),
        })
    }
}
