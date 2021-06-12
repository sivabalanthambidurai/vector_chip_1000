//____________________________________________________________________________________________________________________
//file name : lane.sv
//author : sivabalan
//description : This file holds the logic for lane inside the pipeline.
//____________________________________________________________________________________________________________________

module lane (input clk,
             input reset,

             //execution unit interface
             input vld,
             input [VECTOR_REG_WIDTH-1:0] data0,
             input [VECTOR_REG_WIDTH-1:0] data1,
             input [$clog2(NUM_OF_VECTOR_REG)-1:0] vec_reg_in,
             input function_opcode_t functional_opcode,
             output reg busy,

             //wb interface
             output reg result_vld,
             output reg [$clog2(NUM_OF_VECTOR_REG)-1:0] vec_reg_out,
             output reg data_out,
             input wb_full_lane

            );

    logic functional_unit_busy;

    always_ff @(posedge clk or negedge reset) begin
       if(!reset) begin
          result_vld <= 0;
          vec_reg_out <= 0;
          data_out <= 0;
          functional_unit_busy <= 0;
       end
       else begin
          case (functional_opcode)
             SADD : begin
                       result_vld  <= 1;
                       vec_reg_out <= vec_reg_in;
                       data_out    <= data0 + data1;
                       functional_unit_busy <= 0;
                    end
             SSUB : begin
                       result_vld  <= 1;
                       vec_reg_out <= vec_reg_in;
                       data_out    <= data0 - data1;
                       functional_unit_busy <= 0;               
                    end
             SMUL : begin
                       result_vld  <= 1;
                       vec_reg_out <= vec_reg_in;
                       data_out    <= data0 * data1;
                       functional_unit_busy <= 0;              
                    end
             SDIV : begin
                       result_vld  <= 1;
                       vec_reg_out <= vec_reg_in;
                       data_out    <= data0 / data1;
                       functional_unit_busy <= 0;                
                    end
             FADD : begin
                    end
             FSUB : begin
                    end
             FMUL : begin
                    end
             FDIV : begin
                    end
             default : begin
                          result_vld <= 0;
                          vec_reg_out <= 0;
                          data_out <= 0;
                          functional_unit_busy <= 0;
                       end 
          endcase
       end
    end

   assign busy = functional_unit_busy || wb_full_lane;
 
endmodule