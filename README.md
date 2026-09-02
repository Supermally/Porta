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

## Architecture Overview

Porta is split into two integrated layers:

1. **Porta (`apps/Porta`)**: Native macOS SwiftUI frontend utilizing Apple HIG design patterns, dynamic Liquid Glass materials, and AppKit workspace management.
2. **Forge Engine (`crates/`)**: Modular Rust engine providing application discovery, DirectX translation governance, MSVC and anti-cheat troubleshooting, and C-FFI bridging (`crates/bridge`).

```
mac-gaming/
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
├── README.md                # Project overview
└── FAQ.md                   # Frequently Asked Questions & Early Access Notes
```

---

## System Requirements

- **Mac**: Apple Silicon Mac (M1, M2, M3, M4 or later).
- **Operating System**: macOS 13.0 (Ventura), macOS 14.0 (Sonoma), macOS 15.0 (Sequoia), or macOS 26+.
- **Rosetta 2**: Required for translating x86_64 binaries (`softwareupdate --install-rosetta --agree-to-license`).

---

## Building from Source

### Prerequisites

- **Xcode 15+** or **Xcode Command Line Tools** (`xcode-select --install`)
- **Rust & Cargo** (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
- **Swift 6.0+**

### Build Commands

1. **Build the Forge Rust Engine**:
   ```bash
   cargo build --release
   ```

2. **Run Tests**:
   ```bash
   cargo test
   ```

3. **Build the Porta SwiftUI App**:
   ```bash
   cd apps/Porta
   swift build
   ```

4. **Launch the Application**:
   ```bash
   swift run
   ```

---

## Security & Package Integrity

- **SHA-256 Checksums**: All external runtime packages (Wine builds, DXVK bundles) are cryptographically validated against SHA-256 hashes prior to extraction.
- **User-Space Operation**: Porta operates without kernel extensions (`kexts`) or `sudo` privileges.
- **AppKit Sandboxing**: File access is governed by macOS Security-Scoped Bookmarks.

---

## Early Access & Notes

> [!WARNING]
> **Porta is currently in active development (Early Access).** Some features, game profiles, and translation layers are not finalized. Please refer to [FAQ.md](FAQ.md) for known limitations, troubleshooting tips, and development notes.

---

## License & Acknowledgements

Porta is released under the MIT License. Special thanks to the Wine, DXVK, MoltenVK, and Sikarugir projects for their foundational compatibility research.
