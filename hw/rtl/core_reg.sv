//____________________________________________________________________________________________________________________
//file name : core_register.sv
//author : sivabalan
//description : This file includes all the core registers.
//____________________________________________________________________________________________________________________

//core register
typedef struct packed {
   bit [31:16] RESERVED;
   bit [15:0] ADDR;
} core_base_addr_t;

module core_register (input clk,
                      input reset
                 
                     );

endmodule