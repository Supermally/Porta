use crate::capabilities::{AcxCapability, CapabilityNegotiationRequest, CapabilityNegotiationResponse, CapabilityStatus};
use crate::error::AcxError;
use crate::policy::SecurityPolicyTier;
use crate::security_context::SecurityContext;
use crate::services::{IntegrityVerificationResult, ModuleMetadata, ProcessInfo};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;

pub fn default_socket_path() -> PathBuf {
    if let Some(home) = dirs::home_dir() {
        home.join(".porta").join("acx.sock")
    } else {
        PathBuf::from("/tmp/acx.sock")
    }
}

/// Standardized IPC request payload (ACX Spec v0.1 Section 43)
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "action", content = "payload")]
pub enum IpcRequest {
    Ping,
    GetHostCapabilities,
    NegotiateCapabilities(CapabilityNegotiationRequest),
    CreateSecurityContext {
        game_id: String,
        anti_cheat_id: String,
        policy_tier: SecurityPolicyTier,
    },
    QueryProcesses,
    InspectModule {
        path: String,
    },
    VerifyIntegrity {
        path: String,
        expected_hash: String,
    },
    GetActiveContexts,
}

/// Standardized IPC response payload
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "status", content = "payload")]
pub enum IpcResponse {
    SuccessPong,
    SuccessHostCapabilities(HashMap<AcxCapability, CapabilityStatus>),
    SuccessNegotiation(CapabilityNegotiationResponse),
    SuccessSecurityContext(SecurityContext),
    SuccessProcessList(Vec<ProcessInfo>),
    SuccessModuleInfo(ModuleMetadata),
    SuccessIntegrity(IntegrityVerificationResult),
    SuccessActiveContexts(Vec<SecurityContext>),
    Error(AcxError),
}
