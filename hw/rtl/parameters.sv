//____________________________________________________________________________________________________________________
//file name : parameters.sv
//author : sivabalan
//description : This file include the predefined parameter values.
//____________________________________________________________________________________________________________________

//system config
parameter NUM_OF_CORES = 4;

//registers
parameter VECTOR_REG_DEPTH = 64; 
parameter VECTOR_REG_WIDTH = 64;
parameter SCALAR_REG_DEPTH = 32; 
parameter SCALAR_REG_WIDTH = 64;

//memory
parameter BYTE = 8;
parameter ADDR_FIELD_WIDTH = 16;
parameter DATA_FIELD_WIDTH = 64;

//INTERFACE
parameter access_id_WIDTH = 8;
parameter CORE_ID_WIDTH = 4;

typedef enum { NULL_ACCESS, READ_REQ, WRITE_REQ, READ_RSP, WRITE_RSP} access_type_t;

typedef struct packed {
    bit vld;
    access_type_t access_type;
    bit [access_id_WIDTH-1:0] access_id;
    bit [CORE_ID_WIDTH-1:0] core_id;
    bit [ADDR_FIELD_WIDTH-1:0] addr;
    bit [(DATA_FIELD_WIDTH/BYTE)-1:0] byte_en;
    bit [VECTOR_REG_DEPTH-1:0] data;
} request_t;

`define flip_flop(clk, reset, in, out)\
always_ff@(posedge clk or negedge reset)\
begin\
   if(!reset)\
      out <= 0;\
   else\
      out <= in;\
end