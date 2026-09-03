# ACX Specification v0.1

**Anti-Cheat Compatibility eXecution Layer**

**Status:** Draft  
**Version:** 0.1  
**Date:** September 3, 2026  
**Primary Target:** Apple Silicon Macs running macOS  
**Architecture:** ARM64  
**Primary Compatibility Target:** Windows x86-64 games  
**Project Type:** Open compatibility/security runtime  

---

## 0. Executive Summary

**ACX** is a compatibility runtime intended to allow Windows games and their security components to operate within alternative operating-system and CPU environments without circumventing, disabling, or concealing anti-cheat mechanisms.

The initial implementation targets:

> **Windows x86-64 games → Apple Silicon ARM64 → macOS**

ACX does not attempt to emulate an entire Windows computer. Instead, ACX provides a set of standardized compatibility and security interfaces that translate required Windows security capabilities into mechanisms available on the host platform.

The fundamental design principle is:

> **Translate the security contract, rather than bypass the security system.**

ACX treats anti-cheat as a first-class component of the compatibility environment rather than as an obstacle to be defeated.

---

## 1. Problem Statement

Modern Windows games increasingly depend upon anti-cheat systems that operate beyond ordinary userspace, including process monitoring, executable/module integrity verification, memory inspection, privileged services, kernel drivers, hardware/platform information, secure communication, and virtualization/security primitives.

Traditional compatibility layers concentrate solely on application APIs:
```text
Windows Application → Windows API → Compatibility Layer → Host OS
```

Security software introduces another layer:
```text
Windows Game ──┬── Windows APIs
               └── Anti-Cheat ──┬── Userspace
                                ├── Services
                                └── Privileged components
```
Consequently, a game may function correctly while its anti-cheat refuses to initialize. ACX bridges this gap.

---

## 2. Goals & Non-Goals

### 2.1 Primary Goal
Create a compatibility environment capable of hosting Windows game security software on Apple Silicon Macs **when the relevant security capabilities can be legitimately provided and the software/vendor permits such operation**.

### 2.2 Non-Goals
ACX **will not**:
- disable anti-cheat
- patch anti-cheat binaries
- hide Wine/ACX from anti-cheat software
- spoof security properties
- circumvent anti-cheat integrity checks
- bypass game authentication
- manipulate game memory
- defeat kernel protections
- provide cheating functionality
- impersonate unsupported hardware
- falsify security attestations

> **Rule:** If an anti-cheat determines that ACX does not satisfy its security requirements, **ACX must allow the anti-cheat to reject the environment.**

---

## 3. Core Design Principles

1. **Transparency**: The environment is identifiable as `ACX` rather than pretending to be native Windows.
2. **Capability-based security**: Applications request granular capabilities rather than receiving unrestricted host access.
3. **Least privilege**: Security components receive only the minimal capabilities authorized for their role.
4. **Fail closed**: If a security capability cannot be provided with sufficient confidence, `CAPABILITY_UNAVAILABLE` must be returned. ACX never reports `SUPPORTED` when a guarantee does not exist.

---

## 4. Architecture & Subsystems

```text
┌───────────────────────────────────────────┐
│               WINDOWS GAME                │
│  Game Client       Anti-Cheat Client      │
└─────────────────┬─────────────────────────┘
                  │
                  ▼
┌───────────────────────────────────────────┐
│          WINDOWS COMPATIBILITY             │
│ Wine / Windows API Compatibility (Forge)  │
│ x86-64 → ARM64 translation (Rosetta)      │
└─────────────────┬─────────────────────────┘
                  │
                  ▼
┌───────────────────────────────────────────┐
│                    ACX                     │
│ ┌───────────────┐  ┌────────────────────┐ │
│ │ ACX Runtime   │  │ ACX Security Core  │ │
│ └───────────────┘  └────────────────────┘ │
│ ┌───────────────┐  ┌────────────────────┐ │
│ │ ACX HAL       │  │ ACX Integrity      │ │
│ └───────────────┘  └────────────────────┘ │
└─────────────────┬─────────────────────────┘
                  │
                  ▼
┌───────────────────────────────────────────┐
│              macOS SECURITY               │
│ Endpoint / Process / Code / System APIs   │
└─────────────────┬─────────────────────────┘
                  │
                  ▼
┌───────────────────────────────────────────┐
│              APPLE SILICON                │
│ CPU │ GPU │ Memory │ Devices │ Secure Encl│
└───────────────────────────────────────────┘
```

### Components
1. **ACX Runtime**: Lifecycle, process registration, context allocation, IPC routing.
2. **ACX Security Core**: Process, thread, memory, and module services.
3. **ACX Integrity Engine**: Cryptographic verification (SHA-256/384/512) for binaries and memory.
4. **Capability System & Policy Engine**: Explicit capability negotiation (`ACX_CAP_*`) with strict tiers (`STRICT`, `STANDARD`, `COMPATIBILITY`, `UNTRUSTED`).
5. **Host Daemon (`acx-host`)**: Native ARM64 macOS background daemon serving IPC requests.
6. **Test Client (`acx-test-client`)**: Automated reference client exercising the capability negotiation protocol.
