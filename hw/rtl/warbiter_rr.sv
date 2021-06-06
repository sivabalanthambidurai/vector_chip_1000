//____________________________________________________________________________________________________________________
//file name : warbiter_rr.sv
//author : sivabalan
//description : This file holds the weighted round robin arbiter logic. 
//Source : https://rtlery.com/components/ppc-based-weighted-work-conserving-round-robin-arbiter
//latency : 1cc to grant a request.
//____________________________________________________________________________________________________________________

module weight_logic # (parameter VECTOR_IN = 8)
                    (input clk, 
                     input reset,
                     input [VECTOR_IN-1:0] request_vector,
                     input [VECTOR_REG_DEPTH-1:0] weight [VECTOR_IN-1:0],
                     output reg [VECTOR_IN-1:0] grant
                    );

   logic [$clog2(VECTOR_REG_DEPTH):0] num_of_grants;

   //parallel prefix computation logic.
   always_ff @(posedge clk or negedge reset) begin
      if(!reset) begin
         num_of_grants <= 0;
         grant <= 0;
      end
      else begin
         for(int i = 0; i<VECTOR_IN; i++) begin
            if(request_vector[i] && (weight[i] != num_of_grants+1)) begin
               num_of_grants <= num_of_grants+1;
            end
            else if(request_vector[i] && (weight[i] == num_of_grants+1)) begin
               num_of_grants <= 0;
               for(int i = 1; i < VECTOR_IN; i++) begin
                  grant[i] <= request_vector[i-1] | grant[i-1];
               end
            end
         end
      end
   end

endmodule

module warbiter_rr # (parameter VECTOR_IN = 8)
                   (input clk,
                    input reset,
                    input [VECTOR_IN-1:0] request_vector,
                    input [VECTOR_REG_DEPTH-1:0] weight [VECTOR_IN-1:0],
                    output reg [VECTOR_IN-1:0] grant
                   );

   logic [VECTOR_IN-1:0] request_vector_comb, masked_request_vector,
                         unmasked_grant, masked_grant, next_mask_vector;
   logic masked;

   weight_logic # (.VECTOR_IN(VECTOR_IN))
                next_mask_generator (.clk(clk),
                                     .reset(reset),
                                     .request_vector(grant),
                                     .weight(weight),
                                     .grant(next_mask_vector)
                                    );

  //filter thew request that has zero weight.
   always_comb begin
      request_vector_comb = 0;
      for(int i=0; i<VECTOR_IN; i++) begin
         if(weight[i] != 0)
            request_vector_comb[i] = request_vector[i];
      end
   end

    always_comb begin
       masked_request_vector = request_vector & next_mask_vector;
    end

   arbiter_p # (.VECTOR_IN(VECTOR_IN))
             masked_request_grant (.clk(clk),
                                   .request_vector(masked_request_vector),
                                   .grant(masked_grant)
                                  );

   arbiter_p # (.VECTOR_IN(VECTOR_IN))
             unmasked_request_grant (.clk(clk),
                                     .request_vector(request_vector_comb),
                                     .grant(unmasked_grant)
                                    );

    always_comb begin
       masked = (masked_grant == 4'h0) ? 0 : 1;
    end

    always_comb begin
       if(masked)
          grant = masked_grant;
       else
          grant = unmasked_grant;
    end

endmodule