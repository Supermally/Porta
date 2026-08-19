use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AcquisitionPath {
    /// Path ①: Official Native macOS Storefront Build (Zero translation overhead)
    NativeStorefront,
    /// Path ②: Direct Storefront Depot / Manifest Integration
    StorefrontIntegration,
    /// Path ③: Windows Launcher Runtime in Sandboxed Prefix (Official Steam/Epic client inside Wine)
    WindowsLauncherRuntime,
    /// Path ④: Existing PC Installation / Transferred Folder / External Drive
    ExistingFiles,
}

impl AcquisitionPath {
    pub fn display_name(&self) -> &'static str {
        match self {
            Self::NativeStorefront => "Native Mac Storefront",
            Self::StorefrontIntegration => "Storefront Integration",
            Self::WindowsLauncherRuntime => "Windows Steam / Launcher Container",
            Self::ExistingFiles => "Transferred PC Folder / External Drive",
        }
    }

    pub fn icon_name(&self) -> &'static str {
        match self {
            Self::NativeStorefront => "applelogo",
            Self::StorefrontIntegration => "arrow.down.circle.fill",
            Self::WindowsLauncherRuntime => "shippingbox.fill",
            Self::ExistingFiles => "folder.badge.gearshape",
        }
    }

    pub fn description(&self) -> &'static str {
        match self {
            Self::NativeStorefront => "Runs directly as a native macOS Mach-O executable with optimal Metal performance.",
            Self::StorefrontIntegration => "Acquired via official storefront APIs with sandboxed prefix creation.",
            Self::WindowsLauncherRuntime => "Runs inside a sandboxed Windows Steam environment for official DRM & cloud saves.",
            Self::ExistingFiles => "Imported from an existing PC directory with auto-detected companion executables.",
        }
    }
}

pub struct WindowsLauncherManager {
    base_launchers_dir: PathBuf,
}

impl WindowsLauncherManager {
    pub fn new() -> Self {
        let base = dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Library/Application Support/MacGaming/launchers");
        Self {
            base_launchers_dir: base,
        }
    }

    pub fn get_steam_launcher_dir(&self) -> PathBuf {
        self.base_launchers_dir.join("steam")
    }

    pub fn get_epic_launcher_dir(&self) -> PathBuf {
        self.base_launchers_dir.join("epic")
    }

    pub fn get_steam_exe_path(&self) -> PathBuf {
        self.get_steam_launcher_dir()
            .join("drive_c/Program Files (x86)/Steam/Steam.exe")
    }

    pub fn is_windows_steam_installed(&self) -> bool {
        self.get_steam_exe_path().exists()
    }

    pub fn prepare_steam_launcher_prefix<P: AsRef<Path>>(&self, prefix_dir: P) -> std::io::Result<()> {
        let p = prefix_dir.as_ref();
        std::fs::create_dir_all(p.join("drive_c/Program Files (x86)/Steam"))?;
        std::fs::create_dir_all(p.join("drive_c/windows/system32"))?;
        Ok(())
    }

    pub fn generate_steam_app_launch_args(app_id: &str) -> Vec<String> {
        vec![
            "-applaunch".to_string(),
            app_id.to_string(),
            "-silent".to_string(),
        ]
    }
}

impl Default for WindowsLauncherManager {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_acquisition_path_metadata() {
        let p1 = AcquisitionPath::NativeStorefront;
        assert_eq!(p1.display_name(), "Native Mac Storefront");
        assert_eq!(p1.icon_name(), "applelogo");

        let p3 = AcquisitionPath::WindowsLauncherRuntime;
        assert_eq!(p3.display_name(), "Windows Steam / Launcher Container");
        assert_eq!(p3.icon_name(), "shippingbox.fill");
    }

    #[test]
    fn test_steam_app_launch_args() {
        let args = WindowsLauncherManager::generate_steam_app_launch_args("1086940");
        assert_eq!(args, vec!["-applaunch", "1086940", "-silent"]);
    }
}
