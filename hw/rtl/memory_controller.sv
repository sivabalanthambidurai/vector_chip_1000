//____________________________________________________________________________________________________________________
//file name : memory_controller.sv
//author : sivabalan
//description : This file holds the memory controller logic. 
//latency : 2cc to get a response from the memory.
//____________________________________________________________________________________________________________________

module memory_controller (input clk,
                          input reset,
                    
                          //core interface
                          input request_t core_req,
                          output request_t core_rsp,

                        
                          //memory interface
                          output reg write,
                          output reg [(DATA_FIELD_WIDTH/BYTE)-1:0] we,
                          output reg [ADDR_FIELD_WIDTH-1:0] addr,
                          output reg [DATA_FIELD_WIDTH-1:0] data,                           
                          input [DATA_FIELD_WIDTH-1:0] q
                          );
  
   request_t core_req_f1, core_req_f2;

   //memory request generation logic
   always_ff@(posedge clk or negedge reset)
   begin
      if(!reset)
      begin
         write <= 0;
         we <= 0;
         addr <= 0;
         data <= 0;
      end
      else if(core_req.vld)
      begin
         write <= (core_req.access_type == WRITE_REQ);
         we <= core_req.byte_en;
         addr <= core_req.addr;
         data <= core_req.data;        
      end
   end

   //memory response generation logic
   `flip_flop(clk, reset, core_req.vld, core_req_f1.vld)
   `flip_flop(clk, reset, core_req.access_type, core_req_f1.access_type)
   `flip_flop(clk, reset, core_req.access_id, core_req_f1.access_id)
   `flip_flop(clk, reset, core_req.core_id, core_req_f1.core_id)
   `flip_flop(clk, reset, core_req.data, core_req_f1.data)

   `flip_flop(clk, reset, core_req_f1.vld, core_req_f2.vld)
   `flip_flop(clk, reset, core_req_f1.access_type, core_req_f2.access_type)
   `flip_flop(clk, reset, core_req_f1.access_id, core_req_f2.access_id)
   `flip_flop(clk, reset, core_req_f1.core_id, core_req_f2.core_id)
   `flip_flop(clk, reset, core_req_f1.data, core_req_f2.data)

   assign core_rsp.vld = core_req_f2.vld;
   assign core_rsp.access_type = (core_req_f2.access_type == WRITE_REQ) ? WRITE_RSP : READ_RSP;
   assign core_rsp.access_id = core_req_f2.access_id;
   assign core_rsp.core_id = core_req_f2.core_id;
   assign core_rsp.data = (core_req_f2.access_type == READ_REQ) ? q : 0;

endmodule
