//____________________________________________________________________________________________________________________
//file name : lane.sv
//author : sivabalan
//description : This file holds the logic for lane inside the pipeline.
//____________________________________________________________________________________________________________________

module lane (input clk,
             input reset,

             //execution unit interface
             input vld,
             input [VECTOR_REG_WIDTH-1:0] data0,
             input [VECTOR_REG_WIDTH-1:0] data1,
             input [$clog2(NUM_OF_VECTOR_REG)-1:0] vec_reg_in,
             input function_opcode_t opcode,
             output busy,

             //wb interface
             output reg result_vld,
             output reg [$clog2(NUM_OF_VECTOR_REG)-1:0] vec_reg_out,
             output reg data_out

            );
 
endmodule