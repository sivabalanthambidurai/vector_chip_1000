//____________________________________________________________________________________________________________________
//file name : stp.sv
//author : sivabalan
//description : This file holds the logic for single threaded pipeline.
//____________________________________________________________________________________________________________________

module stp (input clk,
            input reset,

            //vector register interface
            input reg_req_grant [NUM_OF_LANES-1:0],
            input reg_rsp_vld [NUM_OF_LANES-1:0],
            input [VECTOR_REG_WIDTH-1:0] reg_rsp_data [NUM_OF_LANES-1:0],
            output cntrl_req_t reg_req [NUM_OF_LANES-1:0]

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
                      .opcode0(),
                      .opcode1()

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