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

                        //ifetch unit interface 
                        input reg opcode_vld,
                        input opcode_t opcode0,
                        input opcode_t opcode1,
                        output reg inst_buff_full

                       );

    logic buffer0_full, buffer1_full, buffer0_empty, buffer1_empty,
          buffer0_rsp, buffer1_rsp;
    //exe_unit_active : Indicates that execution unit is Active.
    logic exe_unit_active;

    opcode_t buffer0_opcode, buffer1_opcode;
    vopcode_t opcode;

    //Register : EXE_VECTOR_REG
    //LENGTH : This field indicates the length of the vector operation.
    //MASK : This field uses mask to execute conditional codes.
    exe_vector_reg_t EXE_VECTOR_REG;
    logic [31:0] vector_length;

    //TODO: Need to identify the dependecy between the opcode0 and opcode1.
    //If the dependency exists, then the two opcodes should be sent to same
    //buffer.

    //buffer0 stores the opcode from channel opcode0
    buffer buffer0 (.clk(clk),
                    .reset(reset),
                    //buffer input
                    .req(opcode_vld),
                    .req_data(opcode0),
                    .full(buffer0_full),
                    //buffer output
                    .rsp(buffer0_rsp && !exe_unit_active),
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
                    .rsp(buffer1_rsp && !exe_unit_active),
                    .empty(buffer1_empty),
                    .rsp_data(buffer1_opcode)
                   );

    assign inst_buff_full = buffer0_full || buffer1_full;

    arbiter_rr # (.VECTOR_IN(2))
               exe_arb (.clk(clk),
                        .reset(reset),
                        .request_vector({!buffer1_empty, !buffer0_empty}),
                        .grant({buffer1_rsp, buffer0_rsp})
                       );
   
    //opcode fetching logic.
    always_comb begin
       if(buffer0_rsp) begin
          opcode = vopcode_t'(buffer0_opcode[31:24]);
       end
       else if(buffer1_rsp) begin
          opcode = vopcode_t'(buffer1_opcode[31:24]);
       end
       else begin
          opcode = NO_OP;
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
                          if(EXE_VECTOR_REG.LENGTH <= vector_length)  begin
                             exe_unit_active <= 1;
                          end
                          else begin
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
             LV      : begin
                       end
             LVI     : begin
                       end
             LVWS    : begin
                       end
             SV      : begin
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
             default : begin
                       end
          endcase
       end
    end
    
endmodule