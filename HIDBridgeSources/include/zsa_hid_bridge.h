#ifndef ZSA_HID_BRIDGE_H
#define ZSA_HID_BRIDGE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void *zsa_hid_bridge_open_first_voyager(void);
void zsa_hid_bridge_close(void *bridge);

int32_t zsa_hid_bridge_write_command(void *bridge, uint8_t command);
int32_t zsa_hid_bridge_get_feature_report(void *bridge, uint8_t report_id, uint8_t *buffer, int32_t length);
int32_t zsa_hid_bridge_read_timeout(void *bridge, uint8_t *buffer, int32_t length, int32_t timeout_ms);
const char *zsa_hid_bridge_last_error(void *bridge);

#ifdef __cplusplus
}
#endif

#endif
