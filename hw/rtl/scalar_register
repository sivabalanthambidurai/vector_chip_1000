//____________________________________________________________________________________________________________________
//file name : scalar_register.sv
//author : sivabalan
//description : This file holds the scalar register logic.
//Scalar register holds 32 general purpose registers and 32 floating point regsiters each 64 bit wide.
//____________________________________________________________________________________________________________________

module scalar_register (input clk,
                        input reset

                       );
  
  logic [SCALAR_REG_WIDTH-1:0] scalar_register_array [SCALAR_REG_DEPTH];
  logic [SCALAR_REG_WIDTH-1:0] scalar_register_array_fp [SCALAR_REG_DEPTH];
  
  always_ff@(posedge clk or posedge reset)
  begin
    if(reset)
    begin
      foreach(scalar_register_array[i])
      begin
        scalar_register_array[i] <= {SCALAR_REG_WIDTH{1'h0}};
      end
    end
  end

  always_ff@(posedge clk or posedge reset)
  begin
    if(reset)
    begin
      foreach(scalar_register_array_fp[i])
      begin
        scalar_register_array_fp[i] <= {SCALAR_REG_WIDTH{1'h0}};
      end
    end
  end
 
endmodule
