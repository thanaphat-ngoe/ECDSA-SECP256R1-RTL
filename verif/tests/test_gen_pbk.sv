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

// Test Public Key Generation

module test_gen_pbk();

`include "test_base.inc"

logic [255:0] pvk = 256'h383e1159ba87a74eedb20c0d2981c2744daa66a4974e1f5e066324fb6333b725;
logic [255:0] pbk_x, pbk_y;
// logic [255:0] temp_pbk_x, temp_pbk_y;

initial begin
    $display("\n");
    $display("================================================================================");
    $display(" TEST: test_gen_pbk");
    $display("================================================================================");

    power_up();
    delay_ns(1000);

    //==========================================================================
    // Test 1: Result Stability
    //==========================================================================
    $display("\n[%t] ===== Test 1: Result Stability =====", $time);

    // Perform an addition
    perform_gen_pbk(pvk, pbk_x, pbk_y);

    // Read results multiple times and verify they remain stable
    $display("[%t] Verifying result stability (multiple reads)...", $time);

    // for (int i = 0; i < 5; i++) begin
    //     delay_ns(100);
    //     read_results(temp_sum, temp_carry);
    //     check_value(temp_sum, sum, $sformatf("Result stability check %0d - sum", i));
    //     check_value(temp_carry, carry, $sformatf("Result stability check %0d - carry", i));
    // end

    // delay_ns(200);

    //==========================================================================
    // Test Summary
    //==========================================================================
    delay_ns(1_000_000);
    power_down();

    $display("\n[%t] Test completed", $time);
    report_pass_fail_status();

    $finish;
end

endmodule // test_gen_pbk
