//____________________________________________________________________________________________________________________
//file name : arbiter_rr.sv
//author : sivabalan
//description : This file holds the round robin arbiter logic. 
//Source : https://rtlery.com/components/work-conserving-round-robin-arbiter
//latency : 1cc to grant a request.
//____________________________________________________________________________________________________________________

module arbiter_rr (input clk,
                   input reset,
                   input [NUM_OF_CORES-1:0] request_vector,
                   output reg [NUM_OF_CORES-1:0] grant
                  );

   logic [NUM_OF_CORES-1:0] masked_request_vector, unmasked_grant, masked_grant;
   logic masked;

   ppc_unit next_mask_generator (.clk(clk),
                                 .request_vector(grant),
                                 .grant(next_mask_vector)
                                );

    always_comb begin
       masked_request_vector = request_vector & next_mask_vector;
    end

   arbiter_p masked_request_grant (.clk(clk),
                                   .request_vector(masked_request_vector),
                                   .grant(masked_grant)
                                  );

   arbiter_p unmasked_request_grant (.clk(clk),
                                     .request_vector(request_vector),
                                     .grant(unmasked_grant)
                                    );

    always_comb begin
       masked = (masked_grant == 4'h0) ? 0 : 1;
    end

    always_ff@(posedge clk or negedge reset) begin
        if(!reset)
        begin
           grant <= {NUM_OF_CORES{1'b0}};
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