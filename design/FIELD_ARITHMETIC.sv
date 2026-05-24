// --------------------------------------------------------------------------------
// NAMING CONVENTION FOR SIGNALS BETWEEN MODULES:
// --------------------------------------------------------------------------------
// 1. INPUT  Signals: i_<SRC_MODULE>_<DEST_MODULE>_<SIGNAL_NAME>
// 2. OUTPUT Signals: o_<SRC_MODULE>_<DEST_MODULE>_<SIGNAL_NAME>
// --------------------------------------------------------------------------------

module FIELD_ARITHMETIC #(
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

    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_SECP256R1_FIELDARITH_OPERAND_A,
    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_SECP256R1_FIELDARITH_OPERAND_B,
    input  logic [p_REGISTER_BIT_WIDTH-1:0] i_SECP256R1_FIELDARITH_MODULUS,
    output logic [p_REGISTER_BIT_WIDTH-1:0] o_FIELDARITH_SECP256R1_RESULT,
    
    input  logic [1:0]                      i_FIELDARITH_SECP256R1_OP_SEL,
    input  logic                            i_SECP256R1_FIELDARITH_EN,
    output logic                            o_FIELDARITH_SECP256R1_DONE
);

    // --------------------------------------------------------------------------------
    // INTERNAL SIGNALS DECLARATION SECTION
    // --------------------------------------------------------------------------------
    logic [p_REGISTER_BIT_WIDTH-1:0] w_MODADD_FIELDARITH_RESULT;
    logic                            w_FIELDARITH_MODADD_EN;
    logic                            w_MODADD_FIELDARITH_DONE;

    logic [p_REGISTER_BIT_WIDTH-1:0] w_MODSUB_FIELDARITH_RESULT;
    logic                            w_FIELDARITH_MODSUB_EN;
    logic                            w_MODSUB_FIELDARITH_DONE;

    logic [p_REGISTER_BIT_WIDTH-1:0] w_MODMUL_FIELDARITH_RESULT;
    logic                            w_FIELDARITH_MODMUL_EN;
    logic                            w_MODMUL_FIELDARITH_DONE;

    logic [p_REGISTER_BIT_WIDTH-1:0] w_MODINV_FIELDARITH_RESULT;
    logic                            w_FIELDARITH_MODINV_EN;
    logic                            w_MODINV_FIELDARITH_DONE;

    // --------------------------------------------------------------------------------
    // MODULE INSTANTIATION  SECTION
    // --------------------------------------------------------------------------------
    MODULAR_ADDITION # (
        .p_REGISTER_BIT_WIDTH(p_REGISTER_BIT_WIDTH)
    ) modular_addition_instance (
        .i_SYS_CLK(i_SYS_CLK),
        .i_RSTn(i_RSTn),

        .i_FIELDARITH_MODADD_OPERAND_A(i_SECP256R1_FIELDARITH_OPERAND_A),
        .i_FIELDARITH_MODADD_OPERAND_B(i_SECP256R1_FIELDARITH_OPERAND_B),
        .i_FIELDARITH_MODADD_MODULUS(i_SECP256R1_FIELDARITH_MODULUS),

        .o_MODADD_FIELDARITH_RESULT(w_MODADD_FIELDARITH_RESULT),
        .i_FIELDARITH_MODADD_EN(w_FIELDARITH_MODADD_EN),
        .o_MODADD_FIELDARITH_DONE(w_MODADD_FIELDARITH_DONE)
    );

    MODULAR_SUBTRACTION # (
        .p_REGISTER_BIT_WIDTH(p_REGISTER_BIT_WIDTH)
    ) modular_subtraction_instance (
        .i_SYS_CLK(i_SYS_CLK),
        .i_RSTn(i_RSTn),

        .i_FIELDARITH_MODSUB_OPERAND_A(i_SECP256R1_FIELDARITH_OPERAND_A),
        .i_FIELDARITH_MODSUB_OPERAND_B(i_SECP256R1_FIELDARITH_OPERAND_B),
        .i_FIELDARITH_MODSUB_MODULUS(i_SECP256R1_FIELDARITH_MODULUS),

        .o_MODSUB_FIELDARITH_RESULT(w_MODSUB_FIELDARITH_RESULT),
        .i_FIELDARITH_MODSUB_EN(w_FIELDARITH_MODSUB_EN),
        .o_MODSUB_FIELDARITH_DONE(w_MODSUB_FIELDARITH_DONE)
    );

    MODULAR_MULTIPLICATION # (
        .p_REGISTER_BIT_WIDTH(p_REGISTER_BIT_WIDTH)
    ) modular_multiplication_instance (
        .i_SYS_CLK(i_SYS_CLK),
        .i_RSTn(i_RSTn),

        .i_FIELDARITH_MODMUL_OPERAND_A(i_SECP256R1_FIELDARITH_OPERAND_A),
        .i_FIELDARITH_MODMUL_OPERAND_B(i_SECP256R1_FIELDARITH_OPERAND_B),
        .i_FIELDARITH_MODMUL_MODULUS(i_SECP256R1_FIELDARITH_MODULUS),

        .o_MODMUL_FIELDARITH_RESULT(w_MODMUL_FIELDARITH_RESULT),
        .i_FIELDARITH_MODMUL_EN(w_FIELDARITH_MODMUL_EN),
        .o_MODMUL_FIELDARITH_DONE(w_MODMUL_FIELDARITH_DONE)
    );

    MODULAR_INVERSE # (
        .p_REGISTER_BIT_WIDTH(p_REGISTER_BIT_WIDTH)
    ) modular_inverse_instance (
        .i_SYS_CLK(i_SYS_CLK),
        .i_RSTn(i_RSTn),

        .i_FIELDARITH_MODINV_OPERAND_A(i_SECP256R1_FIELDARITH_OPERAND_A),
        .i_FIELDARITH_MODINV_OPERAND_B(i_SECP256R1_FIELDARITH_OPERAND_B),
        .i_FIELDARITH_MODINV_MODULUS(i_SECP256R1_FIELDARITH_MODULUS),

        .o_MODINV_FIELDARITH_RESULT(w_MODINV_FIELDARITH_RESULT),
        .i_FIELDARITH_MODINV_EN(w_FIELDARITH_MODINV_EN),
        .o_MODINV_FIELDARITH_DONE(w_MODINV_FIELDARITH_DONE)
    );

    // --------------------------------------------------------------------------------
    // COMBINATIONAL LOGIC SECTION
    // --------------------------------------------------------------------------------
    always_comb begin
        case (i_FIELDARITH_SECP256R1_OP_SEL)
            2'h0: begin
                o_FIELDARITH_SECP256R1_RESULT = w_MODADD_FIELDARITH_RESULT;
                
                w_FIELDARITH_MODADD_EN        = i_SECP256R1_FIELDARITH_EN;
                w_FIELDARITH_MODSUB_EN        = 0;
                w_FIELDARITH_MODMUL_EN        = 0;
                w_FIELDARITH_MODINV_EN        = 0;
                o_FIELDARITH_SECP256R1_DONE   = w_MODADD_FIELDARITH_DONE;
            end
            2'h1: begin
                o_FIELDARITH_SECP256R1_RESULT = w_MODSUB_FIELDARITH_RESULT;
                
                w_FIELDARITH_MODADD_EN        = 0;
                w_FIELDARITH_MODSUB_EN        = i_SECP256R1_FIELDARITH_EN;
                w_FIELDARITH_MODMUL_EN        = 0;
                w_FIELDARITH_MODINV_EN        = 0;
                o_FIELDARITH_SECP256R1_DONE   = w_MODSUB_FIELDARITH_DONE;
            end
            2'h2: begin
                o_FIELDARITH_SECP256R1_RESULT = w_MODMUL_FIELDARITH_RESULT;
                
                w_FIELDARITH_MODADD_EN        = 0;
                w_FIELDARITH_MODSUB_EN        = 0;
                w_FIELDARITH_MODMUL_EN        = i_SECP256R1_FIELDARITH_EN;
                w_FIELDARITH_MODINV_EN        = 0;
                o_FIELDARITH_SECP256R1_DONE   = w_MODMUL_FIELDARITH_DONE;
            end
            2'h3: begin
                o_FIELDARITH_SECP256R1_RESULT = w_MODINV_FIELDARITH_RESULT;
                
                w_FIELDARITH_MODADD_EN        = 0;
                w_FIELDARITH_MODSUB_EN        = 0;
                w_FIELDARITH_MODMUL_EN        = 0;
                w_FIELDARITH_MODINV_EN        = i_SECP256R1_FIELDARITH_EN;
                o_FIELDARITH_SECP256R1_DONE   = w_MODINV_FIELDARITH_DONE;
            end
        endcase
    end
endmodule
