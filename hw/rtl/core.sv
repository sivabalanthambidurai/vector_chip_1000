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
             output request_t mem_req
            );

  //8 read and 8 write ports for 8 vector register. (1 read + 1 write port per vector register)
  logic [$clog2(VECTOR_REG_DEPTH)-1:0] vector_read_addr_port [NUM_OF_VECTOR_REG-1:0];
  logic vector_write_port [NUM_OF_VECTOR_REG-1:0];
  logic [$clog2(VECTOR_REG_DEPTH)-1:0] vector_write_addr_port [NUM_OF_VECTOR_REG-1:0];
  logic [VECTOR_REG_WIDTH-1:0] write_data [NUM_OF_VECTOR_REG-1:0];
  logic [VECTOR_REG_WIDTH-1:0] vector_read_data_port [NUM_OF_VECTOR_REG-1:0];
  logic vector_read_data_port_vld [NUM_OF_PORT-1:0];
  logic [$clog2(VECTOR_REG_DEPTH)-1:0] vector_rsp_addr_port [NUM_OF_VECTOR_REG-1:0];
  //req and rsp port.
  cntrl_req_t vec_reg_req_port [NUM_OF_PORT-1:0];

  vector_register vector_reg[NUM_OF_VECTOR_REG-1:0] (.clk(clk), 
                                                     .reset(reset),
                                                     .read_addr(vector_read_addr_port),
                                                     .write(vector_write_port),
                                                     .write_addr(vector_write_addr_port),
                                                     .write_data(write_data),
                                                     .reg_data(vector_read_data_port)
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
                       .rsp_vld(vector_read_data_port_vld),
                       .rsp_addr_port(vector_rsp_addr_port)
                       );


  vector_load_store_unit # (.CORE_ID(CORE_ID))
                         load_store_unit(.clk(clk),
                                         .reset(reset),

                                        //execution unit interface
                                        .cntrl_req(),
                                        .buffer_full(),

                                        //vector register interface
                                        .reg_rsp_vld(vector_read_data_port_vld[0]),
                                        .reg_rsp_data(vector_read_data_port[vector_rsp_addr_port[0]]),
                                        .reg_req(vec_reg_req_port[0]),

                                        //memory request interface
                                        .mem_rsp(),
                                        .rsp_rcvd(),
                                        .req_grant(),
                                        .mem_req()
                                        );

endmodule
