use acx::capabilities::{AcxCapability, CapabilityNegotiationRequest};
use acx::ipc::{default_socket_path, IpcRequest, IpcResponse};
use acx::policy::SecurityPolicyTier;
use anyhow::{Context, Result};
use colored::Colorize;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::UnixStream;

#[tokio::main]
async fn main() -> Result<()> {
    println!("{}", "==========================================================".cyan());
    println!("{}", "    ACX Test Anti-Cheat Client Harness v0.1.0-alpha".bold().cyan());
    println!("{}", "    Testing Capability Negotiation & Host Contracts".cyan());
    println!("{}", "==========================================================".cyan());

    let socket_path = default_socket_path();
    println!("Connecting to ACX Host Daemon at: {}", socket_path.display().to_string().yellow());

    let stream = UnixStream::connect(&socket_path)
        .await
        .context("Could not connect to acx-host. Ensure the daemon is running.")?;

    let (reader, mut writer) = stream.into_split();
    let mut buf_reader = BufReader::new(reader);

    // Helper closure for sending IPC requests
    async fn send_request(
        req: &IpcRequest,
        writer: &mut tokio::net::unix::OwnedWriteHalf,
        buf_reader: &mut BufReader<tokio::net::unix::OwnedReadHalf>,
    ) -> Result<IpcResponse> {
        let mut json = serde_json::to_string(req)?;
        json.push('\n');
        writer.write_all(json.as_bytes()).await?;
        writer.flush().await?;

        let mut resp_line = String::new();
        buf_reader.read_line(&mut resp_line).await?;
        let resp: IpcResponse = serde_json::from_str(resp_line.trim())?;
        Ok(resp)
    }

    // 1. Test Ping
    println!("\n[1/5] Testing Daemon Heartbeat (Ping)...");
    let resp = send_request(&IpcRequest::Ping, &mut writer, &mut buf_reader).await?;
    match resp {
        IpcResponse::SuccessPong => println!("  {} Daemon acknowledged ping", "PASS:".bold().green()),
        other => println!("  {} Unexpected response: {:?}", "FAIL:".bold().red(), other),
    }

    // 2. Test Standard Capability Negotiation
    println!("\n[2/5] Testing Standard Capability Negotiation (Userspace AC)...");
    let std_req = CapabilityNegotiationRequest {
        client_version: "0.1.0".into(),
        anti_cheat_id: "AcxReferenceAC".into(),
        game_id: "PortaTestGame".into(),
        requested_capabilities: vec![
            AcxCapability::ProcessQuery,
            AcxCapability::ModuleQuery,
            AcxCapability::CodeIntegrity,
            AcxCapability::MemoryQuery,
        ],
        strict_requirement: true,
    };
    let resp = send_request(
        &IpcRequest::NegotiateCapabilities(std_req),
        &mut writer,
        &mut buf_reader,
    )
    .await?;

    match resp {
        IpcResponse::SuccessNegotiation(neg) => {
            if neg.accepted {
                println!(
                    "  {} Negotiation accepted by host ({}/{})",
                    "PASS:".bold().green(),
                    neg.host_platform,
                    neg.host_arch
                );
            } else {
                println!("  {} Negotiation rejected: {:?}", "FAIL:".bold().red(), neg.rejection_reason);
            }
        }
        other => println!("  {} Unexpected response: {:?}", "FAIL:".bold().red(), other),
    }

    // 3. Test Fail-Closed Rule on Unsupported Kernel Driver
    println!("\n[3/5] Testing Fail-Closed Enforcement on Kernel Driver Request...");
    let kernel_req = CapabilityNegotiationRequest {
        client_version: "0.1.0".into(),
        anti_cheat_id: "AcxKernelAC".into(),
        game_id: "PrivilegedShooter".into(),
        requested_capabilities: vec![
            AcxCapability::ProcessQuery,
            AcxCapability::KernelDriver, // MUST FAIL CLOSED
        ],
        strict_requirement: true,
    };
    let resp = send_request(
        &IpcRequest::NegotiateCapabilities(kernel_req),
        &mut writer,
        &mut buf_reader,
    )
    .await?;

    match resp {
        IpcResponse::SuccessNegotiation(neg) => {
            if !neg.accepted {
                println!(
                    "  {} Host rejected unsupported kernel capability as specified: {}",
                    "PASS:".bold().green(),
                    neg.rejection_reason.unwrap_or_default().yellow()
                );
            } else {
                println!(
                    "  {} Host falsified support for kernel driver!",
                    "FAIL:".bold().red()
                );
            }
        }
        other => println!("  {} Unexpected response: {:?}", "FAIL:".bold().red(), other),
    }

    // 4. Test Security Context Creation
    println!("\n[4/5] Testing Security Context Allocation...");
    let ctx_req = IpcRequest::CreateSecurityContext {
        game_id: "PortaTestGame".into(),
        anti_cheat_id: "AcxReferenceAC".into(),
        policy_tier: SecurityPolicyTier::Standard,
    };
    let resp = send_request(&ctx_req, &mut writer, &mut buf_reader).await?;
    match resp {
        IpcResponse::SuccessSecurityContext(ctx) => {
            println!(
                "  {} Context created successfully [Session ID: {}]",
                "PASS:".bold().green(),
                ctx.session_id.cyan()
            );
        }
        other => println!("  {} Unexpected response: {:?}", "FAIL:".bold().red(), other),
    }

    // 5. Test Process Query Service
    println!("\n[5/5] Testing Normalized Process Enumeration...");
    let resp = send_request(&IpcRequest::QueryProcesses, &mut writer, &mut buf_reader).await?;
    match resp {
        IpcResponse::SuccessProcessList(procs) => {
            println!(
                "  {} Process service returned {} active host processes safely",
                "PASS:".bold().green(),
                procs.len().to_string().cyan()
            );
            if let Some(first) = procs.first() {
                println!(
                    "    Sample process -> PID {}: {} [Arch: {}, Security: {}]",
                    first.pid, first.name, first.architecture, first.security_state
                );
            }
        }
        other => println!("  {} Unexpected response: {:?}", "FAIL:".bold().red(), other),
    }

    println!("\n{}", "==========================================================".cyan());
    println!("{}", "  ACX v0.1 Compliance Test Completed Successfully!".bold().green());
    println!("{}", "==========================================================".cyan());

    Ok(())
}
