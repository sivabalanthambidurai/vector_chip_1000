//____________________________________________________________________________________________________________________
//file name : linear_feedback_shift_regsiter.sv
//author : sivabalan
//description : This file holds the logic for linear feedback shift resgister
//____________________________________________________________________________________________________________________

module linear_feedback_shift_regsiter #( parameter REGISTER_LENGTH = 8)
                                      ( input clk,
                                        input reset,
                                        input enable,
                                        output reg_out
                                      );

   logic [REGISTER_LENGTH-1:0] lfsr_register;

   always_ff @(posedge clk or negedge reset) begin
      if(reset) begin
         lfsr_register <= 1;
      end
      else if(enable) begin
         lfsr_register <= lfsr_register >> 1;
         lfsr_register[REGISTER_LENGTH-1] <= lfsr_register[1] ^ lfsr_register[0];
      end
   end

   assign reg_out = lfsr_register[REGISTER_LENGTH-1];

endmodule