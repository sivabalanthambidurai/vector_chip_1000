//____________________________________________________________________________________________________________________
//file name : arbiter_p.sv
//author : sivabalan
//description : This file holds the priority arbiter logic. 
//Source : https://rtlery.com/components/work-conserving-round-robin-arbiter
//latency : nil
//____________________________________________________________________________________________________________________

module arbiter_p (input clk,
                  input [NUM_OF_CORES-1:0] request_vector,
                  output reg [NUM_OF_CORES-1:0] grant
                 );

   //priority arbiter
   always_comb begin
       priority case (request_vector)
       4'b???1 : grant = 4'b0001;
       4'b??10 : grant = 4'b0010;
       4'b?100 : grant = 4'b0100;
       4'b1000 : grant = 4'b1000;
       default : grant = 4'b0000;
       endcase
   end

endmodule