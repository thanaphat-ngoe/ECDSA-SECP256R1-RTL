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


// CL AXI-LITE REGISTER ACCESS

`include "cl_secp256r1_defines.vh"

module cl_secp256r1

(
  `include "cl_ports.vh"
);

`include "cl_id_defines.vh"
`include "unused_flr_template.inc"
`include "unused_ddr_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_apppf_irq_template.inc"
`include "unused_dma_pcis_template.inc"
`include "unused_pcim_template.inc"

	assign cl_sh_id0 = `CL_SH_ID0;
	assign cl_sh_id1 = `CL_SH_ID1;

//----------------------------
// Internal signals
//----------------------------

	// Internal OCL signals
	logic         sh_ocl_awvalid_q;
	logic [31:0]  sh_ocl_awaddr_q;
	logic         sh_ocl_wvalid_q;
	logic [31:0]  sh_ocl_wdata_q;
	logic [3:0]   sh_ocl_wstrb_q;
	logic         sh_ocl_bready_q;
	logic         sh_ocl_arvalid_q;
	logic [31:0]  sh_ocl_araddr_q;
	logic         sh_ocl_rready_q;
	logic         ocl_sh_awready_q = 1'b0;
	logic         ocl_sh_wready_q  = 1'b0;
	logic         ocl_sh_bvalid_q  = 1'b0;
	logic [1:0]   ocl_sh_bresp_q   = 2'b00;
	logic         ocl_sh_arready_q = 1'b0;
	logic         ocl_sh_rvalid_q  = 1'b0;
	logic [31:0]  ocl_sh_rdata_q   = 32'h0;
	logic [1:0]   ocl_sh_rresp_q   = 2'b00;

	// FSM states
	typedef enum logic [2:0] {
		IDLE       = 3'd0,
		WRITE_WAIT = 3'd1,
		WRITE      = 3'd2,
		WRITE_RESP = 3'd3,
		READ       = 3'd4
	} axil_state_t;

	axil_state_t current_state = IDLE;
	axil_state_t next_state;

	// Control and status signals
	logic start_pulse           = 1'b0;
	logic ready_flag            = 1'b0;

	logic reg_pbk_x_1_read_flag = 1'b0;
	logic reg_pbk_x_2_read_flag = 1'b0;
	logic reg_pbk_x_3_read_flag = 1'b0;
	logic reg_pbk_x_4_read_flag = 1'b0;
	logic reg_pbk_x_5_read_flag = 1'b0;
	logic reg_pbk_x_6_read_flag = 1'b0;
	logic reg_pbk_x_7_read_flag = 1'b0;
	logic reg_pbk_x_8_read_flag = 1'b0;

	logic reg_pbk_y_1_read_flag = 1'b0;
	logic reg_pbk_y_2_read_flag = 1'b0;
	logic reg_pbk_y_3_read_flag = 1'b0;
	logic reg_pbk_y_4_read_flag = 1'b0;
	logic reg_pbk_y_5_read_flag = 1'b0;
	logic reg_pbk_y_6_read_flag = 1'b0;
	logic reg_pbk_y_7_read_flag = 1'b0;
	logic reg_pbk_y_8_read_flag = 1'b0;

	// Handshake signals
	logic data_wr_handshake;
	logic addr_rd_handshake;
	logic addr_wr_handshake;
	logic bresp_handshake;
	logic data_rd_handshake;

	// Register access logic
	logic [31:0] reg_pvk_1          = 32'h0;
	logic [31:0] reg_pvk_2          = 32'h0;
	logic [31:0] reg_pvk_3          = 32'h0;
	logic [31:0] reg_pvk_4          = 32'h0;
	logic [31:0] reg_pvk_5          = 32'h0;
	logic [31:0] reg_pvk_6          = 32'h0;
	logic [31:0] reg_pvk_7          = 32'h0;
	logic [31:0] reg_pvk_8          = 32'h0;

	logic [31:0] reg_pbk_x_1        = 32'h0;
	logic [31:0] reg_pbk_x_2        = 32'h0;
	logic [31:0] reg_pbk_x_3        = 32'h0;
	logic [31:0] reg_pbk_x_4        = 32'h0;
	logic [31:0] reg_pbk_x_5        = 32'h0;
	logic [31:0] reg_pbk_x_6        = 32'h0;
	logic [31:0] reg_pbk_x_7        = 32'h0;
	logic [31:0] reg_pbk_x_8        = 32'h0;

	logic [31:0] reg_pbk_y_1        = 32'h0;
	logic [31:0] reg_pbk_y_2        = 32'h0;
	logic [31:0] reg_pbk_y_3        = 32'h0;
	logic [31:0] reg_pbk_y_4        = 32'h0;
	logic [31:0] reg_pbk_y_5        = 32'h0;
	logic [31:0] reg_pbk_y_6        = 32'h0;
	logic [31:0] reg_pbk_y_7        = 32'h0;
	logic [31:0] reg_pbk_y_8        = 32'h0;

	logic [255:0] w_EX_SECP256R1_PUBLIC_KEY_X_OR_SIGNATURE_r;
	logic [255:0] w_EX_SECP256R1_PUBLIC_KEY_Y_OR_SIGNATURE_s;

	logic [31:0] reg_control_status = 32'h0;

	// Address capture
	logic [31:0] write_addr = 32'h0;
	logic [31:0] read_addr  = 32'h0;

	logic w_SECP256R1_EX_DONE = 0;
//----------------------------
// OCL Interface Connections
//----------------------------

// OCL register slice
axi_register_slice_light AXIL_OCL_REG_SLC (
	.aclk          (clk_main_a0),
	.aresetn       (rst_main_n),
	.s_axi_awaddr  (ocl_cl_awaddr),
	.s_axi_awprot  (`AXI_PROT_DEFAULT),
	.s_axi_awvalid (ocl_cl_awvalid),
	.s_axi_awready (cl_ocl_awready),
	.s_axi_wdata   (ocl_cl_wdata),
	.s_axi_wstrb   (ocl_cl_wstrb),
	.s_axi_wvalid  (ocl_cl_wvalid),
	.s_axi_wready  (cl_ocl_wready),
	.s_axi_bresp   (cl_ocl_bresp),
	.s_axi_bvalid  (cl_ocl_bvalid),
	.s_axi_bready  (ocl_cl_bready),
	.s_axi_araddr  (ocl_cl_araddr),
	.s_axi_arprot  (`AXI_PROT_DEFAULT),
	.s_axi_arvalid (ocl_cl_arvalid),
	.s_axi_arready (cl_ocl_arready),
	.s_axi_rdata   (cl_ocl_rdata),
	.s_axi_rresp   (cl_ocl_rresp),
	.s_axi_rvalid  (cl_ocl_rvalid),
	.s_axi_rready  (ocl_cl_rready),
	.m_axi_awaddr  (sh_ocl_awaddr_q),
	.m_axi_awprot  (),
	.m_axi_awvalid (sh_ocl_awvalid_q),
	.m_axi_awready (ocl_sh_awready_q),
	.m_axi_wdata   (sh_ocl_wdata_q),
	.m_axi_wstrb   (sh_ocl_wstrb_q),
	.m_axi_wvalid  (sh_ocl_wvalid_q),
	.m_axi_wready  (ocl_sh_wready_q),
	.m_axi_bresp   (ocl_sh_bresp_q),
	.m_axi_bvalid  (ocl_sh_bvalid_q),
	.m_axi_bready  (sh_ocl_bready_q),
	.m_axi_araddr  (sh_ocl_araddr_q),
	.m_axi_arvalid (sh_ocl_arvalid_q),
	.m_axi_arready (ocl_sh_arready_q),
	.m_axi_rdata   (ocl_sh_rdata_q),
	.m_axi_rresp   (ocl_sh_rresp_q),
	.m_axi_rvalid  (ocl_sh_rvalid_q),
	.m_axi_rready  (sh_ocl_rready_q)
);

SECP256R1 #(
	.p_REGISTER_BIT_WIDTH(256),
	.p_PRIME_MODULUS(256'hFFFFFFFF_00000001_00000000_00000000_00000000_FFFFFFFF_FFFFFFFF_FFFFFFFF),
	.p_ORDER_n(256'hFFFFFFFF_00000000_FFFFFFFF_FFFFFFFF_BCE6FAAD_A7179E84_F3B9CAC2_FC632551),
	.p_CONSTANT_A(256'hFFFFFFFF_00000001_00000000_00000000_00000000_FFFFFFFF_FFFFFFFF_FFFFFFFC),
	.p_CONSTANT_B(256'h5AC635D8_AA3A93E7_B3EBBD55_769886BC_651D06B0_CC53B0F6_3BCE3C3E_27D2604B),
	.p_GX(256'h6B17D1F2_E12C4247_F8BCE6E5_63A440F2_77037D81_2DEB33A0_F4A13945_D898C296),
	.p_GY(256'h4FE342E2_FE1A7F9B_8EE7EB4A_7C0F9E16_2BCE3357_6B315ECE_CBB64068_37BF51F5)
) SECP256R1_DUT (
	.i_SYS_CLK(clk_main_a0),
	.i_RSTn(rst_main_n),

	.i_EX_SECP256R1_EN(start_pulse),
	.o_SECP256R1_EX_DONE(w_SECP256R1_EX_DONE),

	.i_EX_SECP256R1_RANDOMED_PRIVATE_KEY({
		reg_pvk_8, 
		reg_pvk_7, 
		reg_pvk_6, 
		reg_pvk_5, 
		reg_pvk_4, 
		reg_pvk_3, 
		reg_pvk_2, 
		reg_pvk_1
	}),
	.o_EX_SECP256R1_PUBLIC_KEY_X_OR_SIGNATURE_r(w_EX_SECP256R1_PUBLIC_KEY_X_OR_SIGNATURE_r),
	.o_EX_SECP256R1_PUBLIC_KEY_Y_OR_SIGNATURE_s(w_EX_SECP256R1_PUBLIC_KEY_Y_OR_SIGNATURE_s)
);

//-------------------------------------------------
// AXI-lite Handshake & FSM
//-------------------------------------------------

	// Handshake signals
	always_comb begin
		addr_wr_handshake = sh_ocl_awvalid_q && ocl_sh_awready_q;
		data_wr_handshake = sh_ocl_wvalid_q  && ocl_sh_wready_q;
		bresp_handshake   = ocl_sh_bvalid_q  && sh_ocl_bready_q;
		addr_rd_handshake = sh_ocl_arvalid_q && ocl_sh_arready_q;
		data_rd_handshake = ocl_sh_rvalid_q  && sh_ocl_rready_q;
	end

	// FSM next state logic
	always_comb begin
		next_state = current_state;
		case (current_state)
			IDLE: begin
				if (addr_wr_handshake && data_wr_handshake)
					next_state = WRITE;
				else if (addr_wr_handshake || data_wr_handshake)
					next_state = WRITE_WAIT;
				else if (addr_rd_handshake)
					next_state = READ;
			end

			WRITE_WAIT: begin
				if (addr_wr_handshake || data_wr_handshake)
					next_state = WRITE;
			end

			WRITE: begin
				next_state = WRITE_RESP;
			end

			WRITE_RESP: begin
				if (bresp_handshake)
					next_state = IDLE;
			end

			READ: begin
				if (data_rd_handshake)
					next_state = IDLE;
			end

			default: begin
				next_state = IDLE;
			end
		endcase
	end

	// FSM state register
	always_ff @(posedge clk_main_a0) begin
		if (!rst_main_n)
			current_state <= IDLE;
		else
			current_state <= next_state;
	end

//============================================
// AXI-lite CONTROL PATH
//============================================

	// Address capture
	always_ff @(posedge clk_main_a0) begin
		if (addr_wr_handshake)
			write_addr <= sh_ocl_awaddr_q;

		if (addr_rd_handshake)
			read_addr <= sh_ocl_araddr_q;
	end

	// AXI-Lite output signals
	always_ff @(posedge clk_main_a0) begin
		if (!rst_main_n) begin
			ocl_sh_awready_q <= 1'b1;
			ocl_sh_wready_q  <= 1'b1;
			ocl_sh_bvalid_q  <= 1'b0;
			ocl_sh_bresp_q   <= 2'b00;
			ocl_sh_arready_q <= 1'b1;
			ocl_sh_rvalid_q  <= 1'b0;
			ocl_sh_rresp_q   <= 2'b00;
		end
		else begin
			ocl_sh_awready_q <= (next_state == IDLE) || (next_state == WRITE_WAIT);
			ocl_sh_wready_q  <= (next_state == IDLE) || (next_state == WRITE_WAIT);
			ocl_sh_bvalid_q  <= (next_state == WRITE_RESP);
			ocl_sh_bresp_q   <= `AXI_RESP_OKAY;
			ocl_sh_arready_q <= (next_state == IDLE);
			ocl_sh_rvalid_q  <= (next_state == READ);
			ocl_sh_rresp_q   <= `AXI_RESP_OKAY;
		end
	end

//============================================
// AXI-lite DATA PATH
//============================================

	// Register writes
	always_ff @(posedge clk_main_a0) begin
		if (!rst_main_n) begin
			reg_pvk_1 <= 32'h0;
			reg_pvk_2 <= 32'h0;
			reg_pvk_3 <= 32'h0;
			reg_pvk_4 <= 32'h0;
			reg_pvk_5 <= 32'h0;
			reg_pvk_6 <= 32'h0;
			reg_pvk_7 <= 32'h0;
			reg_pvk_8 <= 32'h0;
		end else begin
			if (next_state == WRITE) begin
				case (write_addr)
					`ADDR_RANDOMED_PRIVATE_KEY_1 : reg_pvk_1 <= sh_ocl_wdata_q;
					`ADDR_RANDOMED_PRIVATE_KEY_2 : reg_pvk_2 <= sh_ocl_wdata_q;
					`ADDR_RANDOMED_PRIVATE_KEY_3 : reg_pvk_3 <= sh_ocl_wdata_q;
					`ADDR_RANDOMED_PRIVATE_KEY_4 : reg_pvk_4 <= sh_ocl_wdata_q;
					`ADDR_RANDOMED_PRIVATE_KEY_5 : reg_pvk_5 <= sh_ocl_wdata_q;
					`ADDR_RANDOMED_PRIVATE_KEY_6 : reg_pvk_6 <= sh_ocl_wdata_q;
					`ADDR_RANDOMED_PRIVATE_KEY_7 : reg_pvk_7 <= sh_ocl_wdata_q;
					`ADDR_RANDOMED_PRIVATE_KEY_8 : reg_pvk_8 <= sh_ocl_wdata_q;
				endcase
			end
		end
	end

	// Register reads
	always_ff @(posedge clk_main_a0) begin
		if (addr_rd_handshake) begin
			case (sh_ocl_araddr_q)
				`ADDR_RANDOMED_PRIVATE_KEY_1 : ocl_sh_rdata_q <= reg_pvk_1;
				`ADDR_RANDOMED_PRIVATE_KEY_2 : ocl_sh_rdata_q <= reg_pvk_2;
				`ADDR_RANDOMED_PRIVATE_KEY_3 : ocl_sh_rdata_q <= reg_pvk_3;
				`ADDR_RANDOMED_PRIVATE_KEY_4 : ocl_sh_rdata_q <= reg_pvk_4;
				`ADDR_RANDOMED_PRIVATE_KEY_5 : ocl_sh_rdata_q <= reg_pvk_5;
				`ADDR_RANDOMED_PRIVATE_KEY_6 : ocl_sh_rdata_q <= reg_pvk_6;
				`ADDR_RANDOMED_PRIVATE_KEY_7 : ocl_sh_rdata_q <= reg_pvk_7;
				`ADDR_RANDOMED_PRIVATE_KEY_8 : ocl_sh_rdata_q <= reg_pvk_8;

				`ADDR_PUBLIC_KEY_X_1         : ocl_sh_rdata_q <= reg_pbk_x_1;
				`ADDR_PUBLIC_KEY_X_2		 : ocl_sh_rdata_q <= reg_pbk_x_2;
				`ADDR_PUBLIC_KEY_X_3		 : ocl_sh_rdata_q <= reg_pbk_x_3;
				`ADDR_PUBLIC_KEY_X_4		 : ocl_sh_rdata_q <= reg_pbk_x_4;
				`ADDR_PUBLIC_KEY_X_5		 : ocl_sh_rdata_q <= reg_pbk_x_5;
				`ADDR_PUBLIC_KEY_X_6		 : ocl_sh_rdata_q <= reg_pbk_x_6;
				`ADDR_PUBLIC_KEY_X_7		 : ocl_sh_rdata_q <= reg_pbk_x_7;
				`ADDR_PUBLIC_KEY_X_8		 : ocl_sh_rdata_q <= reg_pbk_x_8;
				
				`ADDR_PUBLIC_KEY_Y_1         : ocl_sh_rdata_q <= reg_pbk_y_1;
				`ADDR_PUBLIC_KEY_Y_2		 : ocl_sh_rdata_q <= reg_pbk_y_2;
				`ADDR_PUBLIC_KEY_Y_3		 : ocl_sh_rdata_q <= reg_pbk_y_3;
				`ADDR_PUBLIC_KEY_Y_4		 : ocl_sh_rdata_q <= reg_pbk_y_4;
				`ADDR_PUBLIC_KEY_Y_5		 : ocl_sh_rdata_q <= reg_pbk_y_5;
				`ADDR_PUBLIC_KEY_Y_6		 : ocl_sh_rdata_q <= reg_pbk_y_6;
				`ADDR_PUBLIC_KEY_Y_7		 : ocl_sh_rdata_q <= reg_pbk_y_7;
				`ADDR_PUBLIC_KEY_Y_8		 : ocl_sh_rdata_q <= reg_pbk_y_8;

				`ADDR_CONTROL_STATUS         : ocl_sh_rdata_q <= reg_control_status;
				default                      : ocl_sh_rdata_q <= `INVALID_ADDR_RESP;
			endcase
		end
	end

//============================================
// APPLICATION LOGIC
//============================================

	// Start pulse generation
	always_ff @(posedge clk_main_a0) begin
		start_pulse <= 1'b0;
		if (current_state == WRITE)
			start_pulse <= (write_addr == `ADDR_CONTROL_STATUS) && sh_ocl_wdata_q[0];
	end

	always_ff @(posedge clk_main_a0) begin
		if (!rst_main_n) begin
			reg_pbk_x_1 <= 32'h0;
			reg_pbk_x_2 <= 32'h0;
			reg_pbk_x_3 <= 32'h0;
			reg_pbk_x_4 <= 32'h0;
			reg_pbk_x_5 <= 32'h0;
			reg_pbk_x_6 <= 32'h0;
			reg_pbk_x_7 <= 32'h0;
			reg_pbk_x_8 <= 32'h0;

			reg_pbk_y_1 <= 32'h0;
			reg_pbk_y_2 <= 32'h0;
			reg_pbk_y_3 <= 32'h0;
			reg_pbk_y_4 <= 32'h0;
			reg_pbk_y_5 <= 32'h0;
			reg_pbk_y_6 <= 32'h0;
			reg_pbk_y_7 <= 32'h0;
			reg_pbk_y_8 <= 32'h0;
		end
		// else if (start_pulse)
		// 	{reg_carry[0], reg_sum} <= reg_pk_1 + reg_pk_2;
		else begin
			reg_pbk_x_1 <= w_EX_SECP256R1_PUBLIC_KEY_X_OR_SIGNATURE_r[31:0];
			reg_pbk_x_2 <= w_EX_SECP256R1_PUBLIC_KEY_X_OR_SIGNATURE_r[63:32];
			reg_pbk_x_3 <= w_EX_SECP256R1_PUBLIC_KEY_X_OR_SIGNATURE_r[95:64];
			reg_pbk_x_4 <= w_EX_SECP256R1_PUBLIC_KEY_X_OR_SIGNATURE_r[127:96];
			reg_pbk_x_5 <= w_EX_SECP256R1_PUBLIC_KEY_X_OR_SIGNATURE_r[159:128];
			reg_pbk_x_6 <= w_EX_SECP256R1_PUBLIC_KEY_X_OR_SIGNATURE_r[191:160];
			reg_pbk_x_7 <= w_EX_SECP256R1_PUBLIC_KEY_X_OR_SIGNATURE_r[223:192];
			reg_pbk_x_8 <= w_EX_SECP256R1_PUBLIC_KEY_X_OR_SIGNATURE_r[255:224];

			reg_pbk_y_1 <= w_EX_SECP256R1_PUBLIC_KEY_Y_OR_SIGNATURE_s[31:0];
			reg_pbk_y_2 <= w_EX_SECP256R1_PUBLIC_KEY_Y_OR_SIGNATURE_s[63:32];
			reg_pbk_y_3 <= w_EX_SECP256R1_PUBLIC_KEY_Y_OR_SIGNATURE_s[95:64];
			reg_pbk_y_4 <= w_EX_SECP256R1_PUBLIC_KEY_Y_OR_SIGNATURE_s[127:96];
			reg_pbk_y_5 <= w_EX_SECP256R1_PUBLIC_KEY_Y_OR_SIGNATURE_s[159:128];
			reg_pbk_y_6 <= w_EX_SECP256R1_PUBLIC_KEY_Y_OR_SIGNATURE_s[191:160];
			reg_pbk_y_7 <= w_EX_SECP256R1_PUBLIC_KEY_Y_OR_SIGNATURE_s[223:192];
			reg_pbk_y_8 <= w_EX_SECP256R1_PUBLIC_KEY_Y_OR_SIGNATURE_s[255:224];
		end
	end

	// Ready flag
	always_ff @(posedge clk_main_a0) begin
		if (w_SECP256R1_EX_DONE)
			ready_flag <= 1'b1;
		else if (
			reg_pbk_x_1_read_flag && 
			reg_pbk_x_2_read_flag &&
			reg_pbk_x_3_read_flag &&
			reg_pbk_x_4_read_flag &&
			reg_pbk_x_5_read_flag &&
			reg_pbk_x_6_read_flag &&
			reg_pbk_x_7_read_flag &&
			reg_pbk_x_8_read_flag &&

			reg_pbk_y_1_read_flag &&
			reg_pbk_y_2_read_flag &&
			reg_pbk_y_3_read_flag &&
			reg_pbk_y_4_read_flag &&
			reg_pbk_y_5_read_flag &&
			reg_pbk_y_6_read_flag &&
			reg_pbk_y_7_read_flag &&
			reg_pbk_y_8_read_flag
		)
			ready_flag <= 1'b0;
	end

	// Read flags
	always_ff @(posedge clk_main_a0) begin
		if (start_pulse) begin
			reg_pbk_x_1_read_flag <= 1'b0;
			reg_pbk_x_2_read_flag <= 1'b0;
			reg_pbk_x_3_read_flag <= 1'b0;
			reg_pbk_x_4_read_flag <= 1'b0;
			reg_pbk_x_5_read_flag <= 1'b0;
			reg_pbk_x_6_read_flag <= 1'b0;
			reg_pbk_x_7_read_flag <= 1'b0;
			reg_pbk_x_8_read_flag <= 1'b0;

			reg_pbk_y_1_read_flag <= 1'b0;
			reg_pbk_y_2_read_flag <= 1'b0;
			reg_pbk_y_3_read_flag <= 1'b0;
			reg_pbk_y_4_read_flag <= 1'b0;
			reg_pbk_y_5_read_flag <= 1'b0;
			reg_pbk_y_6_read_flag <= 1'b0;
			reg_pbk_y_7_read_flag <= 1'b0;
			reg_pbk_y_8_read_flag <= 1'b0;
		end
		else if (addr_rd_handshake) begin
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_X_1)
				reg_pbk_x_1_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_X_2)
				reg_pbk_x_2_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_X_3)
				reg_pbk_x_3_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_X_4)
				reg_pbk_x_4_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_X_5)
				reg_pbk_x_5_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_X_6)
				reg_pbk_x_6_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_X_7)
				reg_pbk_x_7_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_X_8)
				reg_pbk_x_8_read_flag <= 1'b1;

			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_Y_1)
				reg_pbk_y_1_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_Y_2)
				reg_pbk_y_2_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_Y_3)
				reg_pbk_y_3_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_Y_4)
				reg_pbk_y_4_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_Y_5)
				reg_pbk_y_5_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_Y_6)
				reg_pbk_y_6_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_Y_7)
				reg_pbk_y_7_read_flag <= 1'b1;
			if (sh_ocl_araddr_q == `ADDR_PUBLIC_KEY_Y_8)
				reg_pbk_y_8_read_flag <= 1'b1;
		end
	end

	// Control/status register
	always_ff @(posedge clk_main_a0) begin
		if (!rst_main_n)
			reg_control_status <= 32'h0;
		else
			reg_control_status <= {30'h0, ready_flag, start_pulse};
	end

//-------------------------------------
// Debug Bridge
//-------------------------------------

`ifndef SIMULATION
cl_debug_bridge CL_DEBUG_BRIDGE (
	.clk                (clk_main_a0),
	.S_BSCAN_drck       (drck),
	.S_BSCAN_shift      (shift),
	.S_BSCAN_tdi        (tdi),
	.S_BSCAN_update     (update),
	.S_BSCAN_sel        (sel),
	.S_BSCAN_tdo        (tdo),
	.S_BSCAN_tms        (tms),
	.S_BSCAN_tck        (tck),
	.S_BSCAN_runtest    (runtest),
	.S_BSCAN_reset      (reset),
	.S_BSCAN_capture    (capture),
	.S_BSCAN_bscanid_en (bscanid_en)
);
`endif // SIMULATION

`ifndef NO_CL_AXIL_DEBUG_ILA

ila_axil OCL_AXIL_ILA (
	.clk     (clk_main_a0),
	.probe0  (sh_ocl_awaddr_q),
	.probe1  (sh_ocl_awvalid_q),
	.probe2  (ocl_sh_awready_q),
	.probe3  (sh_ocl_wdata_q),
	.probe4  (sh_ocl_wstrb_q),
	.probe5  (sh_ocl_wvalid_q),
	.probe6  (ocl_sh_wready_q),
	.probe7  (ocl_sh_bresp_q),
	.probe8  (ocl_sh_bvalid_q),
	.probe9  (sh_ocl_bready_q),
	.probe10 (sh_ocl_araddr_q),
	.probe11 (sh_ocl_arvalid_q),
	.probe12 (ocl_sh_arready_q),
	.probe13 (ocl_sh_rdata_q),
	.probe14 (ocl_sh_rresp_q),
	.probe15 (ocl_sh_rvalid_q),
	.probe16 (sh_ocl_rready_q)
);

`endif // NO_CL_AXIL_DEBUG_ILA

endmodule
