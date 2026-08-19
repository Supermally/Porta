# 🍎 Mac Gaming: Technical Specification & Architectural Constitution

**Version:** 0.0.1 (Proof of Concept)  
**Status:** Frozen Working Baseline  
**Maintainers:** Mac Gaming Core Engineering Team  

---

> *"One library. One launcher. One compatibility system. Bring the games you already own."*

---

## 1. Mission Statement

**Mac Gaming** is the unified, open-source gaming platform macOS should have had. 

Mac Gaming does not attempt to replace storefronts (Steam, GOG, Epic Games, itch.io, Battle.net); it serves as the intelligent execution and compatibility bridge between the Mac user, their game libraries, Apple Silicon hardware, and Apple Metal graphics. 

Mac Gaming turns compatibility into a seamless, deterministic, one-click experience while creating transparent ecosystem data on the state of gaming on Apple Silicon.

---

## 2. Core Design Principles

### What Mac Gaming IS:
1. **One Click to Play (`[ PLAY ]`)**: The user clicks Play. The platform internally selects runtimes, provisions prefixes, maps GPU shaders to Metal 3, configures display scaling, manages companion executables, and handles macOS Game Mode.
2. **Transparent & Hardware-Aware**: Mac Gaming benchmarks and probes host hardware (`sysctl`, Unified Memory, Metal 3 feature sets) to deliver tailored target framerates and graphical profiles.
3. **Multi-Process Native**: Supports companion executables (`DoConfig.exe`, mod loaders, trainers, dedicated server daemons) running concurrently in the same isolated prefix.
4. **Self-Healing Diagnostics**: Translates cryptic Windows/DirectX crashes into human-readable recommendations with 1-click auto-fixes.
5. **Ecosystem Advocacy**: Aggregates verified user demand and hardware distribution to present actionable commercial data to game studios for native macOS ports.

### Non-Negotiable Design Principle:
> **"Mac Gaming should feel like Apple made it."**
- **Finder + Apple Music + System Settings**: Native `NavigationSplitView`, SF Symbols, system typography, and intentional Liquid Glass materials.
- **Simple by Default, Powerful When Requested**: The user must never be forced to understand Wine, prefixes, or DLL overrides. Technical complexity is hidden behind an optional Developer Mode.
- **Calm, Native Motion**: Subtle spring transitions without garish gaming-industry neon effects or fake dashboard clutter.

### What Mac Gaming IS NOT:
1. **Not a Piracy Tool or DRM Bypass**: Mac Gaming does not crack binaries or bypass ownership verification. It provides legitimate authentication paths (including in-prefix Windows Steam execution).
2. **Not a Kernel Rootkit**: Mac Gaming will never compromise macOS system integrity to emulate Windows Ring 0 kernel-level anti-cheat drivers. Unsupported kernel anti-cheat games are explicitly classified as **🔴 Unsupported** with technical justifications.
3. **Not a Generic Wine Wrapper**: Mac Gaming is a purpose-built macOS gaming operating layer with hardware-tuned runtime management.

---

## 3. System Architecture & Component Hierarchy

```text
                               ┌─────────────────────────────────────────┐
                               │             Mac Gaming.app              │
                               │        (SwiftUI / Liquid Glass)         │
                               └────────────────────┬────────────────────┘
                                                    │
                                     In-Process C-FFI Bridge
                                     (zero-overhead bindings)
                                                    │
                               ┌────────────────────▼────────────────────┐
                               │           Rust Systems Core             │
                               │          (mac-gaming-core)              │
                               └────────────────────┬────────────────────┘
                                                    │
              ┌─────────────────────────────────────┼─────────────────────────────────────┐
              │                                     │                                     │
   ┌──────────▼──────────┐               ┌──────────▼──────────┐               ┌──────────▼──────────┐
   │    GAME LIBRARY     │               │ COMPATIBILITY ENGINE│               │     ECOSYSTEM &     │
   │  (Provider Layer)   │               │   (Runtime & Metal) │               │     DATABASE        │
   ├─────────────────────┤               ├─────────────────────┤               ├─────────────────────┤
   │ • Steam VDF parser  │               │ • Wine Prefix Mgr   │               │ • Universal DB      │
   │ • GOG Galaxy DB     │               │ • D3DMetal (GPTK)   │               │ • Library Audit     │
   │ • Epic / Heroic     │               │ • DXVK / MoltenVK   │               │ • Request Mac Port  │
   │ • itch.io / Ubisoft │               │ • MSVC / .NET Heals │               │ • Native Spotlight  │
   │ • Multi-Exe Ingest  │               │ • Multi-Process Sup.│               │ • Anonymous Metrics │
   └─────────────────────┘               └─────────────────────┘               └─────────────────────┘
```

### Three-Tier Topology:
- **Presentation Layer (`apps/MacGaming`)**: macOS-native SwiftUI application following Apple Human Interface Guidelines with fluid navigation, vector SF Symbols, live HUD toggles, and zero emoji clutter.
- **Bridge Layer (`crates/bridge`)**: High-performance C-FFI / Swift Bridging Header exposing thread-safe C-ABI endpoints (`mg_engine_new`, `mg_engine_scan`, `mg_troubleshoot_logs`, `mg_run_benchmark`).
- **Core Engine (`crates/core`)**: Modular Rust workspace housing isolated domain crates:
  - `mac_gaming_core`: Database persistence, hardware probing, acquisition math, audit metrics.
  - `mac_gaming_prefix`: Sandboxed Wine prefix lifecycle, automated MSVC/DirectX provisioning.
  - `mac_gaming_scanner`: Fast zero-allocation manifest parsers for all 8 storefronts.
  - `mac_gaming_profiles`: Community tuning presets and hardware profiles.
  - `mac_gaming_analyzer`: Executable binary analysis and dependency graph parsing.

