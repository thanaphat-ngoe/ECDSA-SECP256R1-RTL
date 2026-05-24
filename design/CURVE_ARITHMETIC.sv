// --------------------------------------------------------------------------------
// NAMING CONVENTION FOR SIGNALS BETWEEN MODULES:
// --------------------------------------------------------------------------------
// 1. INPUT  Signals: i_<SRC_MODULE>_<DEST_MODULE>_<SIGNAL_NAME>
// 2. OUTPUT Signals: o_<SRC_MODULE>_<DEST_MODULE>_<SIGNAL_NAME>
// --------------------------------------------------------------------------------

module CURVE_ARITHMETIC #(
    parameter p_REGISTER_BIT_WIDTH = 256,
    // --------------------------------------------------------------------------------
    // RECOMMENDED 256-BIT ELLIPTIC CURVE DOMAIN PARAMETERS OVER Fp (SECP256R1)
    // --------------------------------------------------------------------------------
    parameter p_PRIME_MODULUS      = 256'hFFFFFFFF_00000001_00000000_00000000_00000000_FFFFFFFF_FFFFFFFF_FFFFFFFF,
    parameter p_ORDER_n            = 256'hFFFFFFFF_00000000_FFFFFFFF_FFFFFFFF_BCE6FAAD_A7179E84_F3B9CAC2_FC632551,
    parameter p_CONSTANT_A         = 256'hFFFFFFFF_00000001_00000000_00000000_00000000_FFFFFFFF_FFFFFFFF_FFFFFFFC,
    parameter p_CONSTANT_B         = 256'h5AC635D8_AA3A93E7_B3EBBD55_769886BC_651D06B0_CC53B0F6_3BCE3C3E_27D2604B,
    // BASE POINT G
    parameter p_GX                 = 256'h6B17D1F2_E12C4247_F8BCE6E5_63A440F2_77037D81_2DEB33A0_F4A13945_D898C296,
    parameter p_GY                 = 256'h4FE342E2_FE1A7F9B_8EE7EB4A_7C0F9E16_2BCE3357_6B315ECE_CBB64068_37BF51F5
    // --------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------
) (
    // --------------------------------------------------------------------------------
    // SYSTEM SIGNALS INTERFACE
    // --------------------------------------------------------------------------------
    input  logic                            i_SYS_CLK,
    input  logic                            i_RSTn,

    // --------------------------------------------------------------------------------
    // I/O FOR CURVE OPERATIONS WHICH ARE ROUTING BY SECP256R1 TOP MODULE
    // --------------------------------------------------------------------------------
    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_SECP256R1_CURVE_SCALAR,
    // input  logic [p_REGISTER_BIT_WIDTH-1:0] i_SECP256R1_CURVE_POINT_PX,
    // input  logic [p_REGISTER_BIT_WIDTH-1:0] i_SECP256R1_CURVE_POINT_PY,
    output logic [p_REGISTER_BIT_WIDTH-1:0] o_CURVE_SECP256R1_POINT_RX,
    output logic [p_REGISTER_BIT_WIDTH-1:0] o_CURVE_SECP256R1_POINT_RY,          
    
    // input  logic                            i_SECP256R1_CURVE_OP_SEL, // 0: POINT ADDITION 1: SCALAR MULTIPLICATION
    input  logic                            i_SECP256R1_CURVE_EN,
    output logic                            o_CURVE_SECP256R1_DONE,

    // --------------------------------------------------------------------------------
    // I/O FOR FIELD ARITHMETIC OPERATIONS WHICH ARE ROUTING BY SECP256R1 TOP MODULE
    // --------------------------------------------------------------------------------
    output logic [p_REGISTER_BIT_WIDTH-1:0] o_CURVE_SECP256R1_FIELD_OPERAND_A,   
    output logic [p_REGISTER_BIT_WIDTH-1:0] o_CURVE_SECP256R1_FIELD_OPERAND_B,
    output logic [p_REGISTER_BIT_WIDTH-1:0] o_CURVE_SECP256R1_FIELD_MODULUS,
    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_SECP256R1_CURVE_FIELD_OP_RESULT,
    
    output logic [1:0]                      o_CURVE_SECP256R1_FIELD_OP_SEL,
    output logic                            o_CURVE_SECP256R1_FIELD_OP_EN,
    input  logic                            i_SECP256R1_CURVE_FIELD_OP_DONE
);

    localparam MADD = 4'h0,
               MSUB = 4'h1,
               MMUL = 4'h2,
               MINV = 4'h3,
               DONE = 4'hF;

    localparam R0  = 4'h0,
               R1  = 4'h1,
               R2  = 4'h2,
               R3  = 4'h3,
               R4  = 4'h4,
               R5  = 4'h5,
               R6  = 4'h6,
               R7  = 4'h7,
               R8  = 4'h8,
               R9  = 4'h9;

    // --------------------------------------------------------------------------------
    // INTERNAL SIGNALS DECLARATION SECTION
    // --------------------------------------------------------------------------------
    typedef enum logic [1:0] { 
        IDLE           = 2'b00,
        POINT_ADDITION = 2'b01,
        POINT_DOUBLING = 2'b10,
        CURVE_DONE     = 2'b11
    } curve_arithmetic_state_enum;

    curve_arithmetic_state_enum r_STATE;

    logic [p_REGISTER_BIT_WIDTH-1:0] r_k;

    logic [p_REGISTER_BIT_WIDTH-1:0] r_REG_FILE [0:9];

    logic [3:0] r_POINT_ADDITION_LOOKUP_TABLE_ADDR;
    logic [3:0] r_POINT_DOUBLING_LOOKUP_TABLE_ADDR;

    logic [15:0] w_IMEM;

    logic r_PA_STATE_FIELD_OP_EN;
    logic r_PD_STATE_FIELD_OP_EN;
    // --------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------

    // --------------------------------------------------------------------------------
    // SIGNAL ASSIGNMENTS SECTION
    // --------------------------------------------------------------------------------
    assign o_CURVE_SECP256R1_POINT_RX = r_REG_FILE[0];
    assign o_CURVE_SECP256R1_POINT_RY = r_REG_FILE[1];
    assign o_CURVE_SECP256R1_FIELD_MODULUS = p_PRIME_MODULUS;
    // --------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------

    // --------------------------------------------------------------------------------
    // COMBINATIONAL LOGIC SECTION
    // --------------------------------------------------------------------------------
    // POINT ADDITION INSTRUCTIONS & POINT DOUBLING INSTRUCTIONS LOOKUP TABLE
    always_comb begin
        // DEFAULT VALUES FOR PREVENTING UNINTENTIONAL LATCHES
        w_IMEM = '0;
        case (r_STATE)
            POINT_ADDITION: begin
                case (r_POINT_ADDITION_LOOKUP_TABLE_ADDR)
                    4'h0: w_IMEM = {R4, R3, R1, MSUB}; // DEST: R4 | SRC1: R3 | SRC2: R1 | OP: SUB
                    4'h1: w_IMEM = {R5, R2, R0, MSUB}; // DEST: R5 | SRC1: R2 | SRC2: R0 | OP: SUB
                    4'h2: w_IMEM = {R4, R4, R5, MINV}; // DEST: R4 | SRC1: R4 | SRC2: R5 | OP: INV
                    4'h3: w_IMEM = {R5, R4, R4, MMUL}; // DEST: R5 | SRC1: R4 | SRC2: R4 | OP: MUL
                    4'h4: w_IMEM = {R6, R5, R0, MSUB}; // DEST: R6 | SRC1: R5 | SRC2: R0 | OP: SUB
                    4'h5: w_IMEM = {R6, R6, R2, MSUB}; // DEST: R6 | SRC1: R6 | SRC2: R2 | OP: SUB
                    4'h6: w_IMEM = {R7, R0, R6, MSUB}; // DEST: R7 | SRC1: R0 | SRC2: R6 | OP: SUB
                    4'h7: w_IMEM = {R7, R4, R7, MMUL}; // DEST: R7 | SRC1: R4 | SRC2: R7 | OP: MUL
                    4'h8: w_IMEM = {R7, R7, R1, MSUB}; // DEST: R7 | SRC1: R7 | SRC2: R1 | OP: SUB
                    4'h9: w_IMEM = {R0, R0, R0, DONE};
                endcase
            end

            POINT_DOUBLING: begin
                case (r_POINT_DOUBLING_LOOKUP_TABLE_ADDR)
                    4'h0: w_IMEM = {R4, R2, R2, MMUL}; // DEST: R4 | SRC1: R2 | SRC2: R2 | OP: MUL
                    4'h1: w_IMEM = {R4, R9, R4, MMUL}; // DEST: R4 | SRC1: R9 | SRC2: R4 | OP: MUL CONST 3
                    4'h2: w_IMEM = {R4, R4, R8, MADD}; // DEST: R4 | SRC1: R4 | SRC2: R8 | OP: ADD CONST A
                    4'h3: w_IMEM = {R5, R3, R3, MADD}; // DEST: R4 | SRC1: R3 | SRC2: R3 | OP: ADD
                    4'h4: w_IMEM = {R4, R4, R5, MINV}; // DEST: R4 | SRC1: R3 | SRC2: R3 | OP: INV (Slope at R4)
                    4'h5: w_IMEM = {R5, R4, R4, MMUL}; // DEST: R5 | SRC1: R4 | SRC2: R4 | OP: MUL (Slope Square at R5)
                    4'h6: w_IMEM = {R6, R5, R2, MSUB}; // DEST: R6 | SRC1: R5 | SRC2: R2 | OP: SUB
                    4'h7: w_IMEM = {R6, R6, R2, MSUB}; // DEST: R6 | SRC1: R6 | SRC2: R2 | OP: SUB
                    4'h8: w_IMEM = {R7, R2, R6, MSUB}; // DEST: R6 | SRC1: R5 | SRC2: R2 | OP: SUB
                    4'h9: w_IMEM = {R7, R4, R7, MMUL}; // DEST: R7 | SRC1: R4 | SRC2: R7 | OP: MUL
                    4'hA: w_IMEM = {R7, R7, R3, MSUB}; // DEST: R7 | SRC1: R4 | SRC2: R7 | OP: SUB
                    4'hB: w_IMEM = {R0, R0, R0, DONE};
                endcase
            end

            default: begin
                w_IMEM = '0;
            end
        endcase
    end

    always_comb begin
        // DEFAULT VALUES FOR PREVENTING UNINTENTIONAL LATCHES
        o_CURVE_SECP256R1_FIELD_OPERAND_A = r_REG_FILE[w_IMEM[11:8]];
        o_CURVE_SECP256R1_FIELD_OPERAND_B = r_REG_FILE[w_IMEM[7:4]];
        o_CURVE_SECP256R1_FIELD_OP_SEL = w_IMEM[1:0];
        o_CURVE_SECP256R1_FIELD_OP_EN = 0;
        case(r_STATE)
            IDLE: begin
                o_CURVE_SECP256R1_FIELD_OPERAND_A = 256'h0;
                o_CURVE_SECP256R1_FIELD_OPERAND_B = 256'h0;
                o_CURVE_SECP256R1_FIELD_OP_SEL = 2'b00;
                o_CURVE_SECP256R1_FIELD_OP_EN = 0;
            end

            POINT_ADDITION: begin
                o_CURVE_SECP256R1_FIELD_OP_EN = r_PA_STATE_FIELD_OP_EN;
            end

            POINT_DOUBLING: begin
                o_CURVE_SECP256R1_FIELD_OP_EN = r_PD_STATE_FIELD_OP_EN;
            end
            
            default: begin
                o_CURVE_SECP256R1_FIELD_OPERAND_A = r_REG_FILE[w_IMEM[11:8]];
                o_CURVE_SECP256R1_FIELD_OPERAND_B = r_REG_FILE[w_IMEM[7:4]];
                o_CURVE_SECP256R1_FIELD_OP_SEL = w_IMEM[1:0];
                o_CURVE_SECP256R1_FIELD_OP_EN = 0;
            end
        endcase
    end
    // --------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------

    // --------------------------------------------------------------------------------
    // SEQUENTIAL LOGIC SECTION
    // --------------------------------------------------------------------------------
    always_ff @(posedge i_SYS_CLK or negedge i_RSTn) begin
        if (!i_RSTn) begin
            o_CURVE_SECP256R1_DONE <= 0;
            
            r_REG_FILE[0] <= 0;
            r_REG_FILE[1] <= 0;
            r_REG_FILE[2] <= 0;
            r_REG_FILE[3] <= 0;
            r_REG_FILE[4] <= 0;
            r_REG_FILE[5] <= 0;
            r_REG_FILE[6] <= 0;
            r_REG_FILE[7] <= 0;
            r_REG_FILE[8] <= p_CONSTANT_A;
            r_REG_FILE[9] <= 256'h3;
            
            r_k <= '0;
            r_POINT_ADDITION_LOOKUP_TABLE_ADDR <= '0;
            r_POINT_DOUBLING_LOOKUP_TABLE_ADDR <= '0;
            r_PA_STATE_FIELD_OP_EN <= 0;
            r_PD_STATE_FIELD_OP_EN <= 0;
            r_STATE <= IDLE;
        end else begin
            o_CURVE_SECP256R1_DONE <= 0;

            case(r_STATE)
                IDLE: begin
                    o_CURVE_SECP256R1_DONE <= 0;
                    
                    r_POINT_ADDITION_LOOKUP_TABLE_ADDR <= '0;
                    r_POINT_DOUBLING_LOOKUP_TABLE_ADDR <= '0;
                
                    r_PA_STATE_FIELD_OP_EN <= 0;
                    r_PD_STATE_FIELD_OP_EN <= 0;

                    if (i_SECP256R1_CURVE_EN == 1) begin
                        r_REG_FILE[0] <= '0;
                        r_REG_FILE[1] <= '0;
                        r_REG_FILE[2] <= p_GX;
                        r_REG_FILE[3] <= p_GY;
                        r_k <= i_SECP256R1_CURVE_SCALAR;
                        r_STATE <= POINT_ADDITION;
                    end 
                    else begin
                        r_STATE <= IDLE;
                    end
                end

                POINT_ADDITION: begin
                    if (r_k !== 0) begin
                        if (r_k[0] == 1) begin
                            if (r_REG_FILE[0] == 0 && r_REG_FILE[1] == 0) begin
                                r_REG_FILE[0] <= r_REG_FILE[2];
                                r_REG_FILE[1] <= r_REG_FILE[3];
                                r_STATE <= POINT_DOUBLING;
                            end 
                            else begin
                                if (w_IMEM[3:0] == DONE) begin
                                    r_REG_FILE[0] <= r_REG_FILE[6];
                                    r_REG_FILE[1] <= r_REG_FILE[7];
                                    r_POINT_ADDITION_LOOKUP_TABLE_ADDR <= 0;
                                    r_STATE <= POINT_DOUBLING;
                                end 
                                else begin
                                    r_PA_STATE_FIELD_OP_EN <= 1;
                                    r_STATE <= POINT_ADDITION;
                                end

                                if (i_SECP256R1_CURVE_FIELD_OP_DONE == 1) begin
                                    r_POINT_ADDITION_LOOKUP_TABLE_ADDR <= r_POINT_ADDITION_LOOKUP_TABLE_ADDR + 1;
                                    r_REG_FILE[w_IMEM[15:12]] <= i_SECP256R1_CURVE_FIELD_OP_RESULT;
                                    r_PA_STATE_FIELD_OP_EN <= 0;
                                end
                            end
                        end 
                        else begin
                            r_STATE <= POINT_DOUBLING;
                        end
                    end 
                    else begin
                        o_CURVE_SECP256R1_DONE <= 1;
                        r_STATE <= CURVE_DONE;
                    end
                end

                POINT_DOUBLING: begin
                    if (r_k !== 0) begin
                        if (w_IMEM[3:0] == DONE) begin
                            r_k <= r_k >> 1;
                            r_REG_FILE[2] <= r_REG_FILE[6];
                            r_REG_FILE[3] <= r_REG_FILE[7];
                            r_POINT_DOUBLING_LOOKUP_TABLE_ADDR <= 0;
                            r_STATE <= POINT_ADDITION;
                        end 
                        else begin
                            r_PD_STATE_FIELD_OP_EN <= 1;
                            r_STATE <= POINT_DOUBLING;
                        end

                        if (i_SECP256R1_CURVE_FIELD_OP_DONE == 1) begin
                            r_POINT_DOUBLING_LOOKUP_TABLE_ADDR <= r_POINT_DOUBLING_LOOKUP_TABLE_ADDR + 1;
                            r_REG_FILE[w_IMEM[15:12]] <= i_SECP256R1_CURVE_FIELD_OP_RESULT;
                            r_PD_STATE_FIELD_OP_EN <= 0;
                        end
                    end 
                    else begin
                        o_CURVE_SECP256R1_DONE <= 1;
                        r_STATE <= CURVE_DONE;
                    end
                end

                CURVE_DONE: begin
                    r_STATE <= IDLE;
                end
            endcase
        end
    end
    // --------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------
endmodule
