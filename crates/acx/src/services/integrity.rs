use crate::error::{AcxError, AcxResult};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::fs::File;
use std::io::{Read, BufReader};
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IntegrityVerificationResult {
    pub target: String,
    pub algorithm: String,
    pub computed_hash: String,
    pub expected_hash: Option<String>,
    pub matches: bool,
}

pub struct IntegrityEngine;

impl IntegrityEngine {
    /// Computes the SHA-256 hash of a file on disk
    pub fn compute_sha256(path: impl AsRef<Path>) -> AcxResult<String> {
        let file = File::open(path)
            .map_err(|e| AcxError::PermissionDenied(format!("Failed to open file for integrity check: {}", e)))?;

        let mut reader = BufReader::new(file);
        let mut hasher = Sha256::new();
        let mut buffer = [0u8; 64 * 1024];

        loop {
            let bytes_read = reader
                .read(&mut buffer)
                .map_err(|e| AcxError::IntegrityFailure(format!("Read error during hash: {}", e)))?;
            if bytes_read == 0 {
                break;
            }
            hasher.update(&buffer[..bytes_read]);
        }

        let result = hasher.finalize();
        Ok(format!("{:x}", result))
    }

    /// Verifies the cryptographic integrity of an executable file against an expected hash
    pub fn verify_file_sha256(
        path: impl AsRef<Path>,
        expected_hash: &str,
    ) -> AcxResult<IntegrityVerificationResult> {
        let target_str = path.as_ref().to_string_lossy().to_string();
        let computed = Self::compute_sha256(&path)?;
        let matches = computed.eq_ignore_ascii_case(expected_hash);

        if !matches {
            return Err(AcxError::IntegrityFailure(format!(
                "Integrity mismatch for {}: expected {}, computed {}",
                target_str, expected_hash, computed
            )));
        }

        Ok(IntegrityVerificationResult {
            target: target_str,
            algorithm: "SHA-256".to_string(),
            computed_hash: computed,
            expected_hash: Some(expected_hash.to_string()),
            matches: true,
        })
    }

    /// Computes SHA-256 over an in-memory byte slice
    pub fn compute_memory_sha256(data: &[u8]) -> String {
        let mut hasher = Sha256::new();
        hasher.update(data);
        format!("{:x}", hasher.finalize())
    }
}
