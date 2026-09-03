use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Standardized capability identifiers defined in ACX Specification v0.1 Section 15
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AcxCapability {
    // Platform
    Platform,
    Architecture,
    Virtualization,

    // Process
    ProcessQuery,
    ProcessMonitor,

    // Memory
    MemoryQuery,
    MemoryRead,
    MemoryIntegrity,

    // Module
    ModuleQuery,
    ModuleIntegrity,
    ModuleSignature,

    // Hardware
    CpuInfo,
    GpuInfo,
    MemoryInfo,
    DeviceInfo,

    // Security
    SecureStorage,
    CodeIntegrity,
    SecureBootState,
    Attestation,

    // Privileged / Kernel (Explicitly unsupported on native user-space macOS)
    KernelDriver,
}

impl AcxCapability {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Platform => "ACX_CAP_PLATFORM",
            Self::Architecture => "ACX_CAP_ARCHITECTURE",
            Self::Virtualization => "ACX_CAP_VIRTUALIZATION",
            Self::ProcessQuery => "ACX_CAP_PROCESS_QUERY",
            Self::ProcessMonitor => "ACX_CAP_PROCESS_MONITOR",
            Self::MemoryQuery => "ACX_CAP_MEMORY_QUERY",
            Self::MemoryRead => "ACX_CAP_MEMORY_READ",
            Self::MemoryIntegrity => "ACX_CAP_MEMORY_INTEGRITY",
            Self::ModuleQuery => "ACX_CAP_MODULE_QUERY",
            Self::ModuleIntegrity => "ACX_CAP_MODULE_INTEGRITY",
            Self::ModuleSignature => "ACX_CAP_MODULE_SIGNATURE",
            Self::CpuInfo => "ACX_CAP_CPU_INFO",
            Self::GpuInfo => "ACX_CAP_GPU_INFO",
            Self::MemoryInfo => "ACX_CAP_MEMORY_INFO",
            Self::DeviceInfo => "ACX_CAP_DEVICE_INFO",
            Self::SecureStorage => "ACX_CAP_SECURE_STORAGE",
            Self::CodeIntegrity => "ACX_CAP_CODE_INTEGRITY",
            Self::SecureBootState => "ACX_CAP_SECURE_BOOT_STATE",
            Self::Attestation => "ACX_CAP_ATTESTATION",
            Self::KernelDriver => "ACX_CAP_KERNEL_DRIVER",
        }
    }
}

/// Status of an individual capability under negotiation
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum CapabilityStatus {
    Supported,
    Limited(String),
    Unavailable,
}

/// Capability negotiation request sent by an anti-cheat client
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CapabilityNegotiationRequest {
    pub client_version: String,
    pub anti_cheat_id: String,
    pub game_id: String,
    pub requested_capabilities: Vec<AcxCapability>,
    /// If true, the client strictly requires all requested capabilities to be Supported
    pub strict_requirement: bool,
}

/// Capability negotiation response returned by ACX
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CapabilityNegotiationResponse {
    pub acx_version: String,
    pub host_platform: String,
    pub host_arch: String,
    pub translation_active: bool,
    pub capabilities: HashMap<AcxCapability, CapabilityStatus>,
    pub accepted: bool,
    pub rejection_reason: Option<String>,
}

/// Host Capability Matrix provider for Apple Silicon macOS
pub struct HostCapabilities;

impl HostCapabilities {
    pub fn current_host_matrix() -> HashMap<AcxCapability, CapabilityStatus> {
        let mut caps = HashMap::new();

        // Native ARM64 macOS platform capabilities
        caps.insert(AcxCapability::Platform, CapabilityStatus::Supported);
        caps.insert(AcxCapability::Architecture, CapabilityStatus::Supported);
        caps.insert(AcxCapability::Virtualization, CapabilityStatus::Supported);

        // Process & Module Inspection
        caps.insert(AcxCapability::ProcessQuery, CapabilityStatus::Supported);
        caps.insert(AcxCapability::ProcessMonitor, CapabilityStatus::Supported);
        caps.insert(AcxCapability::ModuleQuery, CapabilityStatus::Supported);
        caps.insert(AcxCapability::ModuleIntegrity, CapabilityStatus::Supported);
        caps.insert(
            AcxCapability::ModuleSignature,
            CapabilityStatus::Limited("Apple CodeSign and PE Authenticode validation".into()),
        );

        // Memory Inspection (Constrained to game process space)
        caps.insert(AcxCapability::MemoryQuery, CapabilityStatus::Supported);
        caps.insert(AcxCapability::MemoryRead, CapabilityStatus::Supported);
        caps.insert(AcxCapability::MemoryIntegrity, CapabilityStatus::Supported);

        // Hardware Information
        caps.insert(AcxCapability::CpuInfo, CapabilityStatus::Supported);
        caps.insert(AcxCapability::GpuInfo, CapabilityStatus::Supported);
        caps.insert(AcxCapability::MemoryInfo, CapabilityStatus::Supported);
        caps.insert(AcxCapability::DeviceInfo, CapabilityStatus::Supported);

        // Security Primitives
        caps.insert(AcxCapability::SecureStorage, CapabilityStatus::Supported);
        caps.insert(AcxCapability::CodeIntegrity, CapabilityStatus::Supported);
        caps.insert(
            AcxCapability::SecureBootState,
            CapabilityStatus::Limited("macOS SIP / Secure Enclave policy report".into()),
        );
        caps.insert(
            AcxCapability::Attestation,
            CapabilityStatus::Limited("Local measurement token; remote attestation in preview".into()),
        );

        // Privileged Windows Kernel Drivers: FAIL CLOSED (Principle 4)
        // ACX NEVER reports Supported when underlying guarantee does not exist.
        caps.insert(AcxCapability::KernelDriver, CapabilityStatus::Unavailable);

        caps
    }

    pub fn negotiate(request: &CapabilityNegotiationRequest) -> CapabilityNegotiationResponse {
        let host_caps = Self::current_host_matrix();
        let mut negotiated = HashMap::new();
        let mut missing_critical = Vec::new();

        for req in &request.requested_capabilities {
            let status = host_caps.get(req).cloned().unwrap_or(CapabilityStatus::Unavailable);
            if request.strict_requirement && status == CapabilityStatus::Unavailable {
                missing_critical.push(req.as_str());
            }
            negotiated.insert(*req, status);
        }

        let accepted = missing_critical.is_empty();
        let rejection_reason = if !accepted {
            Some(format!(
                "Required capabilities unavailable on host environment: {}",
                missing_critical.join(", ")
            ))
        } else {
            None
        };

        CapabilityNegotiationResponse {
            acx_version: "0.1.0-alpha".into(),
            host_platform: "macOS".into(),
            host_arch: "arm64".into(),
            translation_active: true, // x86_64 -> arm64 translation
            capabilities: negotiated,
            accepted,
            rejection_reason,
        }
    }
}
