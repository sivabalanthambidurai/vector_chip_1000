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
   logic [VECTOR_IN-1:0] ppc_req_vector;


   assign ppc_req_vector = stall ? 0 : grant;

   ppc_unit # (.VECTOR_IN(VECTOR_IN))
            next_mask_generator (.clk(clk),
                                 .request_vector(ppc_req_vector),
                                 .grant(next_mask_vector)
                                );

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
                                     .request_vector(request_vector),
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
           if(masked)
              grant <= masked_grant;
           else
              grant <= unmasked_grant;
        end
    end

endmodule