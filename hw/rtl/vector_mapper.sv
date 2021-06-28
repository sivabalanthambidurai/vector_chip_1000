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

    //mapping logic.
    //Note : It is recommended not have two addr port maps to 
    //same data port. If two register addr port maps to same 
    //data port, only the port with highest priority will be to 
    //mapped the data port.(Prioirty port0(highest) to port7(lowest))

    always_comb begin
       for(int i=MAP_PORT-1; i>=0; i--) begin
          for(int j=0; j<VECTOR_REG_DEPTH; j++) begin
             if(vld[i] && (j==addr_port[i])) begin
                data_port_out[i] = data_port_in[addr_port[i]];
             end  
          end
       end
    end

 
endmodule