---

## 4. Current Proof-of-Concept Baseline (v0.0.1)

The frozen `v0.0.1-poc` build validates the core technology:
- ✅ **End-to-End x86-64 Execution on Apple Silicon**: Verified execution of Windows binaries via Rosetta 2 and Wine.
- ✅ **Dynamic Hardware Probing**: Real-time `sysctl` hardware discovery (Chip name, physical/logical core counts, Unified Memory size, Metal 3 validation).
- ✅ **Automated Parallel Folder Execution**: Directory ingestion automatically elects the primary game executable and runs companion utilities (`DoConfig.exe`, trainers, mod tools) concurrently inside the same prefix.
- ✅ **Self-Healing Unity / DirectX 11 / DirectX 12 Overrides**: Heuristic detection of `InitializeEngineGraphics failed` with immediate runtime overrides (`-force-d3d12`, `-force-vulkan`, `-force-d3d11`, `WINEDLLOVERRIDES`).
- ✅ **Display Scaling & Resolution Presets**: Native Fullscreen, Virtual Desktop 1080p / 720p, and Retro 4:3 integer windowed scaling.
- ✅ **Universal 8-Storefront Scanner**: Live discovery of Steam, GOG, Epic, itch.io, Ubisoft, EA, Battle.net, and local app bundles.

---

## 5. Runtime & Graphics Translation Pipeline

```text
               Windows DirectX 11 / 12 Application
                               │
               ┌───────────────┴───────────────┐
               │                               │
       DirectX 12 Pipeline             DirectX 11 Pipeline
               │                               │
        Apple D3DMetal                   DXVK / VKD3D
    (Game Porting Toolkit)                     │
               │                            MoltenVK
               │                               │
               └───────────────┬───────────────┘
                               │
                        Apple Metal 3
                               │
                    Apple Silicon GPU (M-Series)
```

1. **DirectX 12 $\to$ Metal**: Apple D3DMetal (GPTK 2.0) compiled shaders translated ahead-of-time/just-in-time into native Metal Shading Language.
2. **DirectX 11/10/9 $\to$ Vulkan $\to$ Metal**: DXVK translates Direct3D draw calls into Vulkan, which MoltenVK maps directly to Metal argument buffers and mesh shaders.
3. **Audio & Input**: DirectSound/XAudio2 mapped to macOS CoreAudio with low-latency buffers; XInput mapped to macOS `GameController.framework` (DualSense, Xbox Wireless, Nintendo Switch Pro).

---

## 6. The Four Standardized Acquisition Paths

To ensure 100% legal compliance and seamless UX, Mac Gaming standardizes game acquisition into four explicit paths:

| Path | Name | Mechanism | DRM / Auth |
| :--- | :--- | :--- | :--- |
| **Path ①** | **Native Storefront** | Official macOS Mach-O binary launched directly | Storefront Native |
| **Path ②** | **Storefront Integration** | Steam/GOG/Epic manifest & depot fetch into prefix | Official API Key / Token |
| **Path ③** | **Windows Launcher Sandbox** | Official Windows Steam/Epic client running inside sandboxed Wine prefix | Official Steam Guard / Epic 2FA Login |
| **Path ④** | **Transferred PC Folder** | Local directory or USB drive imported with auto-detected companions | Game-native files |

---

## 7. The Four-Tier Compatibility Classification System

Every game in the universal catalog and local library is classified into one of four deterministic tiers:

- 🟢 **Native macOS**: Official Mach-O binary running directly on Apple Silicon with zero translation overhead.
- 🔵 **Compatible**: Windows binary running flawlessly via D3DMetal or DXVK with verified 60+ FPS stability.
- 🟡 **Experimental**: Playable with minor community flags, graphical workarounds, or custom engine parameters.
- 🔴 **Unsupported**: Fundamentally blocked by Windows Ring 0 kernel-level anti-cheat drivers (e.g. Riot Vanguard, BattlEye kernel mode) or unsupported 16-bit DRM.

---

## 8. Security, Integrity & Privacy Model

- **Zero Telemetry Leaks**: Hardware benchmarks and demand votes are aggregated using differential privacy and anonymous identifiers.
- **Prefix Sandboxing**: Each game runs in an isolated `WINEPREFIX` (`~/Library/Application Support/MacGaming/prefixes/<game_id>`) preventing cross-contamination and unintended filesystem writes.
- **Rosetta & Gatekeeper Compliance**: All runner invocations execute strictly under macOS security boundaries without disabling System Integrity Protection (SIP).

---

## 9. Platform Roadmap

```text
v0.0.1 (Proof of Concept) ──► v0.1.0 (Engine & Runtimes) ──► v0.5.0 (Universal Steam) ──► v1.0.0 (Mac Gaming Ecosystem)
```

1. **v0.0.1 (Current)**: Frozen working proof of concept, multi-process supervisor, live diagnostics, 8-storefront scanner.
2. **v0.1.0 (Engine Core)**: Automated binary PE analyzer, dynamic runtime manager (Wine/DXVK/D3DMetal versions), self-healing winetricks pipeline.
3. **v0.5.0 (Deep Storefronts)**: Seamless Steam cloud sync, automated depot downloads, GOG Galaxy cloud saves.
4. **v1.0.0 (The Platform)**: Public "State of Mac Gaming" ecosystem report, studio developer portal, crowdsourced hardware benchmarks.

---

*Verified and sealed under Mac Gaming Architecture Standard 1.0.*
