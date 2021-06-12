//____________________________________________________________________________________________________________________
//file name : wb.sv
//author : sivabalan
//description : This file holds the logic for write-back.
//____________________________________________________________________________________________________________________

module wb (input clk,
           input reset,
           //wb interface
           input reg result_vld [NUM_OF_LANES-1:0],
           input reg [$clog2(NUM_OF_VECTOR_REG)-1:0] vec_reg_out [NUM_OF_LANES-1:0],
           input reg data_out [NUM_OF_LANES-1:0],
           //vector register interface
           input wb_reg_req_grant [NUM_OF_WB-1:0],
           input wb_reg_rsp_vld [NUM_OF_WB-1:0],
           input [VECTOR_REG_WIDTH-1:0] wb_reg_rsp_data [NUM_OF_WB-1:0],
           output cntrl_req_t wb_reg_req [NUM_OF_WB-1:0],
           //write buffer full
           output reg wb_full                    
          ); 

   logic [NUM_OF_LANES-1:0] wb_grant;
   cntrl_req_t wb_req;

   arbiter_rr # (.VECTOR_IN(NUM_OF_LANES))
              wb_arbiter (.clk(clk),
                          .reset(reset),
                          .request_vector({result_vld[3], result_vld[2], result_vld[1], result_vld[0]}),
                          .grant(wb_grant)
                         );

   //functional unit request latching logic.
   always_ff @(posedge clk or negedge reset) begin
      if(!reset) begin
         wb_req <= 0;
      end
      else if(|wb_grant) begin
         for(int i=0; i<NUM_OF_LANES; i++) begin
            if(wb_grant[i]) begin
               wb_req.vld <= result_vld[i];
               wb_req.access_type <= WRITE_REQ;
               wb_req.access_length <= 1;
               wb_req.stride_type <= NON_STRIDE;
               wb_req.vec_reg_ptr <= vec_reg_out[i];
               wb_req.addr <= 0;//TODO
               wb_req.data <= data_out[i];
            end
         end       
      end
      else begin
         wb_req <= 0;
      end
   end

   //sending out write back request to the vector register
   //in three port.
   always_ff @(posedge clk or negedge reset) begin
      if(!reset) begin
         for(int i=0; i<NUM_OF_WB; i++) begin
            wb_reg_req[i] <= 0;
         end
      end
      else if(wb_req.vld) begin
         for(int i=0; i<NUM_OF_WB; i++) begin
            if (!wb_reg_req[i].vld || (wb_reg_req[i].vld && wb_reg_req_grant[i])) begin
               wb_reg_req[i].vld <= wb_req.vld;
               wb_reg_req[i].access_type <= wb_req.access_type;
               wb_reg_req[i].access_length <= wb_req.access_length;
               wb_reg_req[i].stride_type <= wb_req.stride_type;
               wb_reg_req[i].vec_reg_ptr <= wb_req.vec_reg_ptr;
               wb_reg_req[i].addr <= wb_req.addr;
               wb_reg_req[i].data <= wb_req.data;           
            end
         end
      end
      else begin
         for(int i=0; i<NUM_OF_WB; i++) begin
            wb_reg_req[i] <= 0;
         end
      end
   end

   assign wb_full = ((wb_reg_req[0].vld && !wb_reg_req_grant[0]) &&
                     (wb_reg_req[1].vld && !wb_reg_req_grant[1]) && 
                     (wb_reg_req[2].vld && !wb_reg_req_grant[2]));

endmodule