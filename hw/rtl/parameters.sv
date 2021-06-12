//____________________________________________________________________________________________________________________
//file name : parameters.sv
//author : sivabalan
//description : This file include the predefined parameter values.
//____________________________________________________________________________________________________________________

//system config
parameter NUM_OF_CORES = 4;
parameter NUM_OF_LANES = 4;
parameter NUM_OF_PORT = 8;
parameter NUM_OF_WB = 3;
parameter MEM_REQ_PER_CORE = 2;

//registers
parameter VECTOR_REG_DEPTH = 64; 
parameter VECTOR_REG_WIDTH = 64;
parameter SCALAR_REG_DEPTH = 32; 
parameter SCALAR_REG_WIDTH = 64;
parameter NUM_OF_VECTOR_REG = 8;

//pipeline
parameter PIPELINE_OPCODE_WIDTH = 32;
typedef bit [PIPELINE_OPCODE_WIDTH-1:0] opcode_t;

//load and store
parameter LOAD_STORE_BUFFER_DEPTH = 64;
parameter REQUEST_COUNTER_WIDTH = 8;
parameter REQUEST_LENGHT_WIDTH = 8;

//cache
parameter TAG_BIT_WIDTH = 5;//to address a maximum of 32 tag.
parameter SET_BIT_WIDTH = 5;//to address a maximum of 32 set.
parameter CACHE_BLOCK_SIZE = 8;
parameter MAX_ASSOCIATIVITY = 32;
parameter CACHE_SIZE = 2048;
typedef enum { ONE_WAY_ASSOCIATIVITY = 0,
               TWO_WAY_ASSOCIATIVITY = 1,
               FOUR_WAY_ASSOCIATIVITY = 2,
               EIGHT_WAY_ASSOCIATIVITY = 3,
               SIXTEEN_WAY_ASSOCIATIVITY = 4,
               THIRTYTWO_WAY_ASSOCIATIVITY = 5 } associativity_t;

//memory
parameter BYTE = 8;
parameter ADDR_FIELD_WIDTH = 16;
parameter DATA_FIELD_WIDTH = 64;

//INTERFACE
parameter ACCESS_ID_WIDTH = 8;
//0 to 63   :core load and store ids
//64 to 127 :core icache ids
parameter CORE_ID_WIDTH = 4;

typedef enum { NULL_ACCESS, READ_REQ, WRITE_REQ, READ_RSP, WRITE_RSP, THREAD_ACTIVATE, THREAD_HALT} access_type_t;
typedef enum { NON_STRIDE, STRIDE, INDEX} stride_type_t;

typedef struct packed {
    bit vld;
    access_type_t access_type;
    bit [REQUEST_LENGHT_WIDTH-1:0] access_length;
    bit [ACCESS_ID_WIDTH-1:0] access_id;
    bit [CORE_ID_WIDTH-1:0] core_id;
    bit [ADDR_FIELD_WIDTH-1:0] addr;
    bit [(DATA_FIELD_WIDTH/BYTE)-1:0] byte_en;
    bit [VECTOR_REG_DEPTH-1:0] data;
} request_t;

typedef struct packed {
    bit vld;
    access_type_t access_type;
    bit [REQUEST_LENGHT_WIDTH-1:0] access_length;
    stride_type_t stride_type;
    bit [$clog2(NUM_OF_VECTOR_REG)-1:0] vec_reg_ptr;
    bit [ADDR_FIELD_WIDTH-1:0] addr;
    bit [VECTOR_REG_DEPTH-1:0] data;
} cntrl_req_t;

`define flip_flop(clk, reset, in, out)\
always_ff@(posedge clk or negedge reset)\
begin\
   if(!reset)\
      out <= 0;\
   else\
      out <= in;\
end

//vector_chip instructions
typedef enum bit [7:0] {
   NO_OP = 0,
   ADDVVD = 1, ADDVSD = 2,
   SUBVVD = 3, SUBVSD = 4, SUBSVD = 5, 
   MULVVD = 6, MULVSD = 7,
   DIVVVD = 8, DIVVSD = 9, DIVSVD = 10,
   LV = 11, LVI = 12, LVWS = 13, 
   SV = 14, SVI = 15, SVWS = 16,
   SEQVVD = 17, SNEVVD = 18, SGTVVD = 19, SLTVVD = 20, SGEVVD = 21, SLEVVD = 22,
   SEQVSD = 23, SNEVSD = 24, SGTVSD = 25, SLTVSD = 26, SGEVSD = 27, SLEVSD = 28,
   POP = 29, 
   CVM = 30, 
   MTC1 = 31, MFC1 = 32,
   MVTM = 33, MVFM = 34,
   PIPE_ACTIVATE =35, PIPE_HALT = 36, 
   MOV_IMM = 37, MOV_IMM_DATA = 38
 } vopcode_t;

 typedef enum {SADD, SSUB, SMUL, SDIV, 
               FADD, FSUB, FMUL, FDIV} function_opcode_t;

 //32 general purpose scalar registers
 typedef enum bit [7:0] { R0,  R1,  R2,  R3,  R4,  R5,  R6,  R7,
                          R8,  R9,  R10, R11, R12, R13, R14, R15,
                          R16, R17, R18, R19, R20, R21, R22, R23,
                          R24, R25, R26, R27, R28, R29, R30, R31 } s_register_t;

 //32 floating point registers
 typedef enum bit [7:0] { F0,  F1,  F2,  F3,  F4,  F5,  F6,  F7,
                          F8,  F9,  F10, F11, F12, F13, F14, F15,
                          F16, F17, F18, F19, F20, F21, F22, F23,
                          F24, F25, F26, F27, F28, F29, F30, F31 } f_register_t;

 typedef enum bit [7:0] { V0, V1, V2, V3, V4, V5, V6, V7, VLR, VM} v_register_t;