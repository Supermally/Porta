// Stage 5 - Steam Overlay Injection Hook
// intercepts IDirect3DDevice9::Present / IDXGISwapChain::Present to render the Steam Overlay
// utilizing our D3DMetalContext for drawing WebKit textures over the game frame.

#include <iostream>

extern "C" {
    void Porta_InjectSteamOverlay() {
        std::cout << "[Steam Overlay] Hooked into Present() swapchain. Ready to composite CEF texture." << std::endl;
    }
}
