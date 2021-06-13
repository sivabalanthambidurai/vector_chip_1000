//____________________________________________________________________________________________________________________
//file name : iexecution_unit.sv
//author : sivabalan
//description : This file holds the logic for execution fetch unit
//____________________________________________________________________________________________________________________

typedef struct packed {
   bit [63:32] MASK;
   bit [31:0] LENGTH;
} exe_vector_reg_t; 

module iexecution_unit (input clk,
                        input reset,

                        //load and store unit interface
                        output cntrl_req_t load_store_req,
                        input load_store_unit_busy,

                        //ifetch unit interface 
                        input reg opcode_vld,
                        input opcode_t opcode0,
                        input opcode_t opcode1,
                        output reg inst_buff_full,

                        //functional unit interface
                        output reg vld [NUM_OF_LANES-1:0],
                        output reg [VECTOR_REG_WIDTH-1:0] data0 [NUM_OF_LANES-1:0],
                        output reg [VECTOR_REG_WIDTH-1:0] data1 [NUM_OF_LANES-1:0],
                        output reg [$clog2(NUM_OF_VECTOR_REG)-1:0] vec_reg_in [NUM_OF_LANES-1:0],
                        output reg [ADDR_FIELD_WIDTH-1:0] vec_addr,
                        output function_opcode_t functional_opcode [NUM_OF_LANES-1:0],
                        input reg busy [NUM_OF_LANES-1:0],

                        //vector register interface
                        input reg_req_grant [NUM_OF_LANES-1:0],
                        input reg_rsp_vld [NUM_OF_LANES-1:0],
                        input [VECTOR_REG_WIDTH-1:0] reg_rsp_data [NUM_OF_LANES-1:0],
                        output cntrl_req_t reg_req [NUM_OF_LANES-1:0]

                       );

    logic buffer0_full, buffer1_full, buffer0_empty, buffer1_empty,
          buffer0_rsp, buffer1_rsp, buffer0_rsp_ff, buffer1_rsp_ff;
    //exe_unit_active : Indicates that execution unit is Active.
    logic exe_unit_active;
    logic all_lanes_busy;
    logic [NUM_OF_LANES-1:0] busy_vector;
    logic [$clog2(NUM_OF_LANES)-1:0] next_free_lane;//indicates the next free lane.
    logic [$clog2(NUM_OF_LANES)-1:0] prev_free_lane;//indicates the previous free lane. To clear the valid bit.

    opcode_t buffer0_opcode, buffer1_opcode;
    vopcode_t opcode;
    logic [PIPELINE_OPCODE_WIDTH-1:0] movimm;
    logic [VECTOR_REG_WIDTH-1:0] reg1, reg2, reg3;
    logic reg1_rcvd, reg2_rcvd, reg3_rcvd;

    //Register : EXE_VECTOR_REG
    //LENGTH : This field indicates the length of the vector operation.
    //MASK : This field uses mask to execute conditional codes.
    exe_vector_reg_t EXE_VECTOR_REG;
    logic [31:0] vector_length;

    //scalar register
   logic write;
   logic [$clog2(SCALAR_REG_DEPTH)-1:0] rd_access_ptr, wr_access_ptr;
   logic [$clog2(SCALAR_REG_DEPTH)-1:0] wr_access_ptr_ff;
   logic [SCALAR_REG_WIDTH-1:0] write_data;
   logic [SCALAR_REG_WIDTH-1:0] read_data;
   //floaing point register
   logic fwrite;
   logic [$clog2(SCALAR_REG_DEPTH)-1:0] rd_faccess_ptr, wr_faccess_ptr;
   logic [SCALAR_REG_WIDTH-1:0] fwrite_data;
   logic [SCALAR_REG_WIDTH-1:0] fread_data;

    scalar_register scalar_reg (.clk(clk),
                                .reset(reset),
                                //scalar register access
                                .write(write),
                                .rd_access_ptr(rd_access_ptr),
                                .wr_access_ptr(wr_access_ptr),
                                .write_data(write_data),
                                .read_data(read_data),

                                 //floaing point register access
                                .fwrite(),
                                .rd_faccess_ptr(),
                                .wr_faccess_ptr(),
                                .fwrite_data(),
                                .fread_data() 

                               );

   //accessing the scalar register to avoid one cycle delay.
   always_comb begin
      case (opcode)
         LV     : begin
                     rd_access_ptr = reg2[$clog2(SCALAR_REG_DEPTH)-1:0];
                  end
         SV     : begin
                     rd_access_ptr = reg1[$clog2(SCALAR_REG_DEPTH)-1:0];
                  end
         MTC1   : begin
                     rd_access_ptr = reg2[$clog2(SCALAR_REG_DEPTH)-1:0];
                  end
         MFC1   : begin
                     write = 1;
                     wr_access_ptr = reg1[$clog2(SCALAR_REG_DEPTH)-1:0];
                     write_data = EXE_VECTOR_REG.LENGTH;
                  end
         MOV_IMM_DATA : begin
                           write = 1;
                           wr_access_ptr = wr_access_ptr_ff;
                           write_data = movimm;
                        end
         default : begin
                      write = 0;
                      wr_access_ptr = 0;
                      rd_access_ptr = 0;
                      rd_faccess_ptr = 0;
                      write_data = 0;
                   end
      endcase
   end

    //TODO: Need to identify the dependecy between the opcode0 and opcode1.
    //If the dependency exists, then the two opcodes should be sent to same
    //buffer(Chaining).

    //buffer0 stores the opcode from channel opcode0
    buffer buffer0 (.clk(clk),
                    .reset(reset),
                    //buffer input
                    .req(opcode_vld),
                    .req_data(opcode0),
                    .full(buffer0_full),
                    //buffer output
                    .rsp(buffer0_rsp_ff && !exe_unit_active),
                    .empty(buffer0_empty),
                    .rsp_data(buffer0_opcode)
                   );

    //buffer1 stores the opcode from channel opcode1
    buffer buffer1 (.clk(clk),
                    .reset(reset),
                    //buffer input
                    .req(opcode_vld),
                    .req_data(opcode1),
                    .full(buffer1_full),
                    //buffer output
                    .rsp(buffer1_rsp_ff && !exe_unit_active),
                    .empty(buffer1_empty),
                    .rsp_data(buffer1_opcode)
                   );

    assign inst_buff_full = buffer0_full || buffer1_full;

    arbiter_rr # (.VECTOR_IN(2))
               exe_arb (.clk(clk),
                        .reset(reset),
                        .request_vector({!buffer1_empty && !exe_unit_active, !buffer0_empty && !exe_unit_active}),
                        .grant({buffer1_rsp, buffer0_rsp})
                       );

   `flip_flop(clk,reset,buffer0_rsp && !exe_unit_active,buffer0_rsp_ff)
   `flip_flop(clk,reset,buffer1_rsp && !exe_unit_active,buffer1_rsp_ff)
   
    //opcode fetching logic.
    always_ff@(posedge clk or negedge reset) begin
       if(!reset) begin
          opcode <= NO_OP;
          reg1 <= 0;
          reg2 <= 0;
          reg3 <= 0;
       end
       else if(buffer0_rsp) begin
          if(opcode == MOV_IMM) begin
             opcode <= MOV_IMM_DATA;
             movimm <= buffer0_opcode;
          end
          else begin
             opcode <= vopcode_t'(buffer0_opcode[31:24]);
             reg1 <= buffer0_opcode[23:16];
             reg2 <= buffer0_opcode[15:8];
             reg3 <= buffer0_opcode[7:0];
          end
       end
       else if(buffer1_rsp) begin
          if(opcode == MOV_IMM) begin
             opcode <= MOV_IMM_DATA;
             movimm <= buffer1_opcode;
          end
          else begin
             opcode <= vopcode_t'(buffer1_opcode[31:24]);
             reg1 <= buffer0_opcode[23:16];
             reg2 <= buffer0_opcode[15:8];
             reg3 <= buffer0_opcode[7:0];
          end
       end
    end

    //all lanes busy finder
    always_comb begin
       busy_vector = {>> 1{busy}};
       all_lanes_busy = &busy_vector;
    end

    //next free lane finder.
    always_comb begin
       next_free_lane = 0;
       for(int i=NUM_OF_LANES-1; i>=0; i++) begin
          if(!busy[i]) begin
             next_free_lane = i;
          end
       end
    end
    
    //execution unit
    always_ff @(posedge clk or negedge reset) begin
       if(!reset) begin
          EXE_VECTOR_REG <= 0;
       end
       else begin
          case (opcode)
             NO_OP   : begin
                       end
             ADDVVD  : begin
                          if(EXE_VECTOR_REG.LENGTH < vector_length)  begin
                             exe_unit_active <= 1;
                             vector_length <= vector_length + 1;
                             if(busy[prev_free_lane])
                                vld[prev_free_lane] <= 0;
                             //register1 rsp
                             if(reg_rsp_vld[0]) begin
                                data0[next_free_lane] <= reg_rsp_data[0];
                                if(!reg_rsp_vld[1])
                                   reg1_rcvd <= 1;
                                else 
                                   reg1_rcvd <= 0;
                             end
                             //register2 rsp
                             if(reg_rsp_vld[1]) begin
                                data1[next_free_lane] <= reg_rsp_data[1];
                                if(!reg_rsp_vld[0])
                                   reg2_rcvd <= 1;
                                else 
                                   reg2_rcvd <= 0;
                             end
                             vec_reg_in[next_free_lane] <= reg3; 
                             functional_opcode[next_free_lane] <= SADD;
                             if((reg_rsp_vld[0] && reg_rsp_vld[1]) || (reg1_rcvd && reg_rsp_vld[1]) || (reg2_rcvd && reg_rsp_vld[0])) begin
                                vld[next_free_lane] <= 1;
                             end
                             else
                                vld[next_free_lane] <= 0;
                             //regiser1 req
                             if(reg_req[0].vld && reg_req_grant[1] && reg_req_grant[0] && !reg_req[0].vld) begin
                                reg_req[0].vld <= 1;
                                reg_req[0].access_type <= READ_REQ;
                                reg_req[0].access_length <= EXE_VECTOR_REG.LENGTH;
                                reg_req[0].stride_type <= NON_STRIDE;
                                reg_req[0].vec_reg_ptr <= v_register_t'(reg1);
                                reg_req[0].addr <= vector_length;
                                vec_addr[next_free_lane] <= vector_length;
                                reg_req[0].data <= 0;
                             end
                             else begin
                                reg_req[0] <= 0;
                             end
                             //regiser2 req
                             if(reg_req[1].vld && reg_req_grant[1] && reg_req_grant[0] && !reg_req[1].vld) begin
                                reg_req[1].vld <= 1;
                                reg_req[1].access_type <= READ_REQ;
                                reg_req[1].access_length <= EXE_VECTOR_REG.LENGTH;
                                reg_req[1].stride_type <= NON_STRIDE;
                                reg_req[1].vec_reg_ptr <= v_register_t'(reg2);
                                reg_req[1].addr <= vector_length;
                                reg_req[1].data <= 0;
                             end
                             else begin
                                reg_req[1] <= 0;
                             end
                          end
                          else if (vld[0] && (EXE_VECTOR_REG.LENGTH == vector_length)) begin
                             exe_unit_active <= 0; 
                          end
                       end
             ADDVSD  : begin
                       end
             SUBVVD  : begin
                       end
             SUBVSD  : begin
                       end
             SUBSVD  : begin
                       end
             MULVVD  : begin
                       end
             MULVSD  : begin
                       end
             DIVVVD  : begin
                       end
             DIVVSD  : begin
                       end
             DIVSVD  : begin
                       end
             LV      : begin//LV is a blocking instruction
                          if(!exe_unit_active)
                             exe_unit_active <= 1;
                          else if(!load_store_unit_busy)
                             exe_unit_active <= 0;
                          load_store_req.vld <= 1;
                          load_store_req.access_type <= READ_REQ;
                          load_store_req.access_length <= 0;
                          load_store_req.stride_type <= NON_STRIDE;
                          load_store_req.vec_reg_ptr <= v_register_t'(reg1);
                          load_store_req.addr <= read_data;
                          load_store_req.data <= 0;
                       end
             LVI     : begin
                       end
             LVWS    : begin
                       end
             SV      : begin//SV is non-blocking
                          if(load_store_unit_busy)
                             exe_unit_active <= 1;
                          else
                             exe_unit_active <= 0;
                          load_store_req.vld <= 1;
                          load_store_req.access_type <= WRITE_REQ;
                          load_store_req.access_length <= 0;
                          load_store_req.stride_type <= NON_STRIDE;
                          load_store_req.vec_reg_ptr <= v_register_t'(reg1);
                          load_store_req.addr <= read_data;
                          load_store_req.data <= 0;
                       end
             SVI     : begin
                       end
             SVWS    : begin
                       end
             SEQVVD  : begin
                       end
             SNEVVD  : begin
                       end
             SGTVVD  : begin
                       end
             SLTVVD  : begin
                       end
             SGEVVD  : begin
                       end
             SLEVVD  : begin
                       end
             SEQVSD  : begin
                       end
             SNEVSD  : begin
                       end
             SGTVSD  : begin
                       end
             SLTVSD  : begin
                       end
             SGEVSD  : begin
                       end
             SLEVSD  : begin
                       end
             POP     : begin
                       end
             CVM     : begin
                       end
             MTC1    : begin
                          EXE_VECTOR_REG.LENGTH <= read_data;
                       end
             MFC1    : begin
                       end
             MVTM    : begin
                       end
             MVFM    : begin
                       end
             PIPE_ACTIVATE : begin
                             end
             PIPE_HALT     : begin
                             end
             MOV_IMM : begin
                          wr_access_ptr_ff <= reg1[$clog2(SCALAR_REG_DEPTH)-1:0];
                       end
             MOV_IMM_DATA  : begin
                             end
             default : begin
                       end
          endcase
       end
    end
    
endmodule