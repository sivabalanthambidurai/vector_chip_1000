//____________________________________________________________________________________________________________________
//file name : memory.sv
//author : sivabalan
//description : This file holds the memory.
//____________________________________________________________________________________________________________________

module memory (input clk,
               input write,
               input [(DATA_FIELD_WIDTH/BYTE)-1:0] we,
               input [ADDR_FIELD_WIDTH-1:0] addr,
               input [DATA_FIELD_WIDTH-1:0] data,                            
               output [DATA_FIELD_WIDTH-1:0] q
               );
  
  logic [DATA_FIELD_WIDTH-1:0] memory [1<<ADDR_FIELD_WIDTH-1];
  logic [ADDR_FIELD_WIDTH-1:0] addr_ff;
  
  always_ff@(posedge clk)
  begin
     if(write)
     begin
        foreach(we[i])
        begin
           if(we[i])
           begin
              memory[addr][8*i +: 8] <= data[8*i +: 8];
           end
        end
     end
     else
     begin
        addr_ff <= addr;
     end
  end

assign q = memory[addr_ff];
 
endmodule
