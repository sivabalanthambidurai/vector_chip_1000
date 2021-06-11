//____________________________________________________________________________________________________________________
//file name : stp.sv
//author : sivabalan
//description : This file holds the logic for single threaded pipeline.
//____________________________________________________________________________________________________________________

module stp (input clk,
            input reset
           ); 
 
   ifetch_unit stp_if(.clk(clk),
                      .reset(reset),

                      //thread manager interface.
                      .tm_req(),
                      .tm_rsp(),

                      //core register interface
                      .CORE_BASE_ADDR(),

                      //icache interface
                      .icache_rsp(),
                      .icache_busy(),
                      .icache_req(),

                      //execution stage interface
                      .opcode_vld(),
                      .opcode1(),
                      .opcode2()

                     );

   iexecution_unit stp_iexe(.clk(clk),
                            .reset(reset)
                           );

   lane stp_lane[NUM_OF_LANES-1:0] (.clk(clk),
                                    .reset(reset)
                                   );

   wb stp_wb(.clk(clk),
             .reset(reset)
            );

  core_register core_reg (.clk(clk),
                          .reset(reset)
                 
                         );

endmodule