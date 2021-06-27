//____________________________________________________________________________________________________________________
//file name : crossbar_switch.sv
//author : sivabalan
//description : This file holds the crossbar_switch logic.
//This module is responsible for inter-connecting the different lanes in a core with the core registers
//design spec : NUM_OF_PORT x NUM_OF_VECTOR_REG crossbar
//____________________________________________________________________________________________________________________

module crossbar_switch (input clk,
                        input reset,

                        input cntrl_req_t vec_reg_req_port [NUM_OF_PORT-1:0],

                        output reg [$clog2(VECTOR_REG_DEPTH)-1:0] vector_read_addr_port [NUM_OF_VECTOR_REG-1:0],
                        output reg vector_write_port [NUM_OF_VECTOR_REG-1:0],
                        output reg [$clog2(VECTOR_REG_DEPTH)-1:0] vector_write_addr_port [NUM_OF_VECTOR_REG-1:0],
                        output reg [VECTOR_REG_WIDTH-1:0] write_data [NUM_OF_VECTOR_REG-1:0],
                        output reg reg_req_grant [NUM_OF_PORT-1:0],
                        output reg rsp_vld [NUM_OF_PORT-1:0],
                        output reg [$clog2(VECTOR_REG_DEPTH)-1:0] rsp_addr_port [NUM_OF_VECTOR_REG-1:0]                    
                       );

    logic [NUM_OF_PORT-1:0] request [NUM_OF_VECTOR_REG], grant [NUM_OF_VECTOR_REG];
    logic [NUM_OF_PORT-1:0] weight [NUM_OF_VECTOR_REG][NUM_OF_PORT-1:0];

    logic [NUM_OF_PORT-1:0] grant_rev [NUM_OF_VECTOR_REG];

    //grant logic
    logic reg_req_grant_comb [NUM_OF_PORT-1:0];
    logic rsp_vld_comb [NUM_OF_PORT-1:0];

    always_comb begin
        for(int i = 0; i<NUM_OF_PORT; i++) begin
           for(int j = 0; j<NUM_OF_VECTOR_REG; j++) begin
              if(vec_reg_req_port[i].vld && (vec_reg_req_port[i].vec_reg_ptr == j)) begin
                 request[j][i] = 1;
                 weight[j][i] = vec_reg_req_port[i].access_length;
              end
              else begin
                 request[j][i] = 0 ;
              end
           end
        end
    end

    warbiter_rr #(.VECTOR_IN(NUM_OF_PORT))
                xbar_arbiter[NUM_OF_VECTOR_REG] (.clk(clk),
                                                 .reset(reset),
                                                 .request_vector(request),
                                                 .weight(weight),
                                                 .grant(grant)
                                                );

    //reverse the grant for port valid calculation
    always_comb begin
       for(int i=0; i<NUM_OF_VECTOR_REG; i++) begin
          for(int j=0; j<NUM_OF_PORT; j++) begin
             grant_rev[i][j] = grant[j][i];
          end
       end
    end
    always_comb begin
       for(int i = 0; i<NUM_OF_PORT; i++) begin
             reg_req_grant_comb[i] =  |grant_rev[i];
             rsp_vld_comb[i] = |grant_rev[i];
       end
    end
    //1cc delay to make the grant in sync with the vector register data.
    always_ff@(posedge clk or negedge reset) begin
       if(!reset) begin
          for(int i = 0; i<NUM_OF_PORT; i++) begin
             reg_req_grant[i] <= 0;
             rsp_vld[i] <= 0;
             rsp_addr_port[i] <= 0;
          end
       end
       else begin
          reg_req_grant <= reg_req_grant_comb;
          rsp_vld <= rsp_vld_comb;
          for(int i=0; i<NUM_OF_VECTOR_REG; i++) begin
             for(int j=0; j<NUM_OF_PORT; j++) begin
                if(grant[i][j]) begin
                   rsp_addr_port[j] <= i;
                end
             end
          end
       end
    end

    always_comb begin
        for(int i = 0; i<NUM_OF_VECTOR_REG; i++) begin
           for(int j = 0; j<NUM_OF_PORT; j++) begin
              if(grant[i][j] && vec_reg_req_port[i].vld && (vec_reg_req_port[i].vec_reg_ptr == i)) begin
                 vector_read_addr_port[j] = vec_reg_req_port[i].addr;
                 vector_write_port[j] = (vec_reg_req_port[i].access_type == WRITE_REQ);
                 vector_write_addr_port[j] = vec_reg_req_port[i].addr;
                 write_data[j] = vec_reg_req_port[i].data;
              end
           end
        end
    end

endmodule