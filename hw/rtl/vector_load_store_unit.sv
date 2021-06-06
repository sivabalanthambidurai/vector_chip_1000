//____________________________________________________________________________________________________________________
//file name : vector_load_store_unit.sv
//author : sivabalan
//description : This file holds the vector load and store unit. This module is responsible for generating memory read and 
//write request.  
//____________________________________________________________________________________________________________________


module vector_load_store_unit # (parameter CORE_ID = 8)
                              (input clk,
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
  logic write_ready, read_complete; 
  //write_ready -> indicates the write data is ready to start the write operation.
  //read_ready -> indicates the read data from memory completly written in to register.
  logic request_ready, response_ready;
  logic [REQUEST_COUNTER_WIDTH-1:0] reg_req_sent, reg_rsp_rcvd;

  always_ff @(posedge clk or negedge reset) begin
     if(!reset) begin
        cntrl_req_ff <= 'h0;
        request_count <= 'h0;
        req_sent_count <= 'h0;
        rsp_rcvd_count <= 'h0;
        reg_req_sent <= 0;
        reg_rsp_rcvd <= 0;
        rsp_rcvd <= 0;
     end
     else if(cntrl_req.vld && !buffer_full) begin
        cntrl_req_ff <= cntrl_req;
        request_count <= cntrl_req.access_length;
        req_sent_count <= 'h0;
        rsp_rcvd_count <= cntrl_req.access_length;
        reg_req_sent <= 0;
        reg_rsp_rcvd <= 0;
     end
     else begin
        if(mem_req.vld)
           req_sent_count <= req_sent_count + 1;
        if(mem_rsp.vld) begin
           rsp_rcvd_count <= rsp_rcvd_count + 1;
           rsp_rcvd <= 1;
        end
        else
          rsp_rcvd <= 0;
        if(reg_req.vld)
           reg_req_sent <= reg_req_sent + 1;
        if(reg_rsp_vld)
           reg_rsp_rcvd <= reg_rsp_rcvd + 1;
     end
  end

  assign request_ready = ((cntrl_req_ff.access_type == READ_REQ) || ((cntrl_req_ff.access_type == WRITE_REQ) && reg_rsp_vld));
  assign response_ready = (((cntrl_req_ff.access_type == READ_REQ) && read_complete) || (cntrl_req_ff.access_type == WRITE_REQ));
  assign write_ready = (reg_rsp_rcvd == cntrl_req_ff.access_length);
  assign read_complete = (reg_rsp_rcvd == cntrl_req_ff.access_length);

  always_ff @(posedge clk or negedge reset) begin
     if(!reset)
        mem_req <= 'h0;
     else if(request_ready && (req_sent_count < request_count) && (!mem_req.vld || (mem_req.vld && req_grant))) begin
        mem_req.vld <= 1;
        mem_req.access_type <= cntrl_req_ff.access_type;
        mem_req.access_id <= (req_sent_count == 0) ? 0 : mem_req.access_id + 1;
        mem_req.core_id <= CORE_ID;
        mem_req.addr <= cntrl_req_ff.addr + 8*mem_req.access_id;
        mem_req.byte_en <= 'hff;
        mem_req.data <= reg_rsp_data;
     end
     else if((req_sent_count == request_count) || req_grant)
        mem_req <= 'h0;
  end

assign buffer_full = (((request_count != rsp_rcvd_count) && (cntrl_req_ff.access_type == WRITE_REQ)) ||
                     ((cntrl_req_ff.access_type == READ_REQ) && read_complete)) ? 1 : 0;

  //register request and response logic
  always_ff @(posedge clk or negedge reset) begin
     if(!reset)
        reg_req <= 0;
     else if((!reg_req.vld || (reg_req.vld && mem_rsp.vld)) && (reg_req_sent < request_count)) begin
        reg_req.vld <= 1;       
        reg_req.access_length <= cntrl_req_ff.access_length;
        reg_req.vec_reg_ptr <= cntrl_req_ff.vec_reg_ptr;
        reg_req.addr <= cntrl_req.addr + reg_req_sent;
        if(cntrl_req_ff.access_type == READ_REQ) begin
           reg_req.access_type <= WRITE_REQ;
           reg_req.data <= mem_rsp.data;
        end
        else if (cntrl_req_ff.access_type == WRITE_REQ) begin
           reg_req.access_type <= READ_REQ;
           reg_req.data <= 0;
        end
     end
     else if((reg_req_sent == request_count) || mem_rsp.vld)
        reg_req <= 'h0;
  end

endmodule