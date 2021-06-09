//____________________________________________________________________________________________________________________
//file name : stp.sv
//author : sivabalan
//description : This file holds the logic for single threaded pipeline.
//____________________________________________________________________________________________________________________

module stp (input clk,
            input reset
           ); 
 
   ifetch_unit stp_if(.clk(clk),
                      .reset(reset)
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

endmodule