use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum AcxError {
    #[error("Capability unavailable: {0}")]
    CapabilityUnavailable(String),

    #[error("Permission denied: {0}")]
    PermissionDenied(String),

    #[error("Integrity check failed: {0}")]
    IntegrityFailure(String),

    #[error("Platform unsupported: {0}")]
    PlatformUnsupported(String),

    #[error("Translation layer failure: {0}")]
    TranslationFailure(String),

    #[error("Security policy violation: {0}")]
    SecurityPolicy(String),

    #[error("Vendor rejected compatibility environment: {0}")]
    VendorRejected(String),

    #[error("General unsupported operation: {0}")]
    Unsupported(String),

    #[error("IPC communication error: {0}")]
    IpcError(String),
}

pub type AcxResult<T> = Result<T, AcxError>;
