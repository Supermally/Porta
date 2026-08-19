#ifndef MAC_GAMING_BRIDGE_H
#define MAC_GAMING_BRIDGE_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* MacGamingEngineHandle;

MacGamingEngineHandle mac_gaming_engine_new(void);
void mac_gaming_engine_free(MacGamingEngineHandle handle);
void mac_gaming_free_string(char* s);

char* mac_gaming_diagnostics_json(MacGamingEngineHandle handle);
char* mac_gaming_scan_all_json(MacGamingEngineHandle handle);
char* mac_gaming_scan_storefront_json(MacGamingEngineHandle handle, const char* storefront);
char* mac_gaming_get_all_games_json(MacGamingEngineHandle handle);
char* mac_gaming_import_game_json(MacGamingEngineHandle handle, const char* path, const char* title);
char* mac_gaming_import_universal_app_json(MacGamingEngineHandle handle, const char* path, const char* title);
char* mac_gaming_prepare_launch_json(
    MacGamingEngineHandle handle,
    const char* game_id,
    bool force_d3dmetal,
    bool force_dxvk,
    bool enable_hud,
    bool enable_esync,
    bool enable_fsync
);
char* mac_gaming_troubleshoot_json(MacGamingEngineHandle handle, const char* log_text);
char* mac_gaming_sync_community_profiles_json(MacGamingEngineHandle handle);
char* mac_gaming_check_provisioning_json(MacGamingEngineHandle handle, const char* game_id);

#ifdef __cplusplus
}
#endif

#endif /* MAC_GAMING_BRIDGE_H */
