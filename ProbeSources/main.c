#include <hidapi/hidapi.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#define ZSA_VENDOR_ID 12951
#define VOYAGER_PRODUCT_ID 6519
#define TARGET_USAGE_PAGE 65376
#define TARGET_USAGE 97
#define REPORT_SIZE 32

static void hex_dump(const unsigned char *bytes, size_t length) {
    if (length == 0) {
        printf("<empty>");
        return;
    }
    for (size_t i = 0; i < length; i++) {
        printf("%s%02X", i == 0 ? "" : " ", bytes[i]);
    }
}

static void print_wide_or_dash(const wchar_t *value) {
    if (!value) {
        printf("-");
        return;
    }

    char buffer[512];
    size_t converted = wcstombs(buffer, value, sizeof(buffer) - 1);
    if (converted == (size_t)-1) {
        printf("<wide-string>");
        return;
    }
    buffer[converted] = '\0';
    printf("%s", buffer);
}

static void print_hid_error(hid_device *device) {
    const wchar_t *error = hid_error(device);
    if (!error) {
        printf("-\n");
        return;
    }

    char buffer[512];
    size_t converted = wcstombs(buffer, error, sizeof(buffer) - 1);
    if (converted == (size_t)-1) {
        printf("<wide-error>\n");
        return;
    }
    buffer[converted] = '\0';
    printf("%s\n", buffer);
}

static struct hid_device_info *find_voyager_vendor_interface(void) {
    struct hid_device_info *devices = hid_enumerate(ZSA_VENDOR_ID, VOYAGER_PRODUCT_ID);
    struct hid_device_info *current = devices;

    while (current) {
        printf(
            "[probe] device path=%s usagePage=%hu usage=%hu interface=%d manufacturer=",
            current->path ? current->path : "-",
            current->usage_page,
            current->usage,
            current->interface_number
        );
        print_wide_or_dash(current->manufacturer_string);
        printf(" product=");
        print_wide_or_dash(current->product_string);
        printf(" serial=");
        print_wide_or_dash(current->serial_number);
        printf("\n");

        if (current->usage_page == TARGET_USAGE_PAGE && current->usage == TARGET_USAGE) {
            return devices;
        }

        current = current->next;
    }

    return devices;
}

static const struct hid_device_info *select_vendor_interface(const struct hid_device_info *devices) {
    const struct hid_device_info *current = devices;
    while (current) {
        if (current->usage_page == TARGET_USAGE_PAGE && current->usage == TARGET_USAGE) {
            return current;
        }
        current = current->next;
    }
    return NULL;
}

int main(void) {
    if (hid_init() != 0) {
        fprintf(stderr, "[probe] hid_init failed\n");
        return 1;
    }

    struct hid_device_info *devices = find_voyager_vendor_interface();
    const struct hid_device_info *target = select_vendor_interface(devices);
    if (!target) {
        fprintf(stderr, "[probe] No Voyager vendor HID interface found\n");
        hid_free_enumeration(devices);
        hid_exit();
        return 1;
    }

    printf("[probe] opening path=%s usagePage=%hu usage=%hu\n", target->path, target->usage_page, target->usage);
    hid_device *device = hid_open_path(target->path);
    if (!device && target->serial_number) {
        printf("[probe] hid_open_path failed, trying hid_open with serial\n");
        device = hid_open(ZSA_VENDOR_ID, VOYAGER_PRODUCT_ID, target->serial_number);
    }
    if (!device) {
        fprintf(stderr, "[probe] hid_open_path/hid_open failed; hid_error=");
        print_hid_error(NULL);
        hid_free_enumeration(devices);
        hid_exit();
        return 1;
    }

    hid_set_nonblocking(device, 0);

    unsigned char handshake0[REPORT_SIZE + 1];
    unsigned char handshake1[REPORT_SIZE + 1];
    memset(handshake0, 0, sizeof(handshake0));
    memset(handshake1, 0, sizeof(handshake1));
    handshake0[1] = 0;
    handshake1[1] = 1;

    int write0 = hid_write(device, handshake0, sizeof(handshake0));
    int write1 = hid_write(device, handshake1, sizeof(handshake1));
    printf("[probe] write [0] -> %d bytes\n", write0);
    printf("[probe] write [1] -> %d bytes\n", write1);

    for (int i = 0; i < 4; i++) {
        unsigned char feature[REPORT_SIZE + 1];
        memset(feature, 0, sizeof(feature));
        feature[0] = (unsigned char)i;
        int feature_result = hid_get_feature_report(device, feature, sizeof(feature));
        printf("[probe] get_feature_report id=%d -> %d bytes: ", i, feature_result);
        if (feature_result > 0) {
            hex_dump(feature, (size_t)feature_result);
        } else {
            printf("<none>");
        }
        printf("\n");
    }

    printf("[probe] reading for 15 seconds. Press keys and switch layers.\n");
    for (int iteration = 0; iteration < 150; iteration++) {
        unsigned char buffer[REPORT_SIZE + 1];
        memset(buffer, 0, sizeof(buffer));
        int read_result = hid_read_timeout(device, buffer, sizeof(buffer), 100);
        if (read_result < 0) {
            fprintf(stderr, "[probe] hid_read_timeout failed\n");
            break;
        }
        if (read_result > 0) {
            printf("[probe] read -> %d bytes: ", read_result);
            hex_dump(buffer, (size_t)read_result);
            printf("\n");
            fflush(stdout);
        }
    }

    hid_close(device);
    hid_free_enumeration(devices);
    hid_exit();
    return 0;
}
