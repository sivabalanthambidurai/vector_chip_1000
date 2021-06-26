//____________________________________________________________________________________________________________________
//file name : soc.sv
//author : sivabalan
//description : This file holds the top level System on Chip logic.
//clock freq = 1Ghz
//reset = active low reset
//Number of cores = 4
//Main Memory Size = 500KB
//____________________________________________________________________________________________________________________

module soc (input clk,
            input reset
           );

   //memory controller interface
   request_t mem_rsp, mem_req;

   //main memory interface
   logic write;
   logic [(DATA_FIELD_WIDTH/BYTE)-1:0] we;
   logic [ADDR_FIELD_WIDTH-1:0] addr;
   logic [DATA_FIELD_WIDTH-1:0] data;
   logic [DATA_FIELD_WIDTH-1:0] q;
   //core0 interface
   request_t core0_req, core0_rsp;

   inter_connect soc_inter_connect (.clk(clk),
                                    .reset(reset),
                      
                                    //core0 interface
                                    .core0_req(core0_req),
                                    .core0_rsp(core0_rsp),
                                    //core1 interface
                                    .core1_req(),
                                    .core1_rsp(),
                                    //core2 interface
                                    .core2_req(),
                                    .core2_rsp(),
                                    //core3 interface
                                    .core3_req(),
                                    .core3_rsp(),

                                    //memory interface
                                    .mem_req(mem_req),
                                    .mem_rsp(mem_rsp)

                     );

//core0
 core #(.CORE_ID(0))
      core0  (.clk(clk),
              .reset(reset),
                 
              //memory interface
              .mem_rsp(core0_rsp),
              .mem_req(core0_req)
             );
    
//core1-3

//memory controller
memory_controller soc_mem_cntrl(.clk(clk),
                                .reset(reset),
                    
                                //core interface
                                .core_req(mem_req),
                                .core_rsp(mem_rsp),

                        
                                //memory interface
                                .write,
                                .we,
                                .addr,
                                .data,                           
                                .q

                          );

memory soc_mmemory (.clk(clk),
                    .write,
                    .we,
                    .addr,
                    .data,                            
                    .q
                   );

endmodule
