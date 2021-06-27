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
                               input reg_req_grant,
                               input reg_rsp_vld,
                               input [VECTOR_REG_WIDTH-1:0] reg_rsp_data,
                               output cntrl_req_t reg_req,

                               //memory request interface
                               input request_t mem_rsp,
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

  //memory response.
  request_t mem_rsp_buffer [VECTOR_REG_DEPTH];
  logic [$clog2(VECTOR_REG_DEPTH)-1:0] mrsp_buff_wptr, mrsp_buff_rptr;
  //no need for full and emtpy logic, as there will not be 
  //more than 64 active request or response. And all the 
  //load and store are blocking.
  always_ff @(posedge clk or negedge reset) begin
     if(!reset) begin
        mrsp_buff_wptr <= 0;
     end
     else if (mem_rsp.vld) begin
        mem_rsp_buffer[mrsp_buff_wptr] <= mem_rsp;
        mrsp_buff_wptr <= mrsp_buff_wptr + 1;
     end
  end

  //vector register response.
  request_t vreg_rsp_buffer [VECTOR_REG_DEPTH];
  logic [$clog2(VECTOR_REG_DEPTH)-1:0] vrsp_buff_wptr, vrsp_buff_rptr;
  //no need for full and emtpy logic, as there will not be 
  //more than 64 active request or response. And all the 
  //load and store are blocking.
  always_ff @(posedge clk or negedge reset) begin
     if(!reset) begin
        vrsp_buff_wptr <= 0;
     end
     else if (reg_rsp_vld) begin
        vreg_rsp_buffer[vrsp_buff_wptr] <= reg_rsp_data;
        vrsp_buff_wptr <= vrsp_buff_wptr + 1;
     end
  end


  always_ff @(posedge clk or negedge reset) begin
     if(!reset) begin
        cntrl_req_ff <= 'h0;
        request_count <= 'h0;
        rsp_rcvd_count <= 'h0;
        reg_rsp_rcvd <= 0;
     end
     else if(cntrl_req.vld && !buffer_full) begin
        cntrl_req_ff <= cntrl_req;
        request_count <= cntrl_req.access_length;
        rsp_rcvd_count <= 'h0;
        reg_rsp_rcvd <= 0;
     end
     else begin        
        if(mem_rsp.vld)
           rsp_rcvd_count <= rsp_rcvd_count + 1;
        if(reg_rsp_vld)
           reg_rsp_rcvd <= reg_rsp_rcvd + 1;
        if(!buffer_full)
           cntrl_req_ff <= 0;
     end
  end

  assign request_ready = ((cntrl_req_ff.access_type == READ_REQ) || (cntrl_req_ff.access_type == WRITE_REQ));
  assign response_ready = (((cntrl_req_ff.access_type == READ_REQ) && read_complete) || (cntrl_req_ff.access_type == WRITE_REQ));
  assign write_ready = (reg_rsp_rcvd == cntrl_req_ff.access_length);
  assign read_complete = (reg_rsp_rcvd == cntrl_req_ff.access_length);

  always_ff @(posedge clk or negedge reset) begin
     if(!reset) begin
        mem_req <= 'h0;
        req_sent_count <= 0;
     end
     else if(request_ready && (req_sent_count < request_count) && (!mem_req.vld || (mem_req.vld && req_grant))) begin
        mem_req.vld <= 1;
        mem_req.access_type <= cntrl_req_ff.access_type;
        mem_req.access_length <= cntrl_req_ff.access_length;
        mem_req.access_id <= req_grant ?  mem_req.access_id + 1 : 0;
        mem_req.core_id <= CORE_ID;
        mem_req.addr <= req_grant ?  mem_req.addr + 1 : 0;
        mem_req.byte_en <= 'hff;
        mem_req.data <= vreg_rsp_buffer[vrsp_buff_rptr];
        req_sent_count <= req_sent_count + 1;
        vrsp_buff_rptr <= vrsp_buff_rptr + 1;
     end
     else if(req_sent_count == request_count) begin
        mem_req <= 'h0;
        if(!buffer_full)
           req_sent_count <= 0;
     end
  end

assign buffer_full = (((request_count != rsp_rcvd_count) && (cntrl_req_ff.access_type == WRITE_REQ)) ||
                     ((cntrl_req_ff.access_type == READ_REQ) && !read_complete)) ? 1 : 0;

  //register request and response logic
  always_ff @(posedge clk or negedge reset) begin
     if(!reset) begin
        reg_req <= 0;
        mrsp_buff_rptr <= 0;
        reg_req_sent <= 0;
     end
     else if((!reg_req.vld || (reg_req.vld && reg_req_grant)) && (((cntrl_req_ff.access_type == READ_REQ) && (reg_req_sent < rsp_rcvd_count))
             || ((cntrl_req_ff.access_type == WRITE_REQ) && (reg_req_sent < request_count)))) begin
        reg_req.vld <= 1;       
        reg_req.access_length <= cntrl_req_ff.access_length;
        reg_req.vec_reg_ptr <= cntrl_req_ff.vec_reg_ptr;
        reg_req.addr <= reg_req.vld ? reg_req.addr + 1 : 0;
        if(cntrl_req_ff.access_type == READ_REQ) begin
           reg_req.access_type <= WRITE_REQ;
           reg_req.data <= mem_rsp_buffer[mrsp_buff_rptr].data;
           mrsp_buff_rptr <= mrsp_buff_rptr + 1;
        end
        else if (cntrl_req_ff.access_type == WRITE_REQ) begin
           reg_req.access_type <= READ_REQ;
           reg_req.data <= 0;
        end
        reg_req_sent <= reg_req_sent + 1;
     end
     else if(((cntrl_req_ff.access_type == READ_REQ) && (reg_req_sent == rsp_rcvd_count)) || ((cntrl_req_ff.access_type == WRITE_REQ) && (reg_req_sent == request_count))) begin
        reg_req <= 'h0;
        if(!buffer_full)
           reg_req_sent <= 0;
     end
  end

endmodule