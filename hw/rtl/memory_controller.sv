//____________________________________________________________________________________________________________________
//file name : memory_controller.sv
//author : sivabalan
//description : This file holds the memory controller logic. 
//____________________________________________________________________________________________________________________

module memory_controller (input clk,
                          input reset,
                          
                          //memory interface
                          output write,
                          output [(DATA_FIELD_WIDTH/BYTE)-1:0] we,
                          output [ADDR_FIELD_WIDTH-1:0] addr,
                          output [DATA_FIELD_WIDTH-1:0] data,                           
                          input [DATA_FIELD_WIDTH-1:0] q
                          );
  

 
endmodule
