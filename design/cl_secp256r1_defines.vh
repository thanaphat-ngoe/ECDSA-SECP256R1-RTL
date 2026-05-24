// ============================================================================
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
// ============================================================================

`ifndef CL_SECP256R1_DEFINES
`define CL_SECP256R1_DEFINES

//Put module name of the CL design here.  This is used to instantiate in top.sv
`define CL_NAME cl_secp256r1

// Uncomment to disable ILA debug
// `define NO_CL_AXIL_DEBUG_ILA

// Register address offsets
`define ADDR_RANDOMED_PRIVATE_KEY_1 32'h00
`define ADDR_RANDOMED_PRIVATE_KEY_2 32'h04
`define ADDR_RANDOMED_PRIVATE_KEY_3 32'h08
`define ADDR_RANDOMED_PRIVATE_KEY_4 32'h0C
`define ADDR_RANDOMED_PRIVATE_KEY_5 32'h10
`define ADDR_RANDOMED_PRIVATE_KEY_6 32'h14
`define ADDR_RANDOMED_PRIVATE_KEY_7 32'h18
`define ADDR_RANDOMED_PRIVATE_KEY_8 32'h1C

`define ADDR_PUBLIC_KEY_X_1         32'h20
`define ADDR_PUBLIC_KEY_X_2         32'h24
`define ADDR_PUBLIC_KEY_X_3         32'h28
`define ADDR_PUBLIC_KEY_X_4         32'h2C
`define ADDR_PUBLIC_KEY_X_5         32'h30
`define ADDR_PUBLIC_KEY_X_6         32'h34
`define ADDR_PUBLIC_KEY_X_7         32'h38
`define ADDR_PUBLIC_KEY_X_8         32'h3C

`define ADDR_PUBLIC_KEY_Y_1         32'h40
`define ADDR_PUBLIC_KEY_Y_2         32'h44
`define ADDR_PUBLIC_KEY_Y_3         32'h48
`define ADDR_PUBLIC_KEY_Y_4         32'h4C
`define ADDR_PUBLIC_KEY_Y_5         32'h50
`define ADDR_PUBLIC_KEY_Y_6         32'h54
`define ADDR_PUBLIC_KEY_Y_7         32'h58
`define ADDR_PUBLIC_KEY_Y_8         32'h5C


`define ADDR_CONTROL_STATUS 		32'h60
`define INVALID_ADDR_RESP   		32'hDEADBEEF

// AXI constants
`define AXI_PROT_DEFAULT            3'h0
`define AXI_RESP_OKAY               2'b00

`endif
