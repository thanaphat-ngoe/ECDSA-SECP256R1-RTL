// --------------------------------------------------------------------------------
// NAMING CONVENTION FOR SIGNALS BETWEEN MODULES:
// --------------------------------------------------------------------------------
// 1. INPUT  Signals: i_<SRC_MODULE>_<DEST_MODULE>_<SIGNAL_NAME>
// 2. OUTPUT Signals: o_<SRC_MODULE>_<DEST_MODULE>_<SIGNAL_NAME>
// --------------------------------------------------------------------------------

module MODULAR_INVERSE #(
    parameter p_REGISTER_BIT_WIDTH = 256
) (
    input  logic                            i_SYS_CLK,
    input  logic                            i_RSTn,
    
    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_FIELDARITH_MODINV_OPERAND_A,
    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_FIELDARITH_MODINV_OPERAND_B,
    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_FIELDARITH_MODINV_MODULUS,
    
    output logic [p_REGISTER_BIT_WIDTH-1:0] o_MODINV_FIELDARITH_RESULT,
    input  logic                            i_FIELDARITH_MODINV_EN,
    output logic                            o_MODINV_FIELDARITH_DONE
);

    logic [p_REGISTER_BIT_WIDTH+3:0] r_U, r_V, r_X, r_Y;
    
    logic [p_REGISTER_BIT_WIDTH+3:0] w_p, w_mm;
    logic [p_REGISTER_BIT_WIDTH+3:0] w_tu, w_tx, w_tv, w_ty, w_tuv;
    logic [p_REGISTER_BIT_WIDTH+3:0] w_uv2, w_uv4, w_uv8, w_uv;
    logic [p_REGISTER_BIT_WIDTH+3:0] w_m2, w_m4, w_m3, w_m5, w_m6;
    logic [p_REGISTER_BIT_WIDTH+3:0] w_tz2, w_tz4, w_tz8, w_tz;
    logic [p_REGISTER_BIT_WIDTH+3:0] w_txy, w_txy2, w_txy4, w_txy8, w_xy;
    logic [p_REGISTER_BIT_WIDTH+3:0] w_xpp, w_result;
    
    logic [2:0] w_t3;
    logic       w_equ; 
    
    assign w_p      = {4'h0, i_FIELDARITH_MODINV_MODULUS};
    assign w_mm     = {4'hf, ~i_FIELDARITH_MODINV_MODULUS[255:1], 1'b1};
    
    assign w_tu     = r_V[0]   ? r_U : 0;
    assign w_tx     = r_V[0]   ? r_X : 0;
    assign w_tv     = r_U[0]   ? r_V : 0;
    assign w_ty     = r_U[0]   ? r_Y : 0;
    
    assign w_tuv    = w_tu + w_tv;
    assign w_uv2    = {w_tuv[259], w_tuv[259:1]};
    assign w_uv4    = {{2{w_tuv[259]}}, w_tuv[259:2]};
    assign w_uv8    = {{3{w_tuv[259]}}, w_tuv[259:3]};
    assign w_uv     = w_tuv[1] ? w_uv2 : w_tuv[2] ? w_uv4 : w_uv8;
    
    assign w_t3     = w_tx[2:0] + w_ty[2:0];
    assign w_equ    = w_t3[1:0] == w_p[1:0];
    
    assign w_m2     = {w_p[258:0], 1'b0};
    assign w_m4     = {w_p[257:0], 2'b0};
    assign w_m3     = w_m2 + w_p;
    assign w_m5     = w_m4 + w_p;
    assign w_m6     = w_m4 + w_m2;
    
    assign w_tz2    = w_t3[0]  ? (w_tx[259] | w_ty[259]) ? w_p : w_mm : 260'h0;
    assign w_tz4    = w_t3[0]  ? w_equ ? w_mm : w_p : w_t3[1] ? w_m2 : 260'h0;
    assign w_tz8    = w_t3[0]  ? w_t3[2:1] == w_p[2:1] ? w_mm : w_t3[1] == w_p[1] ? w_m3 : w_t3[2] != w_p[2] ? i_FIELDARITH_MODINV_MODULUS : w_m5 : w_t3[1] ? w_t3[2] == w_p[1] ? w_m6 : w_m2 : w_t3[2] ? w_m4 : 260'h0;
    assign w_tz     = w_tuv[1] ? w_tz2 : w_tuv[2] ? w_tz4 : w_tz8;
    
    assign w_txy    = w_tx + w_ty + w_tz;
    assign w_txy2   = {w_txy[259], w_txy[259:1]};
    assign w_txy4   = {{2{w_txy[259]}}, w_txy[259:2]};
    assign w_txy8   = {{3{w_txy[259]}}, w_txy[259:3]};
    assign w_xy     = w_tuv[1] ? w_txy2 : w_tuv[2] ? w_txy4 : w_txy8;
    
    assign w_xpp    = r_X + w_p;
    assign w_result = r_X[259] ? w_xpp : r_X;

    assign o_MODINV_FIELDARITH_RESULT = w_result[255:0];
    
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        LOAD    = 2'b01,
        COMPUTE = 2'b10, 
        FINISH  = 2'b11
    } modular_inverse_state_enum;
    
    modular_inverse_state_enum r_STATE;

    always @(posedge i_SYS_CLK or negedge i_RSTn) begin
        if (!i_RSTn) begin
            o_MODINV_FIELDARITH_DONE <= 0;
            r_U     <= '0;
            r_V     <= '0;
            r_X     <= '0;   
            r_Y     <= '0;
            r_STATE <= IDLE; 
        end else begin
            o_MODINV_FIELDARITH_DONE <= 0;

            case(r_STATE)
                IDLE: begin
                    if (i_FIELDARITH_MODINV_EN == 1 && o_MODINV_FIELDARITH_DONE == 0) begin
                        r_STATE <= LOAD;
                    end else begin
                        r_STATE <= IDLE;
                    end
                end

                LOAD: begin
                    r_U     <= {4'b0, i_FIELDARITH_MODINV_OPERAND_B};
                    r_V     <= w_mm;
                    r_X     <= {4'b0, i_FIELDARITH_MODINV_OPERAND_A};
                    r_Y     <= 260'b0;
                    r_STATE <= COMPUTE;
                end

                COMPUTE: begin
                    if (r_U == 1) begin
                        o_MODINV_FIELDARITH_DONE <= 1;
                        r_STATE <= FINISH;
                    end else begin
                        if (w_uv[259]) begin
                            r_V <= w_uv;
                            r_Y <= w_xy;
                        end else begin
                            r_U <= w_uv;
                            r_X <= w_xy;
                        end
                    end
                end

                FINISH: begin
                    r_STATE <= IDLE;
                end
            endcase 
        end
    end
endmodule
