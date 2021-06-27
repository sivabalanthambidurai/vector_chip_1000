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
                      output reg core0_grant,
                      //core1 interface
                      input request_t core1_req,
                      output request_t core1_rsp,
                      output reg core1_grant,
                      //core2 interface
                      input request_t core2_req,
                      output request_t core2_rsp,
                      output reg core2_grant,
                      //core3 interface
                      input request_t core3_req,
                      output request_t core3_rsp,
                      output reg core3_grant,

                      //memory interface
                      output request_t mem_req,
                      input request_t mem_rsp

                     );


   logic [2*NUM_OF_CORES-1:0] memory_request_grant;
   logic [2*NUM_OF_CORES-1:0] weight [2*NUM_OF_CORES-1:0];

   assign weight[0] = core0_req.access_length;
   assign weight[1] = core1_req.access_length;
   assign weight[2] = core2_req.access_length;
   assign weight[3] = core3_req.access_length;

   warbiter_rr # (.VECTOR_IN(2*NUM_OF_CORES))
               memory_request_arbiter (.clk(clk),
                                       .reset(reset),
                                       .request_vector({4'h0,core3_req.vld, core2_req.vld, core1_req.vld, core0_req.vld}),
                                       .weight(weight),
                                       .grant(memory_request_grant)
                                      );

   //grant to the respective cores
   assign core0_grant = memory_request_grant[0];
   assign core1_grant = memory_request_grant[1];
   assign core2_grant = memory_request_grant[2];
   assign core3_grant = memory_request_grant[3];

   //cores to memory request interface
   always_ff @(posedge clk or negedge reset) begin
      if(!reset) begin
         mem_req <= 0;
      end
      else begin
         unique case(memory_request_grant)
            0: mem_req <= 'h0;
            1: mem_req <= core0_req;
            2: mem_req <= core1_req;
            4: mem_req <= core2_req;
            8: mem_req <= core3_req;
            default : mem_req = 'h0;
         endcase
      end
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
      else
      begin
         core0_rsp <= 'h0;
         core1_rsp <= 'h0;
         core2_rsp <= 'h0;
         core3_rsp <= 'h0;
      end
   end  

endmodule