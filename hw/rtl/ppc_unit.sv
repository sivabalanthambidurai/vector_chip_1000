//____________________________________________________________________________________________________________________
//file name : ppc_unit.sv
//author : sivabalan
//description : This file holds the logic for parallel prefix computation unit 
//Source : https://rtlery.com/components/work-conserving-round-robin-arbiter
//latency : nil
//____________________________________________________________________________________________________________________

module ppc_unit (input clk,
                 input [NUM_OF_CORES-1:0] request_vector,
                 output reg [NUM_OF_CORES-1:0] grant
                ); 

   //parallel prefix computation logic.
   always_comb begin
      grant[0] = request_vector[0];
      grant[1] = request_vector[1] | grant[0];
      grant[2] = request_vector[2] | grant[1];
      grant[3] = request_vector[3] | grant[2];
   end
 
endmodule