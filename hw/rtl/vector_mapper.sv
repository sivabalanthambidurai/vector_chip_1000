//____________________________________________________________________________________________________________________
//file name : vector_mapper.sv
//author : sivabalan
//description : This file holds the logic for vector
//Takes eight data port and eight addr port, then map the data port based on the addr port
//to the respective output data port.
//____________________________________________________________________________________________________________________

module vector_mapper # (parameter MAP_PORT = 8)
                     (input clk,
                      input reset,
                      input vld [MAP_PORT-1:0],
                      input [$clog2(VECTOR_REG_DEPTH)-1:0] addr_port [MAP_PORT-1:0],
                      input [VECTOR_REG_WIDTH-1:0] data_port_in [MAP_PORT-1:0],
                      output reg [VECTOR_REG_WIDTH-1:0] data_port_out [MAP_PORT-1:0]                      
                     );

    logic latched [MAP_PORT-1:0];

    //mapping logic.
    //Note : It is recommended not have two addr port maps to 
    //same data port. If two register addr port maps to same 
    //data port, only the first port will be to mapped the 
    //data port.
    always_comb begin
       for(bit [$clog2(MAP_PORT):0] i=0; i<MAP_PORT; i++) begin
          for(bit [$clog2(VECTOR_REG_DEPTH) :0] j=0; j<VECTOR_REG_DEPTH; j++) begin
             if(vld[i] && (j==addr_port[i]) && !latched[j]) begin
                latched[j] = 1;
                data_port_out[i] = data_port_in[addr_port[i]];
             end  
          end
       end
    end
 
endmodule