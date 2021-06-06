//____________________________________________________________________________________________________________________
//file name : vector_register.sv
//author : sivabalan
//description : This file holds the vector register logic. Vector register holds 64 element with each 64 bit wide
//A dual port register file, separte port dedicated for reads and write. So this register can facilitate a read and
//a write at same time. 
//____________________________________________________________________________________________________________________

module vector_register (input clk,
                        input reset,
                        input [$clog2(VECTOR_REG_DEPTH)-1:0] read_addr,
                        input write,
                        input [$clog2(VECTOR_REG_DEPTH)-1:0] write_addr,
                        input [VECTOR_REG_WIDTH-1:0] write_data,

                        output reg [VECTOR_REG_WIDTH-1:0] reg_data

                       );
  
  logic [VECTOR_REG_WIDTH-1:0] vector_register_array [VECTOR_REG_DEPTH];
  
  always_ff@(posedge clk or posedge reset)
  begin
    if(reset)
    begin
      foreach(vector_register_array[i])
      begin
        vector_register_array[i] <= {VECTOR_REG_WIDTH{1'h0}};
      end
    end
    else if(write)
       vector_register_array[write_addr] <= write_data;
  end

  assign reg_data = vector_register_array[read_addr];
  
endmodule
