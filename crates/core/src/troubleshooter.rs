use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum DiagnosticSeverity {
    Critical,
    Warning,
    Info,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CrashCategory {
    MissingMsvcRuntime,
    MissingDotNetRuntime,
    DirectXTranslationMismatch,
    AntiCheatDriverBlock,
    MissingDirectXComponent,
    MemoryOrRosettaLimit,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DiagnosticFinding {
    pub category: CrashCategory,
    pub severity: DiagnosticSeverity,
    pub title: String,
    pub description: String,
    pub log_snippet: Option<String>,
    pub recommended_action: String,
    pub auto_fix_command: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DiagnosticReport {
    pub findings: Vec<DiagnosticFinding>,
    pub has_critical_issues: bool,
    pub summary: String,
}

pub struct Troubleshooter;

impl Troubleshooter {
    pub fn analyze_logs(log_text: &str) -> DiagnosticReport {
        let mut findings = Vec::new();
        let lower = log_text.to_lowercase();

        // 1. Missing MSVC Runtime (VCRUNTIME140, MSVCP140, api-ms-win-crt-*)
        if lower.contains("msvcp140.dll")
            || lower.contains("vcruntime140.dll")
            || lower.contains("vcruntime140_1.dll")
            || lower.contains("msvcp120.dll")
            || lower.contains("api-ms-win-crt-runtime-l1-1-0.dll")
            || lower.contains("err:module:import_dll library msvcp")
        {
            findings.push(DiagnosticFinding {
                category: CrashCategory::MissingMsvcRuntime,
                severity: DiagnosticSeverity::Critical,
                title: "Missing Microsoft Visual C++ Runtime".to_string(),
                description: "The game requires Microsoft Visual C++ 2015-2022 redistributable DLLs that are absent in the prefix."
                    .to_string(),
                log_snippet: Self::extract_relevant_line(log_text, &["msvcp", "vcruntime", "api-ms-win-crt"]),
                recommended_action: "Install Microsoft Visual C++ 2015-2022 runtime dependencies into the game prefix."
                    .to_string(),
                auto_fix_command: Some("winetricks -q vcrun2022".to_string()),
            });
        }

        // 2. Missing .NET Runtime (mscoree.dll, clr.dll)
        if lower.contains("mscoree.dll")
            || lower.contains("clr.dll")
            || lower.contains(".net framework")
            || lower.contains("0x80131500")
        {
            findings.push(DiagnosticFinding {
                category: CrashCategory::MissingDotNetRuntime,
                severity: DiagnosticSeverity::Critical,
                title: "Missing .NET Framework Runtime".to_string(),
                description: "The game executable requires the .NET Framework 4.8 runtime environment."
                    .to_string(),
                log_snippet: Self::extract_relevant_line(log_text, &["mscoree", "clr.dll", ".net"]),
                recommended_action: "Install Microsoft .NET Framework 4.8 via winetricks into the game prefix."
                    .to_string(),
                auto_fix_command: Some("winetricks -q dotnet48".to_string()),
            });
        }

        // 3. DirectX Translation Mismatch / Device Creation Failure / InitializeEngineGraphics Failed
        if lower.contains("d3d12createdevice failed")
            || lower.contains("dxgi_error_device_removed")
            || lower.contains("vk_error_device_lost")
            || lower.contains("vkcreateinstance failed")
            || lower.contains("dxvk: failed to create metal device")
            || lower.contains("failed to initialize graphics")
            || lower.contains("initializeenginegraphics failed")
        {
            findings.push(DiagnosticFinding {
                category: CrashCategory::DirectXTranslationMismatch,
                severity: DiagnosticSeverity::Critical,
                title: "DirectX 11 Graphics Initialization Failed".to_string(),
                description: "The game engine failed to initialize DirectX 11. On Apple Silicon, standard Wine OpenGL fallback fails because macOS lacks OpenGL 4.3+ compute shader support. Switching to DXVK (Vulkan on Metal) or setting D3D11 DLL overrides resolves this."
                    .to_string(),
                log_snippet: Self::extract_relevant_line(log_text, &["initializeenginegraphics", "failed to initialize graphics", "d3d12", "device_removed", "metal device"]),
                recommended_action: "Toggle 'DXVK (Vulkan)' in Translation Controls or force DirectX 12 mode with Apple D3DMetal."
                    .to_string(),
                auto_fix_command: Some("forge config --dxvk=true --override-d3d11=native".to_string()),
            });
        }

        // 4. Missing DirectX Components (d3dcompiler, xaudio, xinput)
        if lower.contains("d3dcompiler_47.dll")
            || lower.contains("d3dcompiler_43.dll")
            || lower.contains("xinput1_3.dll")
            || lower.contains("xact")
        {
            findings.push(DiagnosticFinding {
                category: CrashCategory::MissingDirectXComponent,
                severity: DiagnosticSeverity::Warning,
                title: "Missing DirectX Shaders / Audio Runtime".to_string(),
                description: "The application requires standalone DirectX helper libraries (d3dcompiler / xinput)."
                    .to_string(),
                log_snippet: Self::extract_relevant_line(log_text, &["d3dcompiler", "xinput", "xact"]),
                recommended_action: "Install DirectX shader compiler and audio runtimes into the prefix."
                    .to_string(),
                auto_fix_command: Some("winetricks -q d3dcompiler_47 xact".to_string()),
            });
        }

        // 5. Anti-Cheat Driver Block
        if lower.contains("easyanticheat")
            || lower.contains("easy anti-cheat")
            || lower.contains("bedaisy.sys")
            || lower.contains("battleye")
            || lower.contains("vgc.sys")
            || lower.contains("vgk.sys")
        {
            findings.push(DiagnosticFinding {
                category: CrashCategory::AntiCheatDriverBlock,
                severity: DiagnosticSeverity::Critical,
                title: "Kernel-Level Anti-Cheat Incompatibility".to_string(),
                description: "This game utilizes a Windows kernel-mode driver anti-cheat which cannot execute within Wine/macOS sandboxes."
                    .to_string(),
                log_snippet: Self::extract_relevant_line(log_text, &["easyanticheat", "battleye", "bedaisy", "vgc"]),
                recommended_action: "Launch with single-player / offline flags (e.g. -eac_launcher=0) or check the Forge Community DB."
                    .to_string(),
                auto_fix_command: None,
            });
        }

        // 6. Memory or Rosetta limits
        if lower.contains("out of virtual memory") || lower.contains("bad memory access in rosetta") {
            findings.push(DiagnosticFinding {
                category: CrashCategory::MemoryOrRosettaLimit,
                severity: DiagnosticSeverity::Warning,
                title: "Memory / Rosetta 2 Resource Constraint".to_string(),
                description: "The game ran out of address space or triggered a memory fault in the Rosetta x86 translation engine."
                    .to_string(),
                log_snippet: Self::extract_relevant_line(log_text, &["virtual memory", "rosetta"]),
                recommended_action: "Ensure macOS and Rosetta 2 are updated to the latest version and verify Unified Memory allocation."
                    .to_string(),
                auto_fix_command: Some("/usr/sbin/softwareupdate --install-rosetta --agree-to-license".to_string()),
            });
        }

        let has_critical_issues = findings
            .iter()
            .any(|f| f.severity == DiagnosticSeverity::Critical);

        let summary = if findings.is_empty() {
            "No known runtime crash signatures detected in the provided log output.".to_string()
        } else {
            format!(
                "Detected {} issue(s) ({}) during execution analysis.",
                findings.len(),
                if has_critical_issues { "Action Required" } else { "Advisories" }
            )
        };

        DiagnosticReport {
            findings,
            has_critical_issues,
            summary,
        }
    }

    fn extract_relevant_line(log_text: &str, keywords: &[&str]) -> Option<String> {
        for line in log_text.lines() {
            let lower_line = line.to_lowercase();
            for kw in keywords {
                if lower_line.contains(kw) {
                    return Some(line.trim().to_string());
                }
            }
        }
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_troubleshooter_msvc_detection() {
        let sample_log = r#"
        0024:err:module:import_dll Library MSVCP140.dll (which is needed by L"C:\\Games\\Game.exe") not found
        0024:err:module:LdrInitializeThunk Importing dlls for L"C:\\Games\\Game.exe" failed, status c0000135
        "#;

        let report = Troubleshooter::analyze_logs(sample_log);
        assert!(report.has_critical_issues);
        assert_eq!(report.findings.len(), 1);
        assert_eq!(report.findings[0].category, CrashCategory::MissingMsvcRuntime);
        assert_eq!(
            report.findings[0].auto_fix_command.as_deref(),
            Some("winetricks -q vcrun2022")
        );
    }

    #[test]
    fn test_troubleshooter_anticheat_detection() {
        let sample_log = r#"
        0030:err:service:service_start EasyAntiCheat service driver could not load
        0030:fixme:kernelbase:AppPolicyGetProcessTerminationMethod
        "#;

        let report = Troubleshooter::analyze_logs(sample_log);
        assert!(report.has_critical_issues);
        assert_eq!(report.findings[0].category, CrashCategory::AntiCheatDriverBlock);
    }
}
