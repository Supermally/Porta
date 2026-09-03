use acx::capabilities::HostCapabilities;
use acx::ipc::{default_socket_path, IpcRequest, IpcResponse};
use acx::policy::SecurityPolicy;
use acx::security_context::SecurityContext;
use acx::services::{IntegrityEngine, ModuleService, ProcessService};
use anyhow::Result;
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{UnixListener, UnixStream};
use tokio::sync::RwLock;
use tracing::{error, info, warn};

type SharedContexts = Arc<RwLock<Vec<SecurityContext>>>;

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    info!("Starting ACX Host Daemon v0.1.0-alpha (Apple Silicon ARM64)...");

    let socket_path = default_socket_path();
    if let Some(parent) = socket_path.parent() {
        let _ = tokio::fs::create_dir_all(parent).await;
    }
    if socket_path.exists() {
        let _ = tokio::fs::remove_file(&socket_path).await;
    }

    let listener = UnixListener::bind(&socket_path)?;
    info!("ACX Daemon listening on Unix socket: {}", socket_path.display());

    let contexts: SharedContexts = Arc::new(RwLock::new(Vec::new()));

    loop {
        match listener.accept().await {
            Ok((stream, _)) => {
                let contexts_clone = Arc::clone(&contexts);
                tokio::spawn(async move {
                    if let Err(e) = handle_client(stream, contexts_clone).await {
                        warn!("Client connection handler error: {}", e);
                    }
                });
            }
            Err(e) => {
                error!("Socket accept error: {}", e);
            }
        }
    }
}

async fn handle_client(stream: UnixStream, contexts: SharedContexts) -> Result<()> {
    let (reader, mut writer) = stream.into_split();
    let mut buf_reader = BufReader::new(reader);
    let mut line = String::new();

    while buf_reader.read_line(&mut line).await? > 0 {
        let req_text = line.trim();
        if req_text.is_empty() {
            line.clear();
            continue;
        }

        let response = match serde_json::from_str::<IpcRequest>(req_text) {
            Ok(request) => process_request(request, &contexts).await,
            Err(e) => IpcResponse::Error(acx::error::AcxError::IpcError(format!(
                "Malformed request payload: {}",
                e
            ))),
        };

        let mut res_json = serde_json::to_string(&response)?;
        res_json.push('\n');
        writer.write_all(res_json.as_bytes()).await?;
        writer.flush().await?;

        line.clear();
    }

    Ok(())
}

async fn process_request(req: IpcRequest, contexts: &SharedContexts) -> IpcResponse {
    match req {
        IpcRequest::Ping => IpcResponse::SuccessPong,

        IpcRequest::GetHostCapabilities => {
            IpcResponse::SuccessHostCapabilities(HostCapabilities::current_host_matrix())
        }

        IpcRequest::NegotiateCapabilities(request) => {
            let res = HostCapabilities::negotiate(&request);
            IpcResponse::SuccessNegotiation(res)
        }

        IpcRequest::CreateSecurityContext {
            game_id,
            anti_cheat_id,
            policy_tier,
        } => {
            let caps = HostCapabilities::current_host_matrix();
            let mut policy = SecurityPolicy::default();
            policy.tier = policy_tier;

            let ctx = SecurityContext::new(game_id, anti_cheat_id, policy, caps);
            let mut guard = contexts.write().await;
            guard.push(ctx.clone());
            IpcResponse::SuccessSecurityContext(ctx)
        }

        IpcRequest::QueryProcesses => match ProcessService::enumerate_processes() {
            Ok(procs) => IpcResponse::SuccessProcessList(procs),
            Err(e) => IpcResponse::Error(e),
        },

        IpcRequest::InspectModule { path } => match ModuleService::inspect_module(path) {
            Ok(meta) => IpcResponse::SuccessModuleInfo(meta),
            Err(e) => IpcResponse::Error(e),
        },

        IpcRequest::VerifyIntegrity {
            path,
            expected_hash,
        } => match IntegrityEngine::verify_file_sha256(path, &expected_hash) {
            Ok(res) => IpcResponse::SuccessIntegrity(res),
            Err(e) => IpcResponse::Error(e),
        },

        IpcRequest::GetActiveContexts => {
            let guard = contexts.read().await;
            IpcResponse::SuccessActiveContexts(guard.clone())
        }
    }
}
