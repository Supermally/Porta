# Porta • Powered by Forge Engine

**Porta** is a modern, high-performance compatibility environment and gaming launcher for macOS on Apple Silicon. Powered by the **Forge Engine** backend, Porta seamlessly executes Windows applications and games utilizing Apple D3DMetal (DirectX 11/12 to Metal), DXVK (Vulkan to Metal via MoltenVK), and a low-latency user-space synchronization subsystem.

---

## Key Features

- **Forge Compatibility Engine**: High-performance translation layer with unified WoW64 and ARM64 Mach-O execution.
- **DirectX 11/12 & Vulkan on Metal**: Native hardware acceleration utilizing Apple D3DMetal and MoltenVK.
- **Native Apple Liquid Glass UI**: Clean macOS SwiftUI interface featuring optical glass surfaces, responsive layouts, and native HIG controls.
- **Isolated Prefix & Multi-Environment Management**: Granular sandbox separation per application with automatic DXVK/D3DMetal DLL overrides.
- **Automatic Runtime Provisioning**: On-demand download and setup of translation runtimes with cryptographic **SHA-256 package verification**.
- **Cross-Storefront Library Indexing**: Seamless discovery and import for Steam, GOG, Epic Games, itch.io, and standalone Windows executables (`.exe`).
- **macOS Game Mode & ProMotion Optimization**: Low-latency controller polling, adaptive shader caching, and Bluetooth latency mitigation.

---

## System Requirements

- **Hardware**: Apple Silicon Mac (M1, M2, M3, M4 or later).
- **Operating System**: macOS 13.0 (Ventura), macOS 14.0 (Sonoma), macOS 15.0 (Sequoia), or macOS 26+.
- **Rosetta 2**: Required for translating x86_64 binaries (`softwareupdate --install-rosetta --agree-to-license`).

---

## Installation & Setup

### Option 1: Pre-Built Release (Recommended)

1. Download the latest release package from the [**Releases Page**](https://github.com/Supermally/Porta/releases).
2. Move `Porta.app` into your `/Applications` folder.
3. Open `Porta.app`.

> [!TIP]
> **macOS Gatekeeper Note**: If macOS displays an *“unverified developer”* or *“cannot be opened”* dialog on early access builds, right-click `Porta.app` in Finder, click **Open**, and confirm. Alternatively, run:
> ```bash
> xattr -cr /Applications/Porta.app
> ```

---

### Option 2: Build from Source

#### Prerequisites

- **Xcode 15+** or **Xcode Command Line Tools**:
  ```bash
  xcode-select --install
  ```
- **Rosetta 2**:
  ```bash
  softwareupdate --install-rosetta --agree-to-license
  ```
- **Rust & Cargo**:
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```

#### Clone & Run

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Supermally/Porta.git
   cd Porta
   ```

2. **Build the Forge Engine (Rust)**:
   ```bash
   cargo build --release
   ```

3. **Launch Porta (SwiftUI)**:
   ```bash
   cd apps/Porta
   swift run
   ```

---

## First-Time Launch

When you launch Porta for the first time:

1. Click **Get Started** on the welcome screen.
2. Porta will automatically download, cryptographically verify (via SHA-256), and extract the required translation runtimes (*Wine Staging, DXVK, and MoltenVK*).
3. Click **Enter Porta** once installation completes.
4. Drag & drop Windows `.exe` files or click **Add → Import** to add games to your library!

---

## Architecture Overview

Porta is split into two integrated layers:

1. **Porta (`apps/Porta`)**: Native macOS SwiftUI frontend utilizing Apple HIG design patterns, dynamic Liquid Glass materials, and AppKit workspace management.
2. **Forge Engine (`crates/`)**: Modular Rust engine providing application discovery, DirectX translation governance, MSVC and anti-cheat troubleshooting, and C-FFI bridging (`crates/bridge`).

```
Porta/
├── apps/
│   ├── Porta/               # Native macOS SwiftUI application
│   └── cli/                 # Forge command-line interface (forge)
├── crates/
│   ├── bridge/              # C-FFI bridge between Rust and Swift
│   ├── core/                # Core compatibility engine & diagnostics
│   ├── prefix/              # Prefix management & Wine configuration
│   ├── scanner/             # Multi-storefront game & app discovery
│   ├── profiles/            # Game compatibility profile definitions
│   └── analyzer/            # Binary inspection & recipe synthesis
├── runtime/                 # Wine/D3DMetal translation patches & scripts
├── README.md                # Project overview & install guide
├── FAQ.md                   # Frequently Asked Questions & Early Access Notes
└── LICENSE.md               # MIT License
```

---

## Security & Package Integrity

- **SHA-256 Checksums**: All external runtime packages (Wine builds, DXVK bundles) are cryptographically validated against SHA-256 hashes prior to extraction.
- **User-Space Operation**: Porta operates entirely in user space without requiring kernel extensions (`kexts`) or `sudo` privileges.
- **AppKit Sandboxing**: File and directory access is governed strictly by macOS Security-Scoped Bookmarks.

---

## Early Access & Project Status

> [!WARNING]
> **Porta is currently in active development (Early Access).** Some features, game profiles, and translation layers are not finalized. Please refer to [FAQ.md](FAQ.md) for known limitations, troubleshooting tips, and development notes.

---

## Acknowledgements & Credits

Porta and Forge Engine build upon the remarkable work of the open-source compatibility and graphics translation communities:

- [**Wine Project (WineHQ)**](https://www.winehq.org) — The core compatibility layer enabling Windows applications to run on POSIX-compliant systems.
- [**Gcenx / macOS Wine Builds**](https://github.com/Gcenx/macOS_Wine_builds) — Dedicated Wine Staging builds and tooling for macOS.
- [**DXVK**](https://github.com/doitsujin/dxvk) & [**DXVK-macOS**](https://github.com/Gcenx/DXVK-macOS) — Vulkan-based translation layer for Direct3D 9/10/11.
- [**MoltenVK**](https://github.com/KhronosGroup/MoltenVK) (The Khronos Group) — Vulkan implementation on top of Apple Metal.
- [**Apple Game Porting Toolkit (D3DMetal)**](https://developer.apple.com/games/) — Apple's DirectX 11/12 to Metal translation runtime.
- [**Sikarugir**](https://github.com/Sikarugir) — Research into macOS Wine 10 and WoW64 process orchestration.

---

## License

Porta is licensed under the [MIT License](LICENSE.md).
