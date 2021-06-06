//____________________________________________________________________________________________________________________
//file name : arbiter_p.sv
//author : sivabalan
//description : This file holds the priority arbiter logic. 
//Source : https://rtlery.com/components/work-conserving-round-robin-arbiter
//latency : nil
//____________________________________________________________________________________________________________________

module arbiter_p #(parameter VECTOR_IN = 8)
                 (input clk,
                  input [VECTOR_IN-1:0] request_vector,
                  output reg [VECTOR_IN-1:0] grant
                 );

   //priority arbiter
   always_comb begin
       grant = 0;
       for(int i = 0; i < VECTOR_IN; i++) begin
          if(request_vector[i] == 1'b1) begin
             grant[i] = 1;
             break;
          end
       end
   end

endmodule