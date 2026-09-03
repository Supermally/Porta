//! ACX: Anti-Cheat Compatibility eXecution Layer Core Library
//!
//! Provides capability negotiation, security contexts, process/module inspection,
//! cryptographic integrity verification, and IPC communication for Windows security components
//! operating on Apple Silicon macOS.

pub mod capabilities;
pub mod error;
pub mod ipc;
pub mod policy;
pub mod security_context;
pub mod services;

pub use capabilities::{
    AcxCapability, CapabilityNegotiationRequest, CapabilityNegotiationResponse,
    CapabilityStatus, HostCapabilities,
};
pub use error::{AcxError, AcxResult};
pub use ipc::{default_socket_path, IpcRequest, IpcResponse};
pub use policy::{SecurityPolicy, SecurityPolicyTier};
pub use security_context::{AuditEntry, SecurityContext};
pub use services::{
    IntegrityEngine, IntegrityVerificationResult, ModuleMetadata, ModuleService, ProcessInfo,
    ProcessService,
};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_host_capabilities_matrix() {
        let matrix = HostCapabilities::current_host_matrix();
        assert_eq!(matrix.get(&AcxCapability::Platform), Some(&CapabilityStatus::Supported));
        assert_eq!(matrix.get(&AcxCapability::Architecture), Some(&CapabilityStatus::Supported));
        assert_eq!(matrix.get(&AcxCapability::ProcessQuery), Some(&CapabilityStatus::Supported));
        assert_eq!(matrix.get(&AcxCapability::CodeIntegrity), Some(&CapabilityStatus::Supported));

        // CRITICAL FAIL-CLOSED TEST: Kernel driver MUST be unavailable
        assert_eq!(matrix.get(&AcxCapability::KernelDriver), Some(&CapabilityStatus::Unavailable));
    }

    #[test]
    fn test_capability_negotiation_fail_closed() {
        // Request an unsupported kernel capability strictly
        let request = CapabilityNegotiationRequest {
            client_version: "1.0.0".into(),
            anti_cheat_id: "TestAC".into(),
            game_id: "CompetitiveShooter".into(),
            requested_capabilities: vec![
                AcxCapability::ProcessQuery,
                AcxCapability::CodeIntegrity,
                AcxCapability::KernelDriver, // Requires kernel driver
            ],
            strict_requirement: true,
        };

        let response = HostCapabilities::negotiate(&request);
        // Must be rejected under strict requirements because KernelDriver is unavailable
        assert!(!response.accepted);
        assert!(response.rejection_reason.is_some());
        let reason = response.rejection_reason.unwrap();
        assert!(reason.contains("ACX_CAP_KERNEL_DRIVER"));
    }

    #[test]
    fn test_capability_negotiation_standard_accepted() {
        // Request legitimate user-space monitoring capabilities
        let request = CapabilityNegotiationRequest {
            client_version: "1.0.0".into(),
            anti_cheat_id: "TestAC".into(),
            game_id: "AdventureGame".into(),
            requested_capabilities: vec![
                AcxCapability::ProcessQuery,
                AcxCapability::ModuleQuery,
                AcxCapability::CodeIntegrity,
                AcxCapability::MemoryQuery,
            ],
            strict_requirement: true,
        };

        let response = HostCapabilities::negotiate(&request);
        assert!(response.accepted);
        assert!(response.rejection_reason.is_none());
        assert_eq!(response.host_platform, "macOS");
        assert_eq!(response.host_arch, "arm64");
    }

    #[test]
    fn test_security_context_and_audit_trail() {
        let mut caps = std::collections::HashMap::new();
        caps.insert(AcxCapability::ProcessQuery, CapabilityStatus::Supported);

        let mut ctx = SecurityContext::new("Game123", "AcVendor456", SecurityPolicy::default(), caps);
        assert_eq!(ctx.game_id, "Game123");
        assert_eq!(ctx.anti_cheat_id, "AcVendor456");
        assert!(ctx.has_capability(AcxCapability::ProcessQuery));
        assert!(!ctx.has_capability(AcxCapability::KernelDriver));

        ctx.record_event("MODULE_VERIFIED", "Game binary SHA-256 verified", true);
        assert_eq!(ctx.audit_log.len(), 2); // Initial creation + record_event
    }

    #[test]
    fn test_integrity_engine_memory_hash() {
        let sample_data = b"ACX_INTEGRITY_TEST_DATA";
        let hash = IntegrityEngine::compute_memory_sha256(sample_data);
        assert!(!hash.is_empty());
        assert_eq!(hash.len(), 64); // SHA-256 hex string length
    }
}
