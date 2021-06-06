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

   arbiter_rr # (.VECTOR_IN(NUM_OF_CORES))
              memory_request_arbiter (.clk(clk),
                                      .reset(reset),
                                      .request_vector({core3_req.vld, core2_req.vld, core1_req.vld, core0_req.vld}),
                                      .grant(memory_request_grant)
                                     );


   //cores to memory request interface
   always_comb begin
      unique casez(memory_request_grant)
      {NUM_OF_CORES{1'b0}}: mem_req = 'h0;
      {NUM_OF_CORES{1'b1 << 0}}: mem_req = core0_req;
      {NUM_OF_CORES{1'b1 << 1}}: mem_req = core1_req;
      {NUM_OF_CORES{1'b1 << 2}}: mem_req = core2_req;
      {NUM_OF_CORES{1'b1 << 3}}: mem_req = core3_req;
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