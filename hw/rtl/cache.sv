//____________________________________________________________________________________________________________________
//file name : cache.sv
//author : sivabalan
//description : This file holds the blocking cache logic. This cache is desgined baed on adjustable set associativity.
//Can be configured from direct mapped to N-way set associativity.
//Source : Design of an adjustable-way set-associative cache(IEEE)
//____________________________________________________________________________________________________________________

module cache # (parameter CORE_ID = 0)
             (input clk,
              input reset,
              //cache associativity
              input set_associativity,
              input associativity_t associativity,
              //pipeline bit interface
              input request_t req,
              output reg busy,//will not accept new request when cache miss.
              output request_t rsp,
              //memory bit interface
              input request_t mem_rsp,
              input req_grant,
              output request_t mem_req
             );

    logic [SET_BIT_WIDTH-1:0] set, set_mask;
    logic [TAG_BIT_WIDTH-1:0] tag, tag_mask;
    logic [MAX_ASSOCIATIVITY-1:0] block_en, block_vld;
    logic [ADDR_FIELD_WIDTH-1:0] block_addr [MAX_ASSOCIATIVITY];
    logic [DATA_FIELD_WIDTH-1:0] block_data;
    logic [DATA_FIELD_WIDTH-1:0] block_data_arr [MAX_ASSOCIATIVITY];
    associativity_t cache_associativity;
    request_t req_ff;
    logic [ACCESS_ID_WIDTH-3:0] req_sent_count, rsp_rcvd_count;

    //cache memory
    logic [DATA_FIELD_WIDTH-1:0] cache_memory [MAX_ASSOCIATIVITY][CACHE_BLOCK_SIZE]; //8B x 32 x 8 = 2048B(2KB)
    logic [CACHE_BLOCK_SIZE-1:0] cache_hit_count [MAX_ASSOCIATIVITY];//to count number of hit to calculate LRU cache.
    logic cache_hit, cache_miss;
    logic cache_hit_arr1 [MAX_ASSOCIATIVITY];
    logic cache_miss_arr1 [MAX_ASSOCIATIVITY];
    logic [MAX_ASSOCIATIVITY] cache_hit_arr2, cache_miss_arr2;

    //LRU block for cache retention.
    logic lru_vld;
    logic [CACHE_BLOCK_SIZE-1:0] lru_block;


    always_ff @(posedge clk or negedge reset) begin
       if(!reset) begin
          req_ff <= 0;
          tag <= 0;
          set <= 0;
       end
       else if(req.vld && !busy) begin
          req_ff <= req;
          tag <= tag_mask & req.addr[SET_BIT_WIDTH+$clog2(CACHE_BLOCK_SIZE)-1:$clog2(CACHE_BLOCK_SIZE)];
          set <= set_mask & req.addr[TAG_BIT_WIDTH+$clog2(CACHE_BLOCK_SIZE)-1:$clog2(CACHE_BLOCK_SIZE)];
       end
       else if (cache_hit || (rsp_rcvd_count==CACHE_BLOCK_SIZE)) begin //request will be cleared once we recieve all the response.
          req_ff <= 0;
       end
    end

    always_ff @(posedge clk or negedge reset) begin
       if(!reset) begin
          cache_associativity <= ONE_WAY_ASSOCIATIVITY;
       end
       else if(set_associativity) begin
          cache_associativity <= associativity;
       end
    end
   
    always_ff @(posedge clk or negedge reset) begin
       if(!reset) begin
          tag_mask <= 0; set_mask <= 0;
       end
       else begin
          case(cache_associativity)
             ONE_WAY_ASSOCIATIVITY: begin set_mask <= 'h1f; tag_mask <= 'h0; end
             TWO_WAY_ASSOCIATIVITY: begin set_mask <= 'h1e; tag_mask <= 'h1; end
             FOUR_WAY_ASSOCIATIVITY: begin set_mask <= 'h1c; tag_mask <= 'h3; end
             EIGHT_WAY_ASSOCIATIVITY: begin set_mask <= 'h18; tag_mask <= 'h7; end
             SIXTEEN_WAY_ASSOCIATIVITY: begin set_mask <= 'h10; tag_mask <= 'hf; end
             THIRTYTWO_WAY_ASSOCIATIVITY: begin set_mask <= 'h0; tag_mask <= 'h1f; end
          endcase
       end
    end

    always_comb begin
       block_en = 0;
       if((req.vld && !busy) || req_ff.vld) begin
          case(cache_associativity)
             ONE_WAY_ASSOCIATIVITY: begin 
                                       for(bit [SET_BIT_WIDTH-1:0] i=0; i<MAX_ASSOCIATIVITY; i++)
                                       begin
                                          if(set == i)
                                             block_en[i] = 1;
                                       end
                                    end
             TWO_WAY_ASSOCIATIVITY: begin 
                                       for(bit [SET_BIT_WIDTH-1:0] i=0; i<MAX_ASSOCIATIVITY; i++)
                                       begin
                                          if(set == (i/2))
                                             block_en[i] = 1;
                                       end
                                    end
             FOUR_WAY_ASSOCIATIVITY: begin 
                                        for(bit [SET_BIT_WIDTH-1:0] i=0; i<MAX_ASSOCIATIVITY; i++)
                                        begin
                                           if(set == (i/4))
                                              block_en[i] = 1;
                                        end
                                     end
             EIGHT_WAY_ASSOCIATIVITY: begin 
                                         for(bit [SET_BIT_WIDTH-1:0] i=0; i<MAX_ASSOCIATIVITY; i++)
                                         begin
                                            if(set == (i/8))
                                               block_en[i] = 1;
                                         end
                                      end
             SIXTEEN_WAY_ASSOCIATIVITY: begin 
                                           for(bit [SET_BIT_WIDTH-1:0] i=0; i<MAX_ASSOCIATIVITY; i++)
                                           begin
                                              if(set == (i/16))
                                                 block_en[i] = 1;     
                                           end
                                        end
             THIRTYTWO_WAY_ASSOCIATIVITY: begin 
                                             for(bit [SET_BIT_WIDTH-1:0] i=0; i<MAX_ASSOCIATIVITY; i++)
                                             begin
                                                block_en[i] = 1;
                                             end
                                          end
          endcase
       end    
    end

    //cache hit/miss logic
    generate for(genvar i=0; i<MAX_ASSOCIATIVITY; i++) begin
       always_comb begin
          cache_hit_arr1[i] = 0;
          cache_miss_arr1[i] = 0;
          block_data_arr[i] = 0;
          if(block_en[i]) begin
             if(block_vld[i] && req_ff.vld && (tag == (tag_mask & block_addr[i][ADDR_FIELD_WIDTH-1:TAG_BIT_WIDTH+$clog2(CACHE_BLOCK_SIZE)]))) begin
                cache_hit_arr1[i] = 1;
                cache_miss_arr1[i] = 0;
                block_data_arr[i] = cache_memory[i][req_ff.addr[$clog2(CACHE_BLOCK_SIZE)-1:0]];
             end
          end
       end
    end endgenerate

    //streaming the hit/miss/data from cache
    always_comb begin
       cache_hit_arr2 = {>> 1{cache_hit_arr1}};
       cache_hit = |cache_hit_arr2;
       cache_miss = !cache_hit;
    end

    always_comb begin
       for(int i=0; i<MAX_ASSOCIATIVITY; i++) begin
          if(cache_hit_arr1[i]) block_data = block_data_arr[i];
       end
    end

    generate for(genvar i=0; i<MAX_ASSOCIATIVITY; i++) begin
       always_ff @(posedge clk or negedge reset) begin
          if(!reset) begin
             cache_hit_count[i] <= 0;
          end
          else if(block_en[i]) begin
             if(block_vld[i] && req_ff.vld && (tag == (tag_mask & block_addr[i][ADDR_FIELD_WIDTH-1:TAG_BIT_WIDTH+$clog2(CACHE_BLOCK_SIZE)])))
             begin
                cache_hit_count[i] <= cache_hit_count[i] + 1;
             end
          end
       end
    end endgenerate

    //response to pipeline for hit and miss
    always_ff @(posedge clk or negedge reset) begin
       if(!reset) begin
          rsp <= 0;
       end
       else if(cache_hit) begin
          rsp.vld <= 1;
          rsp.access_type <= READ_RSP;
          rsp.access_id <= 0;
          rsp.core_id <= 0;
          rsp.addr <= req_ff.addr;
          rsp.byte_en <= 0;
          rsp.data <= block_data;
       end
       else if (cache_miss && mem_rsp.vld && (mem_rsp.access_id == 64)) begin//send only the first response.
          rsp.vld <= 1;
          rsp.access_type <= READ_RSP;
          rsp.access_id <= 0;
          rsp.core_id <= 0;
          rsp.addr <= req_ff.addr;
          rsp.byte_en <= 0;
          rsp.data <= mem_rsp.data;
       end
       else begin
          rsp <= 0;
       end
    end

    //request to memory for miss
    always_ff @(posedge clk or negedge reset) begin
       if(!reset) begin
          mem_req <= 0;
          req_sent_count <= 0;
       end
       else if((!mem_req.vld || (mem_req.vld && req_grant)) && req_ff.vld && cache_miss && |block_en && (req_sent_count < CACHE_BLOCK_SIZE)) begin
          mem_req.vld <= 1;
          mem_req.access_type <= READ_REQ;
          mem_req.access_length <= CACHE_BLOCK_SIZE;
          mem_req.access_id <= {2'b01, req_sent_count};//64 to 127 for icache.
          mem_req.core_id <= CORE_ID;
          mem_req.addr <= req_ff.addr + req_sent_count;
          mem_req.byte_en <= 0;
          mem_req.data <= 0;
          req_sent_count <= req_sent_count + 1;
       end
       else if (req_sent_count == rsp_rcvd_count) begin
          req_sent_count <= 0;
       end
       else if (req_sent_count == CACHE_BLOCK_SIZE) begin
          mem_req <= 0;
       end
    end

    //empty blocks are filled first. If all blocks are full, then the eviction 
    //is done based on the LRU.
    always_comb begin
       lru_block = {CACHE_BLOCK_SIZE{1'b1}};
       for(int i=0; i<MAX_ASSOCIATIVITY; i++) begin
          if(block_en[i] && (lru_block > cache_hit_count[i]))
             lru_block = i;
       end    
    end

    assign lru_vld = & (block_en ~^ block_vld);

    //update cache when cache miss
    always_ff @(posedge clk or negedge reset) begin
       if(!reset) begin
          rsp_rcvd_count <= 0;
          block_vld <= 0;
       end
       else if (cache_miss && mem_rsp.vld) begin
          if (rsp_rcvd_count<CACHE_BLOCK_SIZE)
             rsp_rcvd_count <= rsp_rcvd_count + 1;
          else if (rsp_rcvd_count==CACHE_BLOCK_SIZE)
             rsp_rcvd_count <= 0;
          for(int i=0; i<MAX_ASSOCIATIVITY; i++) begin
             if((!block_vld[i] || (lru_vld && (i==lru_block))) && block_en[i] && req_ff.vld) begin
                block_addr[i] <= req_ff.addr & 64'h7;
                cache_memory[i][mem_rsp.addr[$clog2(CACHE_BLOCK_SIZE)-1:0]] <= mem_rsp.data;
             end
          end
       end
       else if (rsp_rcvd_count==CACHE_BLOCK_SIZE) begin
          block_vld <= block_en;
          rsp_rcvd_count <= 0;
       end
    end   

   assign busy = cache_miss && (req_ff.vld);//will be available to pipeline in the next cycle.

endmodule