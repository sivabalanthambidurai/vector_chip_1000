//____________________________________________________________________________________________________________________
//file name : arbiter_rr2.sv
//author : sivabalan
//description : This file holds the round robin arbiter logic with a updated version of the
//arbiter_rr.sv. This arbiter additionally holds stall logic to hold the grant genration.
//latency : 1cc to grant a request.
//____________________________________________________________________________________________________________________

module arbiter_rr2 # (parameter VECTOR_IN = 8)
                   (input clk,
                    input reset,
                    input stall, //updated logic
                    input [VECTOR_IN-1:0] request_vector,
                    output reg [VECTOR_IN-1:0] grant
                   );

   logic [VECTOR_IN-1:0] masked_request_vector, unmasked_grant, masked_grant, next_mask_vector;
   logic masked;
   logic [VECTOR_IN-1:0] request_vector_comb;
    
   //if there is not valid grant to keep when stall, work on the next request and 
   //keep that until stall is de-asserted.
   assign request_vector_comb = (stall && (grant != 0)) ? 0 : request_vector;
   
   ppc_unit # (.VECTOR_IN(VECTOR_IN))
            next_mask_generator (.clk(clk),
                                 .request_vector(grant),
                                 .grant(next_mask_vector)
                                );

    always_comb begin
       masked_request_vector = request_vector_comb & next_mask_vector;
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

    always_ff@(posedge clk or negedge reset) begin
        if(!reset)
        begin
           grant <= {VECTOR_IN{1'b0}};
        end
        else
        begin
           //if there is a valid grant, that is being blocked by stall keep it.
           //else work on next request and keep the grant if the stall still exists.
           if(stall && (grant != 0))
              grant <= grant;
           else if(masked)
              grant <= masked_grant;
           else
              grant <= unmasked_grant;
        end
    end

endmodule