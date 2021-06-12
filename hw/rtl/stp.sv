//____________________________________________________________________________________________________________________
//file name : stp.sv
//author : sivabalan
//description : This file holds the logic for single threaded pipeline.
//____________________________________________________________________________________________________________________

module stp # (parameter CORE_ID = 0)
           (input clk,
            input reset,

            //load and store unit interface
            input load_store_unit_busy,
            output cntrl_req_t load_store_req,

            //vector register interface
            input reg_req_grant [NUM_OF_LANES-1:0],
            input reg_rsp_vld [NUM_OF_LANES-1:0],
            input [VECTOR_REG_WIDTH-1:0] reg_rsp_data [NUM_OF_LANES-1:0],
            output cntrl_req_t reg_req [NUM_OF_LANES-1:0],

            input wb_reg_req_grant [NUM_OF_WB-1:0],
            input wb_reg_rsp_vld [NUM_OF_WB-1:0],
            input [VECTOR_REG_WIDTH-1:0] wb_reg_rsp_data [NUM_OF_WB-1:0],
            output cntrl_req_t wb_reg_req [NUM_OF_WB-1:0],

            //icache interface
            output request_t icache_req,
            input reg icache_busy,
            input request_t icache_rsp

           );
   
   //execution unit interface
   logic inst_buff_full, opcode_vld;
   opcode_t opcode0, opcode1;
   //lane unit interface
   logic vld [NUM_OF_LANES-1:0];
   logic [VECTOR_REG_WIDTH-1:0] data0 [NUM_OF_LANES-1:0];
   logic [VECTOR_REG_WIDTH-1:0] data1 [NUM_OF_LANES-1:0];
   logic [$clog2(NUM_OF_VECTOR_REG)-1:0] vec_reg_in [NUM_OF_LANES-1:0];
   function_opcode_t functional_opcode [NUM_OF_LANES-1:0];
   logic busy [NUM_OF_LANES-1:0];
   //wb interface
   logic wb_full;
   logic wb_full_lane [NUM_OF_LANES-1:0];
   logic result_vld [NUM_OF_LANES-1:0];
   logic data_out [NUM_OF_LANES-1:0];
   logic [$clog2(NUM_OF_VECTOR_REG)-1:0] vec_reg_out [NUM_OF_LANES-1:0]; 

   ifetch_unit stp_if(.clk(clk),
                      .reset(reset),

                      //thread manager interface.
                      .tm_req(),
                      .tm_rsp(),

                      //core register interface
                      .CORE_BASE_ADDR(),

                      //icache interface
                      .icache_rsp(icache_rsp),
                      .icache_busy(icache_busy),
                      .icache_req(icache_req),

                      //execution stage interface
                      .inst_buff_full(inst_buff_full),
                      .opcode_vld(opcode_vld),
                      .opcode0(opcode0),
                      .opcode1(opcode1)

                     );

   iexecution_unit stp_iexe(.clk(clk),
                            .reset(reset),

                            //load and store unit interface
                            .load_store_req(load_store_req),
                            .load_store_unit_busy(load_store_unit_busy),
    
                            //ifetch unit interface 
                            .opcode_vld(opcode_vld),
                            .opcode0(opcode0),
                            .opcode1(opcode1),
                            .inst_buff_full(inst_buff_full),
    
                            //functional unit interface
                            .vld(vld),
                            .data0(data0),
                            .data1(data1),
                            .vec_reg_in(vec_reg_in),
                            .functional_opcode(functional_opcode),
                            .busy(busy),
    
                            //vector register interface
                            .reg_req_grant(reg_req_grant),
                            .reg_rsp_vld(reg_rsp_vld),
                            .reg_rsp_data(reg_rsp_data),
                            .reg_req(reg_req)

                           );

  lane stp_lane[NUM_OF_LANES-1:0] (.clk(clk),
                                   .reset(reset),
                     
                                   //execution unit interface
                                   .vld(vld),
                                   .data0(data0),
                                   .data1(data1),
                                   .vec_reg_in(vec_reg_in),
                                   .functional_opcode(functional_opcode),
                                   .busy(busy),

                                   //wb interface
                                   .result_vld(result_vld),
                                   .vec_reg_out(vec_reg_out),
                                   .data_out(data_out),
                                   .wb_full_lane(wb_full_lane)

                                  );

  //wb full indication to the lanes.
  always_comb begin
     for(int i=0; i<NUM_OF_LANES; i++) begin
        wb_full_lane[i] = wb_full;
     end
  end

  wb stp_wb(.clk(clk),
            .reset(reset),
            //lanes interface
            .result_vld(result_vld),
            .vec_reg_out(vec_reg_out),
            .data_out(data_out),
            //vector register interface
            .wb_reg_req_grant(wb_reg_req_grant),
            .wb_reg_rsp_vld(wb_reg_rsp_vld),
            .wb_reg_rsp_data(wb_reg_rsp_data),
            .wb_reg_req(wb_reg_req),
            //write buffer full
            .wb_full(wb_full)
           );

  core_register core_reg (.clk(clk),
                          .reset(reset)                
                         );

endmodule