use crate::capabilities::{AcxCapability, CapabilityStatus};
use crate::policy::SecurityPolicy;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditEntry {
    pub timestamp_epoch_sec: u64,
    pub event_type: String,
    pub description: String,
    pub success: bool,
}

/// An isolated security context instance (ACX Spec v0.1 Section 14)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SecurityContext {
    pub session_id: String,
    pub game_id: String,
    pub anti_cheat_id: String,
    pub policy: SecurityPolicy,
    pub granted_capabilities: HashMap<AcxCapability, CapabilityStatus>,
    pub created_at: u64,
    pub audit_log: Vec<AuditEntry>,
}

impl SecurityContext {
    pub fn new(
        game_id: impl Into<String>,
        anti_cheat_id: impl Into<String>,
        policy: SecurityPolicy,
        granted_capabilities: HashMap<AcxCapability, CapabilityStatus>,
    ) -> Self {
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        let mut ctx = Self {
            session_id: Uuid::new_v4().to_string(),
            game_id: game_id.into(),
            anti_cheat_id: anti_cheat_id.into(),
            policy,
            granted_capabilities,
            created_at: now,
            audit_log: Vec::new(),
        };

        ctx.record_event("CONTEXT_CREATED", "Security context allocated and initialized", true);
        ctx
    }

    pub fn record_event(&mut self, event_type: &str, description: &str, success: bool) {
        if self.policy.audit_logging_enabled {
            let now = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs();

            self.audit_log.push(AuditEntry {
                timestamp_epoch_sec: now,
                event_type: event_type.to_string(),
                description: description.to_string(),
                success,
            });
        }
    }

    pub fn has_capability(&self, cap: AcxCapability) -> bool {
        matches!(
            self.granted_capabilities.get(&cap),
            Some(CapabilityStatus::Supported) | Some(CapabilityStatus::Limited(_))
        )
    }
}
