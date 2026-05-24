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


`include "common_base_test.svh"
`include "cl_secp256r1_defines.vh"

`ifndef CL_AXIL_TEST_BASE
`define CL_AXIL_TEST_BASE
import tb_type_defines_pkg::*;

// Invalid address for testing
localparam logic[63:0] ADDR_INVALID = 64'h14;

// Write to control/status register
task write_control_status(input logic[31:0] data);
    tb.poke_ocl(.addr(`ADDR_CONTROL_STATUS), .data(data));
endtask

// Read from control/status register
task read_control_status(output logic[31:0] data);
    logic[63:0] rdata;
    tb.peek_ocl(.addr(`ADDR_CONTROL_STATUS), .data(rdata));
    data = rdata[31:0];
endtask

// Trigger addition operation (write start bit)
task trigger_gen_key();
    write_control_status(32'h00000001);  // Set bit[0] = 1 (start)
endtask

// Check ready flag from control/status register
task check_ready(output logic ready);
    logic[31:0] ctrl_stat;
    read_control_status(ctrl_stat);
    ready = ctrl_stat[1];  // bit[1] is ready flag
endtask

// Check if value matches expected
task check_value(
    input logic[31:0] actual,
    input logic[31:0] expected,
    input string msg
);
    if (actual !== expected) begin
        $error("[%t] ERROR: %s", $time, msg);
        $display("        Expected: 0x%08x", expected);
        $display("        Actual:   0x%08x", actual);
        error_count++;
    end else begin
        $display("[%t] PASS: %s", $time, msg);
    end
endtask

// Check if bit matches expected
task check_bit(
    input logic actual,
    input logic expected,
    input string msg
);
    if (actual !== expected) begin
        $error("[%t] ERROR: %s", $time, msg);
        $display("        Expected: %b", expected);
        $display("        Actual:   %b", actual);
        error_count++;
    end else begin
        $display("[%t] PASS: %s", $time, msg);
    end
endtask

// Read and verify register value
task verify_register(
    input logic[63:0] addr,
    input logic[31:0] expected,
    input string reg_name
);
    logic[63:0] rdata;
    tb.peek_ocl(.addr(addr), .data(rdata));
    check_value(rdata[31:0], expected, $sformatf("%s register", reg_name));
endtask

//==============================================================================
// Utility Tasks
//==============================================================================

// Power up helper
task power_up();
    tb.power_up();
endtask

// Power down helper
task power_down();
    tb.power_down();
endtask

// Delay in nanoseconds
task delay_ns(input int ns);
    #(ns * 1ns);
endtask

// Read from arbitrary address
task read_address(input logic[63:0] addr, output logic[31:0] data);
    logic[63:0] rdata;
    tb.peek_ocl(.addr(addr), .data(rdata));
    data = rdata[31:0];
endtask

// Write to arbitrary address
task write_address(input logic[63:0] addr, input logic[31:0] data);
    tb.poke_ocl(.addr(addr), .data(data));
endtask

task perform_gen_pbk(
    input  logic [255:0] pvk,
    output logic [255:0] pbk_x,
    output logic [255:0] pbk_y
);
    // Move the local variable declaration to the top of the task
    logic [31:0] rdata; 

    // Write operands
    tb.poke_ocl(.addr(`ADDR_RANDOMED_PRIVATE_KEY_1), .data(pvk[31:0]));
    tb.poke_ocl(.addr(`ADDR_RANDOMED_PRIVATE_KEY_2), .data(pvk[63:32]));
    tb.poke_ocl(.addr(`ADDR_RANDOMED_PRIVATE_KEY_3), .data(pvk[95:64]));
    tb.poke_ocl(.addr(`ADDR_RANDOMED_PRIVATE_KEY_4), .data(pvk[127:96]));
    tb.poke_ocl(.addr(`ADDR_RANDOMED_PRIVATE_KEY_5), .data(pvk[159:128]));
    tb.poke_ocl(.addr(`ADDR_RANDOMED_PRIVATE_KEY_6), .data(pvk[191:160]));
    tb.poke_ocl(.addr(`ADDR_RANDOMED_PRIVATE_KEY_7), .data(pvk[223:192]));
    tb.poke_ocl(.addr(`ADDR_RANDOMED_PRIVATE_KEY_8), .data(pvk[255:224]));

    // Trigger operation
    trigger_gen_key();

    // Delay for operation to complete
    #10_000_000ns;

    // Read results for X coordinate
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_X_1), .data(rdata));
    pbk_x[31:0] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_X_2), .data(rdata));
    pbk_x[63:32] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_X_3), .data(rdata));
    pbk_x[95:64] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_X_4), .data(rdata));
    pbk_x[127:96] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_X_5), .data(rdata));
    pbk_x[159:128] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_X_6), .data(rdata));
    pbk_x[191:160] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_X_7), .data(rdata));
    pbk_x[223:192] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_X_8), .data(rdata));
    pbk_x[255:224] = rdata;

    // Read results for Y coordinate
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_Y_1), .data(rdata));
    pbk_y[31:0] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_Y_2), .data(rdata));
    pbk_y[63:32] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_Y_3), .data(rdata));
    pbk_y[95:64] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_Y_4), .data(rdata));
    pbk_y[127:96] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_Y_5), .data(rdata));
    pbk_y[159:128] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_Y_6), .data(rdata));
    pbk_y[191:160] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_Y_7), .data(rdata));
    pbk_y[223:192] = rdata;
    tb.peek_ocl(.addr(`ADDR_PUBLIC_KEY_Y_8), .data(rdata));
    pbk_y[255:224] = rdata;
endtask

`endif // CL_AXIL_TEST_BASE
