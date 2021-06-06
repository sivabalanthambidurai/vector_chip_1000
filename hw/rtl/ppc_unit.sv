//____________________________________________________________________________________________________________________
//file name : ppc_unit.sv
//author : sivabalan
//description : This file holds the logic for parallel prefix computation unit 
//Source : https://rtlery.com/components/work-conserving-round-robin-arbiter
//latency : nil
//____________________________________________________________________________________________________________________

module ppc_unit # (parameter VECTOR_IN = 8)
                (input clk,
                 input [VECTOR_IN-1:0] request_vector,
                 output reg [VECTOR_IN-1:0] grant
                ); 

   //parallel prefix computation logic.
   always_comb begin
      grant = 0;
      for(int i = 1; i < VECTOR_IN; i++) begin
         grant[i] = request_vector[i-1] | grant[i-1];
      end
   end
 
endmodule