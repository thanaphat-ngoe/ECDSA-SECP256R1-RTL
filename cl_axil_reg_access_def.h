// =============================================================================
// Amazon FPGA Hardware Development Kit
//
// Copyright 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.
// =============================================================================

#pragma once

// Register offsets
#define ADDR_RANDOMED_PRIVATE_KEY_1 0x00
#define ADDR_RANDOMED_PRIVATE_KEY_2 0x04
#define ADDR_RANDOMED_PRIVATE_KEY_3 0x08
#define ADDR_RANDOMED_PRIVATE_KEY_4 0x0C
#define ADDR_RANDOMED_PRIVATE_KEY_5 0x10
#define ADDR_RANDOMED_PRIVATE_KEY_6 0x14
#define ADDR_RANDOMED_PRIVATE_KEY_7 0x18
#define ADDR_RANDOMED_PRIVATE_KEY_8 0x1C

#define ADDR_PUBLIC_KEY_X_1         0x20
#define ADDR_PUBLIC_KEY_X_2         0x24
#define ADDR_PUBLIC_KEY_X_3         0x28
#define ADDR_PUBLIC_KEY_X_4         0x2C
#define ADDR_PUBLIC_KEY_X_5         0x30
#define ADDR_PUBLIC_KEY_X_6         0x34
#define ADDR_PUBLIC_KEY_X_7         0x38
#define ADDR_PUBLIC_KEY_X_8         0x3C

#define ADDR_PUBLIC_KEY_Y_1         0x40
#define ADDR_PUBLIC_KEY_Y_2         0x44
#define ADDR_PUBLIC_KEY_Y_3         0x48
#define ADDR_PUBLIC_KEY_Y_4         0x4C
#define ADDR_PUBLIC_KEY_Y_5         0x50
#define ADDR_PUBLIC_KEY_Y_6         0x54
#define ADDR_PUBLIC_KEY_Y_7         0x58
#define ADDR_PUBLIC_KEY_Y_8         0x5C

#define CL_AXIL_REG_OFFSET_CONTROL  0x60  // RW : bit[0] Start — write 1 to trigger addition; bit[1] Ready — read-only, set when result is ready, cleared after both Sum and Carry are read

// Control reg masks
#define CONTROL_READY_MASK 0x02
#define CONTROL_START_MASK 0x01
// FPGA Slot 0
#define SLOT_ID 0

// PCIe BAR (PF0-BAR0 for OCL registers). See https://awsdocs-fpga-f2.readthedocs-hosted.com/latest/hdk/docs/AWS-Fpga-Pcie-Memory-Map.html
#define CL_AXIL_DEMO_APP_PF      0
#define CL_AXIL_DEMO_BAR_ID      0
#define CL_AXIL_DEMO_PCI_FLAGS   0  // Write combining disabled
