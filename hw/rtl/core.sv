//____________________________________________________________________________________________________________________
//file name : core.sv
//author : sivabalan
//description : This file holds the top level core logic.
//clock freq = 1Ghz
//reset = active low reset
//vector register = 64
//scalar register = 32
//fp register = 32
//lanes = 4
//pipeline stages = ifetch, idecode, iexecute(holds the lanes), iwriteback
//load and store unit - 1 (can support a maximum of 64 read or write requests) 
//____________________________________________________________________________________________________________________

module core # (parameter CORE_ID = 0)
            (input clk,
             input reset,
                    
             //memory interface
             input request_t mem_rsp,
             output request_t mem_req,
             input mem_req_grant
            );

  //8 read and 8 write ports for 8 vector register. (1 read + 1 write port per vector register)
  logic [$clog2(VECTOR_REG_DEPTH)-1:0] vector_read_addr_port [NUM_OF_VECTOR_REG-1:0];
  logic vector_write_port [NUM_OF_VECTOR_REG-1:0];
  logic [$clog2(VECTOR_REG_DEPTH)-1:0] vector_write_addr_port [NUM_OF_VECTOR_REG-1:0];
  logic [VECTOR_REG_WIDTH-1:0] write_data [NUM_OF_VECTOR_REG-1:0];
  logic [VECTOR_REG_WIDTH-1:0] vector_read_data_port [NUM_OF_VECTOR_REG-1:0];
  logic [VECTOR_REG_WIDTH-1:0] vector_read_data_map_port [NUM_OF_VECTOR_REG-1:0];
  logic reg_req_grant [NUM_OF_PORT-1:0];
  logic vector_read_data_port_vld [NUM_OF_PORT-1:0];
  logic [$clog2(VECTOR_REG_DEPTH)-1:0] vector_rsp_addr_port [NUM_OF_VECTOR_REG-1:0];
  //req and rsp port.
  cntrl_req_t vec_reg_req_port [NUM_OF_PORT-1:0];
  //core to memory requests
  request_t load_store_unit_mem_req, icache_mem_req;
  //memory to core responses
  request_t load_store_unit_mem_rsp, icache_mem_rsp;
  logic [MEM_REQ_PER_CORE-1:0] grant;
  //grant[0] - icahe (highest priority),
  //grant[1] - load and store unit (lowest priority)

  //icache interface
  request_t icache_req, icache_rsp;
  logic icache_busy;

  //load and store unit       
  logic load_store_unit_busy;
  cntrl_req_t load_store_req;

  vector_register vector_reg[NUM_OF_VECTOR_REG-1:0] (.clk(clk), 
                                                     .reset(reset),
                                                     .read_addr(vector_read_addr_port),
                                                     .write(vector_write_port),
                                                     .write_addr(vector_write_addr_port),
                                                     .write_data(write_data),
                                                     .reg_data(vector_read_data_port)
                                                    );
  
  vector_mapper reg_map (.clk(clk),
                         .reset(reset),
                         .vld(vector_read_data_port_vld),
                         .addr_port(vector_rsp_addr_port),
                         .data_port_in(vector_read_data_port),
                         .data_port_out(vector_read_data_map_port) 
                        );

  crossbar_switch xbar(.clk(clk), 
                       .reset(reset),

                       //req port.
                       .vec_reg_req_port(vec_reg_req_port),

                       //reg interface.
                       .vector_read_addr_port(vector_read_addr_port),
                       .vector_write_port(vector_write_port),
                       .vector_write_addr_port(vector_write_addr_port),
                       .write_data(write_data),
                       .reg_req_grant(reg_req_grant),
                       .rsp_vld(vector_read_data_port_vld),
                       .rsp_addr_port(vector_rsp_addr_port)
                       );


  vector_load_store_unit # (.CORE_ID(CORE_ID))
                         load_store_unit(.clk(clk),
                                         .reset(reset),

                                        //pipeline interface
                                        .cntrl_req(load_store_req),
                                        .buffer_full(load_store_unit_busy),

                                        //vector register interface
                                        .reg_req_grant(reg_req_grant[0]),
                                        .reg_rsp_vld(vector_read_data_port_vld[0]),
                                        .reg_rsp_data(vector_read_data_map_port[0]),
                                        .reg_req(vec_reg_req_port[0]),

                                        //memory request interface
                                        .mem_rsp(load_store_unit_mem_rsp),
                                        .req_grant(grant[1] && (!mem_req.vld || (mem_req_grant && mem_req.vld))),
                                        .mem_req(load_store_unit_mem_req)
                                        );

    

    stp stp_thread (.clk(clk),
                    .reset(reset),

                    //load and store unit interface
                    .load_store_unit_busy(load_store_unit_busy),
                    .load_store_req(load_store_req),

                    //vector register interface
                    .reg_req_grant(reg_req_grant[4:1]),
                    .reg_rsp_vld(vector_read_data_port_vld[4:1]),
                    .reg_rsp_data(vector_read_data_map_port[4:1]),
                    .reg_req(vec_reg_req_port[4:1]),

                    .wb_reg_req_grant(reg_req_grant[7:5]),
                    //write back will only do write operation.
                    .wb_reg_rsp_vld(),
                    .wb_reg_rsp_data(),
                    .wb_reg_req(vec_reg_req_port[7:5]),

                    //icache interface
                    .icache_req(icache_req),
                    .icache_busy(icache_busy),
                    .icache_rsp(icache_rsp)

                    );  

    cache #(.CORE_ID(CORE_ID))
             icache (.clk(clk),
                     .reset(reset),
                     .set_associativity('0),
                     .associativity(),
                     //pipeline interface
                     .req(icache_req),
                     .busy(icache_busy),//will not accept new request when cache miss.
                     .rsp(icache_rsp),
                     //memory interface
                     .mem_rsp(icache_mem_rsp),
                     .req_grant(grant[0] && (!mem_req.vld || (mem_req_grant && mem_req.vld))),
                     .mem_req(icache_mem_req)
                    );

   arbiter_p #(.VECTOR_IN(MEM_REQ_PER_CORE))
             core_arbiter (.clk(clk),
                           .request_vector({load_store_unit_mem_req.vld, icache_mem_req.vld}),
                           .grant(grant)
                          );

   //request from core to memory.
   always_ff @(posedge clk or negedge reset) begin
      if(!reset) begin
         mem_req <= 0;
      end
      else if((mem_req_grant && mem_req.vld) || !mem_req.vld)begin
         unique case(grant)
            0: mem_req <= 0;
            1: mem_req <= icache_mem_req;
            2: mem_req <= load_store_unit_mem_req;
         endcase
      end
   end

   //response from memory to core.
   always_ff @(posedge clk or negedge reset) begin
      if(!reset) begin
         icache_mem_rsp <= 0;
         load_store_unit_mem_rsp <= 0;
      end
      else begin
         if(mem_rsp.vld) begin
            if(mem_rsp.access_id[6])//access_id(6) = 1 is a icahe response 
               icache_mem_rsp <= mem_rsp;
            else
               load_store_unit_mem_rsp <= mem_rsp;
         end
         else begin
            icache_mem_rsp <= 0;
            load_store_unit_mem_rsp <= 0;            
         end
      end
   end 

endmodule
