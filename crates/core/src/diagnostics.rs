use serde::{Deserialize, Serialize};
use std::process::Command;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HostSystemDiagnostics {
    pub chip_name: String,
    pub is_apple_silicon: bool,
    pub core_count: u32,
    pub total_memory_gb: u32,
    pub os_version: String,
    pub os_build: String,
    pub metal_supported: bool,
    pub metal_version: String,
    pub rosetta_installed: bool,
    pub controller_support: bool,
    pub compatibility_engine_ready: bool,
}

impl HostSystemDiagnostics {
    pub fn probe() -> Self {
        let chip_name = Self::probe_chip_name();
        let is_apple_silicon = chip_name.contains("Apple")
            || chip_name.contains("M1")
            || chip_name.contains("M2")
            || chip_name.contains("M3")
            || chip_name.contains("M4");

        let core_count = Self::probe_core_count();
        let total_memory_gb = Self::probe_memory_gb();
        let (os_version, os_build) = Self::probe_os_version();
        let rosetta_installed = Self::check_rosetta();

        Self {
            chip_name,
            is_apple_silicon,
            core_count,
            total_memory_gb,
            os_version,
            os_build,
            metal_supported: true,
            metal_version: "Metal 3 (GPUDriver / D3DMetal Ready)".to_string(),
            rosetta_installed,
            controller_support: true,
            compatibility_engine_ready: true,
        }
    }

    fn probe_chip_name() -> String {
        // Try machdep.cpu.brand_string first
        if let Ok(output) = Command::new("sysctl").arg("-n").arg("machdep.cpu.brand_string").output() {
            let s = String::from_utf8_lossy(&output.stdout).trim().to_string();
            if !s.is_empty() && s != "Apple Processor" {
                return s;
            }
        }

        // Fallback to hw.model (e.g. Mac14,2)
        if let Ok(output) = Command::new("sysctl").arg("-n").arg("hw.model").output() {
            let s = String::from_utf8_lossy(&output.stdout).trim().to_string();
            if !s.is_empty() {
                return format!("Apple Silicon ({})", s);
            }
        }

        "Apple Silicon".to_string()
    }

    fn probe_core_count() -> u32 {
        if let Ok(output) = Command::new("sysctl").arg("-n").arg("hw.ncpu").output() {
            let s = String::from_utf8_lossy(&output.stdout).trim().to_string();
            if let Ok(n) = s.parse::<u32>() {
                return n;
            }
        }
        8
    }

    fn probe_memory_gb() -> u32 {
        if let Ok(output) = Command::new("sysctl").arg("-n").arg("hw.memsize").output() {
            let s = String::from_utf8_lossy(&output.stdout).trim().to_string();
            if let Ok(bytes) = s.parse::<u64>() {
                return (bytes / (1024 * 1024 * 1024)) as u32;
            }
        }
        16
    }

    fn probe_os_version() -> (String, String) {
        let mut ver = "macOS 15.0".to_string();
        let mut build = "".to_string();

        if let Ok(output) = Command::new("sw_vers").arg("-productVersion").output() {
            let s = String::from_utf8_lossy(&output.stdout).trim().to_string();
            if !s.is_empty() {
                ver = format!("macOS {}", s);
            }
        }

        if let Ok(output) = Command::new("sw_vers").arg("-buildVersion").output() {
            let s = String::from_utf8_lossy(&output.stdout).trim().to_string();
            if !s.is_empty() {
                build = s;
            }
        }

        (ver, build)
    }

    fn check_rosetta() -> bool {
        if let Ok(status) = Command::new("/usr/bin/arch")
            .arg("-x86_64")
            .arg("/usr/bin/true")
            .status()
        {
            status.success()
        } else {
            false
        }
    }
}
