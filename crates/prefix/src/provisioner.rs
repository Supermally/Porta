use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DependencyStatus {
    pub name: String,
    pub is_installed: bool,
    pub winetricks_verb: Option<String>,
    pub required_files: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProvisioningPlan {
    pub game_id: String,
    pub prefix_path: PathBuf,
    pub missing_dependencies: Vec<DependencyStatus>,
    pub recommended_commands: Vec<String>,
    pub is_ready: bool,
}

pub struct PrefixProvisioner;

impl PrefixProvisioner {
    pub fn check_dependencies<P: AsRef<Path>>(
        prefix_path: P,
        game_id: &str,
        requested_deps: &[String],
    ) -> ProvisioningPlan {
        let prefix = prefix_path.as_ref();
        let sys32 = prefix.join("drive_c/windows/system32");
        let syswow64 = prefix.join("drive_c/windows/syswow64");

        let mut statuses = Vec::new();

        for dep in requested_deps {
            let dep_lower = dep.to_lowercase();
            let (verb, files) = match dep_lower.as_str() {
                "vcrun2022" | "vcrun2019" | "vcrun2015" => (
                    Some("vcrun2022".to_string()),
                    vec!["msvcp140.dll".to_string(), "vcruntime140.dll".to_string()],
                ),
                "vcrun2013" => (
                    Some("vcrun2013".to_string()),
                    vec!["msvcp120.dll".to_string(), "vcruntime120.dll".to_string()],
                ),
                "dotnet48" | "dotnet472" | "dotnet" => (
                    Some("dotnet48".to_string()),
                    vec!["mscoree.dll".to_string(), "clr.dll".to_string()],
                ),
                "d3dcompiler_47" => (
                    Some("d3dcompiler_47".to_string()),
                    vec!["d3dcompiler_47.dll".to_string()],
                ),
                "d3dcompiler_43" => (
                    Some("d3dcompiler_43".to_string()),
                    vec!["d3dcompiler_43.dll".to_string()],
                ),
                "xact" | "xact_64" => (
                    Some("xact".to_string()),
                    vec!["xactengine3_7.dll".to_string(), "xaudio2_7.dll".to_string()],
                ),
                _ => (None, vec![dep.clone()]),
            };

            let mut all_found = !files.is_empty();
            for file in &files {
                let in_sys32 = sys32.join(file).exists();
                let in_syswow = syswow64.join(file).exists();
                if !in_sys32 && !in_syswow {
                    all_found = false;
                    break;
                }
            }

            statuses.push(DependencyStatus {
                name: dep.clone(),
                is_installed: all_found,
                winetricks_verb: verb,
                required_files: files,
            });
        }

        let missing: Vec<DependencyStatus> = statuses.into_iter().filter(|s| !s.is_installed).collect();
        let mut commands = Vec::new();

        let verbs: Vec<String> = missing
            .iter()
            .filter_map(|m| m.winetricks_verb.clone())
            .collect();

        if !verbs.is_empty() {
            commands.push(format!(
                "WINEPREFIX=\"{}\" winetricks -q {}",
                prefix.display(),
                verbs.join(" ")
            ));
        }

        let is_ready = missing.is_empty();

        ProvisioningPlan {
            game_id: game_id.to_string(),
            prefix_path: prefix.to_path_buf(),
            missing_dependencies: missing,
            recommended_commands: commands,
            is_ready,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn test_provisioner_detects_missing_vcrun() {
        let temp = tempdir().unwrap();
        let prefix = temp.path().join("prefix_test");
        std::fs::create_dir_all(prefix.join("drive_c/windows/system32")).unwrap();

        let plan = PrefixProvisioner::check_dependencies(&prefix, "game_1", &["vcrun2022".to_string()]);
        assert!(!plan.is_ready);
        assert_eq!(plan.missing_dependencies.len(), 1);
        assert_eq!(plan.recommended_commands.len(), 1);
        assert!(plan.recommended_commands[0].contains("winetricks -q vcrun2022"));

        // Simulate installing vcrun2022
        std::fs::write(prefix.join("drive_c/windows/system32/msvcp140.dll"), b"").unwrap();
        std::fs::write(prefix.join("drive_c/windows/system32/vcruntime140.dll"), b"").unwrap();

        let updated_plan = PrefixProvisioner::check_dependencies(&prefix, "game_1", &["vcrun2022".to_string()]);
        assert!(updated_plan.is_ready);
        assert!(updated_plan.missing_dependencies.is_empty());
    }
}
