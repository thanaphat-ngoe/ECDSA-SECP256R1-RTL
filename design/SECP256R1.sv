// --------------------------------------------------------------------------------
// NAMING CONVENTION FOR SIGNALS BETWEEN MODULES:
// --------------------------------------------------------------------------------
// 1. INPUT  Signals: i_<SRC_MODULE>_<DEST_MODULE>_<SIGNAL_NAME>
// 2. OUTPUT Signals: o_<SRC_MODULE>_<DEST_MODULE>_<SIGNAL_NAME>
// --------------------------------------------------------------------------------

module SECP256R1 #(
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
    input  logic                            i_SYS_CLK,                     
    input  logic                            i_RSTn,
    // input  logic [1:0]                      i_EX_SECP256R1_ECDSA_OP_SEL, // 00: KEY GENERATION, 01: SIGNATURE GENERATION, 10: SIGNATURE VERIFY
    input  logic                            i_EX_SECP256R1_EN,
    output logic                            o_SECP256R1_EX_DONE,

	input  logic [p_REGISTER_BIT_WIDTH-1:0] i_EX_SECP256R1_RANDOMED_PRIVATE_KEY,
    output logic [p_REGISTER_BIT_WIDTH-1:0] o_EX_SECP256R1_PUBLIC_KEY_X_OR_SIGNATURE_r,
    output logic [p_REGISTER_BIT_WIDTH-1:0] o_EX_SECP256R1_PUBLIC_KEY_Y_OR_SIGNATURE_s
);

    logic [p_REGISTER_BIT_WIDTH-1:0] w_CURVE_SECP256R1_FIELD_OPERAND_A;
    logic [p_REGISTER_BIT_WIDTH-1:0] w_CURVE_SECP256R1_FIELD_OPERAND_B;
    logic [p_REGISTER_BIT_WIDTH-1:0] w_CURVE_SECP256R1_FIELD_MODULUS;
    logic [p_REGISTER_BIT_WIDTH-1:0] w_FIELD_SECP2561_FIELD_OP_RESULT;
    
    logic [1:0] w_CURVE_SECP256R1_FIELD_OP_SEL;
    logic w_CURVE_SECP256R1_FIELD_OP_EN;
    logic w_FIELD_SECP256R1_FIELD_DONE;

    CURVE_ARITHMETIC #(
        .p_REGISTER_BIT_WIDTH(p_REGISTER_BIT_WIDTH),
        .p_PRIME_MODULUS(p_PRIME_MODULUS),
        .p_ORDER_n(p_ORDER_n),
        .p_CONSTANT_A(p_CONSTANT_A),
        .p_CONSTANT_B(p_CONSTANT_B),
        .p_GX(p_GX),
        .p_GY(p_GY)
    ) curve_arithmetic_instance (
        .i_SYS_CLK(i_SYS_CLK),                       
        .i_RSTn(i_RSTn),

        .i_SECP256R1_CURVE_SCALAR(i_EX_SECP256R1_RANDOMED_PRIVATE_KEY),
        // .i_SECP256R1_CURVE_POINT_PX(w_SECP256R1_CURVE_POINT_PX),
        // .i_SECP256R1_CURVE_POINT_PY(w_SECP256R1_CURVE_POINT_PY),
        .o_CURVE_SECP256R1_POINT_RX(o_EX_SECP256R1_PUBLIC_KEY_X_OR_SIGNATURE_r),
        .o_CURVE_SECP256R1_POINT_RY(o_EX_SECP256R1_PUBLIC_KEY_Y_OR_SIGNATURE_s),

        // .i_SECP256R1_CURVE_OP_SEL(w_SECP256R1_CURVE_OP_SEL),
        .i_SECP256R1_CURVE_EN(i_EX_SECP256R1_EN),
        .o_CURVE_SECP256R1_DONE(o_SECP256R1_EX_DONE),

        .o_CURVE_SECP256R1_FIELD_OPERAND_A(w_CURVE_SECP256R1_FIELD_OPERAND_A),   
        .o_CURVE_SECP256R1_FIELD_OPERAND_B(w_CURVE_SECP256R1_FIELD_OPERAND_B),
        .o_CURVE_SECP256R1_FIELD_MODULUS(w_CURVE_SECP256R1_FIELD_MODULUS),
        .i_SECP256R1_CURVE_FIELD_OP_RESULT(w_FIELD_SECP2561_FIELD_OP_RESULT),

        .o_CURVE_SECP256R1_FIELD_OP_SEL(w_CURVE_SECP256R1_FIELD_OP_SEL),
        .o_CURVE_SECP256R1_FIELD_OP_EN(w_CURVE_SECP256R1_FIELD_OP_EN),
        .i_SECP256R1_CURVE_FIELD_OP_DONE(w_FIELD_SECP256R1_FIELD_DONE)
    );

    FIELD_ARITHMETIC #(
        .p_REGISTER_BIT_WIDTH(p_REGISTER_BIT_WIDTH),
        .p_PRIME_MODULUS(p_PRIME_MODULUS),
        .p_ORDER_n(p_ORDER_n),
        .p_CONSTANT_A(p_CONSTANT_A),
        .p_CONSTANT_B(p_CONSTANT_B),
        .p_GX(p_GX),
        .p_GY(p_GY)
    ) field_arithmetic_instance (
        .i_SYS_CLK(i_SYS_CLK),
        .i_RSTn(i_RSTn),

        .i_SECP256R1_FIELDARITH_OPERAND_A(w_CURVE_SECP256R1_FIELD_OPERAND_A),
        .i_SECP256R1_FIELDARITH_OPERAND_B(w_CURVE_SECP256R1_FIELD_OPERAND_B),
        .i_SECP256R1_FIELDARITH_MODULUS(w_CURVE_SECP256R1_FIELD_MODULUS),
        .o_FIELDARITH_SECP256R1_RESULT(w_FIELD_SECP2561_FIELD_OP_RESULT),

        .i_FIELDARITH_SECP256R1_OP_SEL(w_CURVE_SECP256R1_FIELD_OP_SEL),
        .i_SECP256R1_FIELDARITH_EN(w_CURVE_SECP256R1_FIELD_OP_EN),
        .o_FIELDARITH_SECP256R1_DONE(w_FIELD_SECP256R1_FIELD_DONE)
    );
    
endmodule
