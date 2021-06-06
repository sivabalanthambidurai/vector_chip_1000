//____________________________________________________________________________________________________________________
//file name : vector_load_store_unit.sv
//author : sivabalan
//description : This file holds the vector load and store unit. This module is responsible for generating memory read and 
//write request.  
//____________________________________________________________________________________________________________________


module vector_load_store_unit (input clk,
                               input reset,

                               //execution unit interface
                               input cntrl_req_t cntrl_req,
                               output reg buffer_full,

                               //vector register interface
                               input reg_rsp_vld,
                               input [VECTOR_REG_WIDTH-1:0] reg_rsp_data,
                               output cntrl_req_t reg_req,

                               //memory request interface
                               input request_t mem_rsp,
                               output reg rsp_rcvd,
                               input req_grant,
                               output request_t mem_req
                               );
  
  //load and store buffer. Can supppot only one vector load or store with maximum size of 64.
  logic [REQUEST_COUNTER_WIDTH-1:0] request_count, req_sent_count, rsp_rcvd_count;
  cntrl_req_t cntrl_req_ff;


  always_ff @(posedge clk or negedge reset) begin
     if(!reset)
        cntrl_req_ff <= 'h0;
     else if(cntrl_req.vld && !buffer_full)
        cntrl_req_ff <= cntrl_req;
  end
  
  always_ff @(posedge clk or negedge reset) begin
     if(!reset)
        request_count <= 'h0;
     else if(cntrl_req.vld && !buffer_full) 
        request_count <= cntrl_req.access_length;
  end

  always_ff @(posedge clk or negedge reset) begin
     if(!reset)
        req_sent_count <= 'h0;
     else if(cntrl_req.vld && !buffer_full)
        req_sent_count <= 'h0;
     else if(mem_req.vld)
        req_sent_count <= req_sent_count + 1;
  end

  always_ff @(posedge clk or negedge reset) begin
     if(!reset)
        rsp_rcvd_count <= 'h0;
     else if(cntrl_req.vld && !buffer_full)
        rsp_rcvd_count <= cntrl_req.access_length;
     else if(mem_rsp.vld)
        rsp_rcvd_count <= rsp_rcvd_count + 1;
  end

  always_ff @(posedge clk or negedge reset) begin
     if(!reset)
        mem_req <= 'h0;
     else if((req_sent_count < request_count) && (!mem_req.vld || (mem_req.vld && req_grant))) begin
        mem_req.vld <= 1;
        mem_req.access_type <= cntrl_req.access_type;
        mem_req.access_id <= (req_sent_count == 0) ? 0 : mem_req.access_id + 1;
        //mem_req.core_id <= 0 TODO : FIXME
        mem_req.addr <= cntrl_req.addr + 8*mem_req.access_id;
        mem_req.byte_en <= 'hff;
        //mem_req.data <= 0 TODO : FIXME
     end
     else if(req_sent_count == request_count)
        mem_req <= 'h0;
  end


assign buffer_full = (request_count != rsp_rcvd_count) ? 1 : 0;

endmodule