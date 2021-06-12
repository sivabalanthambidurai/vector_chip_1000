//____________________________________________________________________________________________________________________
//file name : scalar_register.sv
//author : sivabalan
//description : This file holds the scalar register logic.
//Scalar register holds 32 general purpose registers and 32 floating point regsiters each 64 bit wide.
//____________________________________________________________________________________________________________________

module scalar_register (input clk,
                        input reset,

                        //scalar register access
                        input write,
                        input [$clog2(SCALAR_REG_DEPTH)-1:0] rd_access_ptr,
                        input [$clog2(SCALAR_REG_DEPTH)-1:0] wr_access_ptr,
                        input [SCALAR_REG_WIDTH-1:0] write_data,
                        output reg [SCALAR_REG_WIDTH-1:0] read_data,

                        //floaing point register access
                        input fwrite,
                        input [$clog2(SCALAR_REG_DEPTH)-1:0] rd_faccess_ptr,
                        input [$clog2(SCALAR_REG_DEPTH)-1:0] wr_faccess_ptr,
                        input [SCALAR_REG_WIDTH-1:0] fwrite_data,
                        output reg [SCALAR_REG_WIDTH-1:0] fread_data

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
    else if(write) begin
       scalar_register_array[wr_access_ptr] <= write_data;
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
    else if(fwrite) begin
       scalar_register_array_fp[wr_faccess_ptr] <= fwrite_data;
    end
  end
 
 assign read_data = scalar_register_array[rd_access_ptr];
 assign fread_data = scalar_register_array_fp[rd_faccess_ptr];

endmodule
