//____________________________________________________________________________________________________________________
//file name : inter_connect.sv
//author : sivabalan
//description : This file holds logic for Inter connection between Core and the memory.
//____________________________________________________________________________________________________________________

module inter_connect (input clk,
                      input reset,
                      
                      //core0 interface
                      input request_t core0_req,
                      output request_t core0_rsp,
                      //core1 interface
                      input request_t core1_req,
                      output request_t core1_rsp,
                      //core2 interface
                      input request_t core2_req,
                      output request_t core2_rsp,
                      //core3 interface
                      input request_t core3_req,
                      output request_t core3_rsp,

                      //memory interface
                      output request_t mem_req,
                      input request_t mem_rsp

                     );


   logic [NUM_OF_CORES-1:0] memory_request_grant;
   logic [2*NUM_OF_CORES-1:0] weight [NUM_OF_CORES-1:0];

   assign weight[0] = core0_req.access_length;
   assign weight[1] = core1_req.access_length;
   assign weight[2] = core2_req.access_length;
   assign weight[3] = core3_req.access_length;

   warbiter_rr # (.VECTOR_IN(NUM_OF_CORES))
               memory_request_arbiter (.clk(clk),
                                       .reset(reset),
                                       .request_vector({core3_req.vld, core2_req.vld, core1_req.vld, core0_req.vld}),
                                       .weight(weight),
                                       .grant(memory_request_grant)
                                     );


   //cores to memory request interface
   always_comb begin
      unique case(memory_request_grant)
      0: mem_req = 'h0;
      1: mem_req = core0_req;
      2: mem_req = core1_req;
      4: mem_req = core2_req;
      8: mem_req = core3_req;
      endcase
   end

   //memory to core response interface
   always_ff@(posedge clk or negedge reset) begin
      if(!reset)
      begin
         core0_rsp <= 'h0;
         core1_rsp <= 'h0;
         core2_rsp <= 'h0;
         core3_rsp <= 'h0;
      end
      else if(mem_rsp.vld)
      begin
         unique case(mem_rsp.core_id)
         4'h0: core0_rsp <= mem_rsp;
         4'h1: core1_rsp <= mem_rsp;
         4'h2: core2_rsp <= mem_rsp;
         4'h3: core3_rsp <= mem_rsp;
         endcase
      end
   end  

endmodule