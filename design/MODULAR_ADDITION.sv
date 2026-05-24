// --------------------------------------------------------------------------------
// NAMING CONVENTION FOR SIGNALS BETWEEN MODULES:
// --------------------------------------------------------------------------------
// 1. INPUT  Signals: i_<SRC_MODULE>_<DEST_MODULE>_<SIGNAL_NAME>
// 2. OUTPUT Signals: o_<SRC_MODULE>_<DEST_MODULE>_<SIGNAL_NAME>
// --------------------------------------------------------------------------------

module MODULAR_ADDITION #(
    parameter p_REGISTER_BIT_WIDTH = 256
) (
    input  logic                            i_SYS_CLK,
    input  logic                            i_RSTn,

    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_FIELDARITH_MODADD_OPERAND_A,
    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_FIELDARITH_MODADD_OPERAND_B,
    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_FIELDARITH_MODADD_MODULUS,
    
    output logic [p_REGISTER_BIT_WIDTH-1:0] o_MODADD_FIELDARITH_RESULT,
    input  logic                            i_FIELDARITH_MODADD_EN,
    output logic                            o_MODADD_FIELDARITH_DONE
);

    logic [p_REGISTER_BIT_WIDTH+1:0] sum;
    logic [p_REGISTER_BIT_WIDTH+1:0] s_m;

    typedef enum logic {
        IDLE = 1'b0,
        DONE = 1'b1
    } modular_addition_state_enum;
    
    modular_addition_state_enum st;

    assign sum = {2'b00, i_FIELDARITH_MODADD_OPERAND_A} + {2'b00, i_FIELDARITH_MODADD_OPERAND_B};
    assign s_m = sum - {2'b00, i_FIELDARITH_MODADD_MODULUS};
    assign o_MODADD_FIELDARITH_RESULT = s_m[257] ? sum[255:0] : s_m[255:0];

    always_ff @(posedge i_SYS_CLK or negedge i_RSTn) begin
        if (!i_RSTn) begin
            o_MODADD_FIELDARITH_DONE <= 0;
            st <= IDLE;
        end else begin
            o_MODADD_FIELDARITH_DONE <= 0;
            
            case(st)
                IDLE: begin
                    if (i_FIELDARITH_MODADD_EN == 1 && o_MODADD_FIELDARITH_DONE == 0) begin
                        o_MODADD_FIELDARITH_DONE <= 1;
                        st <= DONE;
                    end
                end

                DONE: begin
                    st <= IDLE;
                end
            endcase
        end
    end
endmodule
