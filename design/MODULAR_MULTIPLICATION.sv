// --------------------------------------------------------------------------------
// NAMING CONVENTION FOR SIGNALS BETWEEN MODULES:
// --------------------------------------------------------------------------------
// 1. INPUT  Signals: i_<SRC_MODULE>_<DEST_MODULE>_<SIGNAL_NAME>
// 2. OUTPUT Signals: o_<SRC_MODULE>_<DEST_MODULE>_<SIGNAL_NAME>
// --------------------------------------------------------------------------------

module MODULAR_MULTIPLICATION #(
    parameter p_REGISTER_BIT_WIDTH = 256
) (
    input  logic                            i_SYS_CLK,
    input  logic                            i_RSTn,

    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_FIELDARITH_MODMUL_OPERAND_A,
    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_FIELDARITH_MODMUL_OPERAND_B, 
    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_FIELDARITH_MODMUL_MODULUS,

    output logic [p_REGISTER_BIT_WIDTH-1:0] o_MODMUL_FIELDARITH_RESULT,
    input  logic                            i_FIELDARITH_MODMUL_EN,
    output logic                            o_MODMUL_FIELDARITH_DONE
);

    logic [7:0]                        r_CNT;
    logic [7:0]                        w_NEXT_CNT;
    
    logic [p_REGISTER_BIT_WIDTH+1:0]   r_U;
    logic [p_REGISTER_BIT_WIDTH+1:0]   r_S;
    
    logic                              w_BI_IS_1;
    logic [p_REGISTER_BIT_WIDTH+1:0]   w_PLUS_U;
    logic [p_REGISTER_BIT_WIDTH+1:0]   w_MINUS_M;
    logic [p_REGISTER_BIT_WIDTH+1:0]   w_NEW_S;
    logic [p_REGISTER_BIT_WIDTH+1:0]   w_TWO_U;
    logic [p_REGISTER_BIT_WIDTH+1:0]   w_TWO_U_M;
    logic [p_REGISTER_BIT_WIDTH+1:0]   w_NEW_U;
    logic                              r_LOADED;
    
    assign w_BI_IS_1                  = i_FIELDARITH_MODMUL_OPERAND_B[r_CNT];
    assign w_NEXT_CNT                 = r_CNT + 8'd1;
    assign w_PLUS_U                   = r_S + r_U;
    assign w_MINUS_M                  = w_PLUS_U - {2'b00, i_FIELDARITH_MODMUL_MODULUS};
    assign w_NEW_S                    = w_BI_IS_1 ? (w_MINUS_M[p_REGISTER_BIT_WIDTH+1] ? w_PLUS_U : w_MINUS_M) : r_S;
    assign w_TWO_U                    = {r_U[p_REGISTER_BIT_WIDTH:0], 1'b0};
    assign w_TWO_U_M                  = w_TWO_U - {2'b00, i_FIELDARITH_MODMUL_MODULUS};
    assign w_NEW_U                    = w_TWO_U_M[p_REGISTER_BIT_WIDTH+1] ? w_TWO_U : w_TWO_U_M;
    
    assign o_MODMUL_FIELDARITH_RESULT = r_S[p_REGISTER_BIT_WIDTH-1:0];

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        LOAD    = 2'b01, 
        COMPUTE = 2'b10,
        FINISH  = 2'b11
    } modular_multiplication_state_enum;
    
    modular_multiplication_state_enum r_STATE;

    always_ff @(posedge i_SYS_CLK or negedge i_RSTn) begin
        if (!i_RSTn) begin
            o_MODMUL_FIELDARITH_DONE <= 0;
            r_U                      <= 0;
            r_S                      <= 0;
            r_CNT                    <= 0;
            r_LOADED                 <= 0;
            r_STATE                  <= IDLE;
        end else begin
            o_MODMUL_FIELDARITH_DONE <= 0;

            case(r_STATE)
                IDLE: begin
                    if (i_FIELDARITH_MODMUL_EN == 1 && o_MODMUL_FIELDARITH_DONE == 0) begin
                        r_STATE <= LOAD;
                    end else begin
                        r_STATE <= IDLE;
                    end
                end

                LOAD: begin
                    r_U     <= {2'b00, i_FIELDARITH_MODMUL_OPERAND_A};
                    r_S     <= 0; 
                    r_CNT   <= 0;
                    r_STATE <= COMPUTE;
                end

                COMPUTE: begin
                    r_S <= w_NEW_S;
                    if (r_CNT == 8'd255) begin
                        o_MODMUL_FIELDARITH_DONE <= 1;
                        r_STATE                  <= FINISH;
                    end else begin
                        r_U     <= w_NEW_U;
                        r_CNT   <= w_NEXT_CNT;
                        r_STATE <= COMPUTE;
                    end
                end

                FINISH: begin
                    r_STATE <= IDLE;
                end
            endcase
        end
    end
endmodule
