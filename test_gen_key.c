// ============================================================================
// Amazon FPGA Hardware Development Kit
// ... (License Header) ...
// ============================================================================

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>

#include "fpga_pci.h"
#include "fpga_mgmt.h"
#include "utils/lcd.h"

#include "cl_axil_reg_access_def.h"

#define MAX_ATTEMPTS 10000 // กำหนด Timeout สำหรับการ Polling (ปรับแต่งได้ตามความเร็วของ Hardware)

static const struct logger *logger = &logger_stdout;

void usage(const char *program_name)
{
    printf("usage: %s [--slot <slot>]\n", program_name);
}

int main(int argc, char **argv)
{
    int rc;
    int slot_id = 0;
    int attempts = 0;
    uint32_t status = 0;

    // ข้อมูล Private Key (256-bit)
    uint32_t private_key[8] = {
		0x6333b725, 0x066324fb, 0x974e1f5e, 0x4daa66a4,
		0x2981c274, 0xedb20c0d, 0xba87a74e, 0x383e1159
    };

    // Buffer สำหรับรอรับ Public Key กลับมา
    uint32_t public_key_x[8] = {0};
    uint32_t public_key_y[8] = {0};

    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;

    // Parse command line arguments
    for (int i = 1; i < argc; i++)
    {
        if (strncmp(argv[i], "--slot", sizeof("--slot") - 1) == 0 && i + 1 < argc)
        {
            slot_id = atoi(argv[++i]);
        }
        else
        {
            usage(argv[0]);
            return 1;
        }
    }

    // Initialize logging
    rc = log_init("Public_Key_Generation_Test");
    fail_on(rc, out, "Unable to initialize the log.");
    rc = log_attach(logger, NULL, 0);
    fail_on(rc, out, "Unable to attach to the log.");

    // Initialize FPGA management library
    rc = fpga_mgmt_init();
    fail_on(rc, out, "Unable to initialize the fpga_mgmt library");

    printf("===================================================\n");
    printf("Running SECP256R1 Public Key Generation Test\n");
    printf("===================================================\n");
    printf("slot_id = %d\n", slot_id);
    for (int i = 0; i < 8; i++) {
        printf("private_key[%d] = 0x%08x\n", i, private_key[i]);
    }
    printf("===================================================\n");

    // Attach to PCIe BAR
    rc = fpga_pci_attach(slot_id, CL_AXIL_DEMO_APP_PF, CL_AXIL_DEMO_BAR_ID, CL_AXIL_DEMO_PCI_FLAGS, &pci_bar_handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d\nCheck if the AFI is properly loaded", slot_id);

    // -------------------------------------------------------------------------
    // 1. Write Private Key (256-bit => 8 x 32-bit registers)
    // -------------------------------------------------------------------------
    printf("Writing Private Key to FPGA...\n");
    for (int i = 0; i < 8; i++) {
        // ใช้ Base Address บวกด้วย Offset (i * 4)
        rc = fpga_pci_poke(pci_bar_handle, ADDR_RANDOMED_PRIVATE_KEY_1 + (i * 4), private_key[i]);
        fail_on(rc, out, "Unable to write private_key[%d]", i);
    }

    // -------------------------------------------------------------------------
    // 2. Trigger Hardware (Write CONTROL_START_MASK)
    // -------------------------------------------------------------------------
    printf("Triggering SECP256R1 Calculation...\n");
    rc = fpga_pci_poke(pci_bar_handle, CL_AXIL_REG_OFFSET_CONTROL, CONTROL_START_MASK);
    fail_on(rc, out, "Unable to write to CL_AXIL_REG_OFFSET_CONTROL");

    // -------------------------------------------------------------------------
    // 3. Polling Status until READY
    // -------------------------------------------------------------------------
    printf("Polling for READY status...\n");
    bool is_ready = false;
    do
    {
        rc = fpga_pci_peek(pci_bar_handle, CL_AXIL_REG_OFFSET_CONTROL, &status);
        fail_on(rc, out, "Unable to read from CL_AXIL_REG_OFFSET_CONTROL");
        
        is_ready = (status & CONTROL_READY_MASK) != 0;
        if (!is_ready)
        {
            usleep(1000); // Sleep 1ms เพื่อไม่ให้ CPU โหลด 100% ตอนรัน Polling loop
        }
        attempts++;
    } while (!is_ready && (attempts < MAX_ATTEMPTS));

    fail_on(attempts >= MAX_ATTEMPTS, out, "Timeout waiting for ready flag");
    // อัปเดตเช็กว่า START bit ถูกเคลียร์ลงไปแล้วตามดีไซน์ของฝั่ง Hardware หรือไม่
    fail_on((status & CONTROL_START_MASK) != 0, out, "CONTROL_START_MASK still high after ready");

    // -------------------------------------------------------------------------
    // 4. Read Public Key X & Y
    // -------------------------------------------------------------------------
    printf("Calculation complete! Reading Public Key...\n");
    for (int i = 0; i < 8; i++) {
        rc = fpga_pci_peek(pci_bar_handle, ADDR_PUBLIC_KEY_X_1 + (i * 4), &public_key_x[i]);
        fail_on(rc, out, "Unable to read public_key_x[%d]", i);
    }
    
    for (int i = 0; i < 8; i++) {
        rc = fpga_pci_peek(pci_bar_handle, ADDR_PUBLIC_KEY_Y_1 + (i * 4), &public_key_y[i]);
        fail_on(rc, out, "Unable to read public_key_y[%d]", i);
    }

    // -------------------------------------------------------------------------
    // Print Results
    // -------------------------------------------------------------------------
    printf("===================================================\n");
    printf("Public Key X:\n");
    for (int i = 0; i < 8; i++) {
        printf("  X[%d] = 0x%08x\n", i, public_key_x[i]);
    }
    printf("Public Key Y:\n");
    for (int i = 0; i < 8; i++) {
        printf("  Y[%d] = 0x%08x\n", i, public_key_y[i]);
    }
    printf("===================================================\n");
    printf("TEST PASSED\n");

out:
    return rc;
}
ß