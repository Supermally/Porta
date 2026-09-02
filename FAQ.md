# Frequently Asked Questions & Early Access Notes

## 1. Project Status & Early Access Notice

### Is Porta finalized or production-ready?
No. **Porta is currently in active Early Access / Alpha development.** 
While many Windows games and applications run with near-native performance, you may encounter unexpected graphical glitches, audio synchronization latency, missing DirectX dependencies, or unexpected crashes depending on the title.

We are continuously refining the **Forge Engine** translation subsystem, improving shader caching, and expanding storefront integration.

---

## 2. Common Questions & Troubleshooting

### Why does a game show a black screen for the first 1–2 minutes?
DirectX 12 games translate shaders into Apple Metal Pipeline State Objects (PSOs) at launch. On the very first launch of a title, the GPU compiles these shaders into disk cache. Subsequent launches will load immediately with cached shaders.

### Can I run games with Kernel-Level Anti-Cheat (Vanguard, EAC, BattlEye, Ricochet)?
No. Games that require Windows kernel-mode drivers (`.sys`) cannot run inside Wine or user-space translation environments on macOS. Games like *Valorant*, *Fortnite*, or *League of Legends (Vanguard)* are marked as **[Blocked / Unsupported]** by the Forge Troubleshooter.

### Why does Steam launch with `--no-sandbox` flags?
Chromium Embedded Framework (CEF), which renders the Steam store and friends list, requires Windows sandbox primitives that do not translate cleanly across macOS Mach IPC. Running with compatibility flags ensures the Steam client UI remains fluid and responsive without freezing.

### How do I enable the Apple Metal Performance HUD overlay?
Go to **Settings** → **Graphics & Compatibility Runtime** and toggle **Metal Performance HUD Overlay**, or enable it per-game in the Game Details inspector.

---

## 3. Known Limitations & Bugs

| Area | Status / Note |
| :--- | :--- |
| **DirectX 9 / 32-bit Legacy Games** | 32-bit executables run via unified WoW64 translation; certain legacy D3D9 titles may require DXVK overrides. |
| **Retina / HiDPI Scaling** | High-DPI scaling is enabled by default. Some older Windows titles may render at 1/4 resolution unless display mode override is configured in Game Settings. |
| **Custom Controllers** | DualSense, Xbox Wireless, and Nintendo Switch Pro controllers are supported via macOS GameController framework. Third-party direct-input drivers may vary. |

---

## 4. Reporting Issues & Feedback

Please open an issue on the [GitHub Issues tracker](https://github.com/Supermally/Porta/issues) with:
- macOS version and Apple Silicon chip (e.g., macOS 15.1, M3 Max)
- Target game / application executable name
- Console log snippet from **Settings → Developer Console** or `~/Library/Application Support/Porta/logs`
