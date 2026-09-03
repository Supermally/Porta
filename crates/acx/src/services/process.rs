use crate::error::{AcxError, AcxResult};
use serde::{Deserialize, Serialize};
use std::process::Command;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProcessInfo {
    pub pid: u32,
    pub ppid: u32,
    pub name: String,
    pub path: Option<String>,
    pub architecture: String,
    pub is_translated: bool,
    pub security_state: String,
}

pub struct ProcessService;

impl ProcessService {
    /// Enumerates processes with normalized security state
    pub fn enumerate_processes() -> AcxResult<Vec<ProcessInfo>> {
        // Use macOS `ps` command to enumerate processes safely without requiring root or kernel extensions
        let output = Command::new("ps")
            .args(["-ax", "-o", "pid,ppid,comm"])
            .output()
            .map_err(|e| AcxError::IpcError(format!("Failed to execute process enumeration: {}", e)))?;

        let stdout = String::from_utf8_lossy(&output.stdout);
        let mut list = Vec::new();

        for line in stdout.lines().skip(1) {
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() >= 3 {
                if let (Ok(pid), Ok(ppid)) = (parts[0].parse::<u32>(), parts[1].parse::<u32>()) {
                    let cmd = parts[2..].join(" ");
                    let name = std::path::Path::new(&parts[2])
                        .file_name()
                        .map(|s| s.to_string_lossy().to_string())
                        .unwrap_or_else(|| parts[2].to_string());

                    // Determine if the process is translated (e.g. Wine/Rosetta x86_64 or native ARM64)
                    let is_translated = name.ends_with(".exe") || cmd.contains("oahd") || cmd.contains("wine");
                    let architecture = if is_translated { "x86_64 (Translated)" } else { "arm64" };

                    list.push(ProcessInfo {
                        pid,
                        ppid,
                        name,
                        path: Some(cmd),
                        architecture: architecture.to_string(),
                        is_translated,
                        security_state: "SANDBOX_CONSTRAINED".to_string(),
                    });
                }
            }
        }

        Ok(list)
    }

    /// Queries specific process information by PID
    pub fn get_process_info(pid: u32) -> AcxResult<ProcessInfo> {
        let procs = Self::enumerate_processes()?;
        procs.into_iter()
            .find(|p| p.pid == pid)
            .ok_or_else(|| AcxError::CapabilityUnavailable(format!("PID {} not found or inaccessible", pid)))
    }
}
