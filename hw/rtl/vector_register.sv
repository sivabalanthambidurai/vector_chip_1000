//____________________________________________________________________________________________________________________
//file name : vector_register.sv
//author : sivabalan
//description : This file holds the vector register logic. Vector register holds 64 element with each 64 bit wide
//____________________________________________________________________________________________________________________

module vector_register (input clk,
                        input reset

                       );
  
  logic [VECTOR_REG_WIDTH-1:0] vector_register_array [VECTOR_REG_DEPTH];
  
  always_ff@(posedge clk or posedge reset)
  begin
    if(reset)
    begin
      foreach(vector_register_array[i])
      begin
        vector_register_array[i] <= {VECTOR_REG_WIDTH{1'h0}};
      end
    end
  end
  
endmodule
