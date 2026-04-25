#include "zsa_hid_bridge.h"

#include <hidapi/hidapi.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ZSA_VENDOR_ID 12951
#define VOYAGER_PRODUCT_ID 6519
#define TARGET_USAGE_PAGE 65376
#define TARGET_USAGE 97

struct zsa_hid_bridge {
    hid_device *device;
    char last_error[512];
};
typedef struct zsa_hid_bridge zsa_hid_bridge_t;

static void set_error(zsa_hid_bridge_t *bridge, const char *message) {
    if (!bridge) {
        return;
    }
    snprintf(bridge->last_error, sizeof(bridge->last_error), "%s", message ? message : "unknown error");
}

static void set_error_from_hid(zsa_hid_bridge_t *bridge, const char *prefix) {
    if (!bridge) {
        return;
    }

    const wchar_t *error = bridge->device ? hid_error(bridge->device) : NULL;
    if (!error) {
        snprintf(bridge->last_error, sizeof(bridge->last_error), "%s", prefix ? prefix : "hidapi error");
        return;
    }

    char converted[384];
    size_t result = wcstombs(converted, error, sizeof(converted) - 1);
    if (result == (size_t)-1) {
        snprintf(bridge->last_error, sizeof(bridge->last_error), "%s", prefix ? prefix : "hidapi error");
        return;
    }

    converted[result] = '\0';
    snprintf(bridge->last_error, sizeof(bridge->last_error), "%s: %s", prefix ? prefix : "hidapi error", converted);
}

void *zsa_hid_bridge_open_first_voyager(void) {
    if (hid_init() != 0) {
        return NULL;
    }

    zsa_hid_bridge_t *bridge = calloc(1, sizeof(zsa_hid_bridge_t));
    if (!bridge) {
        return NULL;
    }

    struct hid_device_info *devices = hid_enumerate(ZSA_VENDOR_ID, VOYAGER_PRODUCT_ID);
    const struct hid_device_info *current = devices;
    const char *path = NULL;

    while (current) {
        if (current->usage_page == TARGET_USAGE_PAGE && current->usage == TARGET_USAGE) {
            path = current->path;
            break;
        }
        current = current->next;
    }

    if (!path) {
        set_error(bridge, "Voyager vendor HID interface not found");
        hid_free_enumeration(devices);
        return bridge;
    }

    bridge->device = hid_open_path(path);
    hid_free_enumeration(devices);

    if (!bridge->device) {
        set_error(bridge, "hid_open_path failed");
        return bridge;
    }

    hid_set_nonblocking(bridge->device, 0);
    return bridge;
}

void zsa_hid_bridge_close(void *raw_bridge) {
    zsa_hid_bridge_t *bridge = (zsa_hid_bridge_t *)raw_bridge;
    if (!bridge) {
        return;
    }
    if (bridge->device) {
        hid_close(bridge->device);
    }
    hid_exit();
    free(bridge);
}

int32_t zsa_hid_bridge_write_command(void *raw_bridge, uint8_t command) {
    zsa_hid_bridge_t *bridge = (zsa_hid_bridge_t *)raw_bridge;
    if (!bridge || !bridge->device) {
        set_error(bridge, "device not open");
        return -1;
    }

    unsigned char buffer[33];
    memset(buffer, 0, sizeof(buffer));
    buffer[1] = command;

    int result = hid_write(bridge->device, buffer, sizeof(buffer));
    if (result < 0) {
        set_error_from_hid(bridge, "hid_write failed");
    }
    return result;
}

int32_t zsa_hid_bridge_get_feature_report(void *raw_bridge, uint8_t report_id, uint8_t *buffer, int32_t length) {
    zsa_hid_bridge_t *bridge = (zsa_hid_bridge_t *)raw_bridge;
    if (!bridge || !bridge->device || !buffer || length <= 0) {
        set_error(bridge, "invalid feature report request");
        return -1;
    }

    memset(buffer, 0, (size_t)length);
    buffer[0] = report_id;
    int result = hid_get_feature_report(bridge->device, buffer, (size_t)length);
    if (result < 0) {
        set_error_from_hid(bridge, "hid_get_feature_report failed");
    }
    return result;
}

int32_t zsa_hid_bridge_read_timeout(void *raw_bridge, uint8_t *buffer, int32_t length, int32_t timeout_ms) {
    zsa_hid_bridge_t *bridge = (zsa_hid_bridge_t *)raw_bridge;
    if (!bridge || !bridge->device || !buffer || length <= 0) {
        set_error(bridge, "invalid read request");
        return -1;
    }

    memset(buffer, 0, (size_t)length);
    int result = hid_read_timeout(bridge->device, buffer, (size_t)length, timeout_ms);
    if (result < 0) {
        set_error_from_hid(bridge, "hid_read_timeout failed");
    }
    return result;
}

const char *zsa_hid_bridge_last_error(void *raw_bridge) {
    zsa_hid_bridge_t *bridge = (zsa_hid_bridge_t *)raw_bridge;
    if (!bridge || bridge->last_error[0] == '\0') {
        return "unknown error";
    }
    return bridge->last_error;
}
