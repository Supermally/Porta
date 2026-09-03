use serde::{Deserialize, Serialize};

/// Security Policy tiers defined in ACX Specification v0.1 Section 22
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum SecurityPolicyTier {
    /// STRICT: Only capabilities with strong hardware/host OS guarantees are reported
    Strict,
    /// STANDARD: Normal supported compatibility environment with full transparent reporting
    Standard,
    /// COMPATIBILITY: Relaxed guarantees for legacy titles with explicit disclosure
    Compatibility,
    /// UNTRUSTED: Development, fuzzing, and diagnostic mode; disabled for competitive play
    Untrusted,
}

impl Default for SecurityPolicyTier {
    fn default() -> Self {
        Self::Standard
    }
}

/// Security Policy configuration governing access and capability enforcement
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SecurityPolicy {
    pub tier: SecurityPolicyTier,
    pub enforce_code_integrity: bool,
    pub allow_memory_inspection: bool,
    pub allow_debugger_attachment: bool,
    pub audit_logging_enabled: bool,
}

impl Default for SecurityPolicy {
    fn default() -> Self {
        Self {
            tier: SecurityPolicyTier::Standard,
            enforce_code_integrity: true,
            allow_memory_inspection: true,
            allow_debugger_attachment: false,
            audit_logging_enabled: true,
        }
    }
}

impl SecurityPolicy {
    pub fn strict() -> Self {
        Self {
            tier: SecurityPolicyTier::Strict,
            enforce_code_integrity: true,
            allow_memory_inspection: true,
            allow_debugger_attachment: false,
            audit_logging_enabled: true,
        }
    }

    pub fn untrusted() -> Self {
        Self {
            tier: SecurityPolicyTier::Untrusted,
            enforce_code_integrity: false,
            allow_memory_inspection: true,
            allow_debugger_attachment: true,
            audit_logging_enabled: true,
        }
    }
}
