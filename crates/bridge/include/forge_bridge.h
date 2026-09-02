#ifndef MAC_GAMING_BRIDGE_H
#define MAC_GAMING_BRIDGE_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* ForgeEngineHandle;

ForgeEngineHandle forge_engine_new(void);
void forge_engine_free(ForgeEngineHandle handle);
void forge_free_string(char* s);

char* forge_diagnostics_json(ForgeEngineHandle handle);
char* forge_scan_all_json(ForgeEngineHandle handle);
char* forge_scan_storefront_json(ForgeEngineHandle handle, const char* storefront);
char* forge_get_all_games_json(ForgeEngineHandle handle);
char* forge_import_game_json(ForgeEngineHandle handle, const char* path, const char* title);
char* forge_import_universal_app_json(ForgeEngineHandle handle, const char* path, const char* title);
char* forge_prepare_launch_json(
    ForgeEngineHandle handle,
    const char* game_id,
    bool force_d3dmetal,
    bool force_dxvk,
    bool enable_hud,
    bool enable_esync,
    bool enable_fsync
);
char* forge_troubleshoot_json(ForgeEngineHandle handle, const char* log_text);
char* forge_sync_community_profiles_json(ForgeEngineHandle handle);
char* forge_check_provisioning_json(ForgeEngineHandle handle, const char* game_id);

#ifdef __cplusplus
}
#endif

#endif /* MAC_GAMING_BRIDGE_H */
