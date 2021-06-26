//____________________________________________________________________________________________________________________
//file name : ifetch_unit.sv
//author : sivabalan
//description : This file holds the logic for instruction fetch unit.
//Each thread will be activated and de-activated by the software.
//Thread specific machine codes are managed by the Thread Manager.
//____________________________________________________________________________________________________________________

module ifetch_unit (input clk,
                    input reset,

                    //thread manager interface.
                    input request_t tm_req,
                    output request_t tm_rsp,

                    //core register interface
                    input core_base_addr_t CORE_BASE_ADDR,

                    //icache interface
                    input request_t icache_rsp,
                    input icache_busy,
                    output request_t icache_req,

                    //execution stage interface
                    input inst_buff_full,
                    output reg opcode_vld,
                    output opcode_t opcode0,
                    output opcode_t opcode1

                   ); 
 
   logic pipe_active;
   logic [ADDR_FIELD_WIDTH-1:0] current_pc;

   //pipe active indication logic.
   always_ff @(posedge clk or negedge reset) begin
      if(!reset)
         pipe_active <= 0;
      else if (!pipe_active && tm_req.vld && (tm_req.access_type == THREAD_ACTIVATE))
         pipe_active <= 1;
      //immediatly stop the fetch if we see a PIPE_HALT instruction
      else if (pipe_active && ((opcode0[31:24] == PIPE_HALT) || (opcode1[31:24] == PIPE_HALT)))
         pipe_active <= 0;
   end

   //thread de-activated response
   always_ff @(posedge clk or negedge reset) begin
      if(!reset)
         tm_rsp <= 0;
      else if (pipe_active && (opcode0 != PIPE_HALT) && (opcode1 != PIPE_HALT)) begin
         tm_rsp.vld <= 1;
         tm_rsp.access_type <= THREAD_HALT;
         tm_rsp.access_length <= 0;
         tm_rsp.access_id <= 0;
         tm_rsp.core_id <= 0;
         tm_rsp.addr <= 0;
         tm_rsp.byte_en <= 0;
         tm_rsp.data <= 0;
      end
      else
         tm_rsp <= 0;
   end

   //icache request generation logic.
   always_ff @(posedge clk or negedge reset)  begin
      if (!reset) begin
         icache_req <= 0;
         current_pc <= 0;
      end
      else if (!inst_buff_full && pipe_active && !icache_busy && (opcode0 != PIPE_HALT) && (opcode1 != PIPE_HALT)) begin
         icache_req.vld <= 1;
         icache_req.access_type <= NULL_ACCESS;
         icache_req.access_length <= 0;
         icache_req.access_id <= 0;
         icache_req.core_id <= 0;
         icache_req.addr <= CORE_BASE_ADDR.ADDR + current_pc;
         icache_req.byte_en <= 0;
         icache_req.data <= 0;
         current_pc <= current_pc + 1;
      end
      else if (!pipe_active) begin
         current_pc <= 0;
         icache_req <= 0;
      end
   end

   //a single cycle indicating a valid opcode to the execution unit 
   assign  opcode_vld = icache_rsp.vld;
   //execution unit interface
   assign opcode0 = (icache_rsp.vld) ? icache_rsp.data[31:0] : 0;
   assign opcode1 = (icache_rsp.vld) ? icache_rsp.data[63:32] : 0;

endmodule