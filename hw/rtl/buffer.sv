//____________________________________________________________________________________________________________________
//file name : buffer.sv
//author : sivabalan
//description : This file holds the logic for buffer.
//____________________________________________________________________________________________________________________

module buffer # ( parameter WIDTH = 32, DEPTH = 64)
              (input clk,
               input reset,
               //buffer input
               input req,
               input [WIDTH-1:0] req_data,
               output reg full,
               //buffer output
               input rsp,
               output reg empty,
               output [WIDTH-1:0] rsp_data
              );

    logic [WIDTH-1:0] buffer [DEPTH-1:0];
    logic [$clog2(DEPTH):0] rd_ptr, wr_ptr;

    always_ff @(posedge clk or negedge reset) begin
       if(!reset) begin
          rd_ptr <= 0; wr_ptr <= 0;
       end
       else begin
          if(req && !full) begin
             buffer[wr_ptr] <= req_data; 
             wr_ptr <= wr_ptr + 1;
           end
          if (rsp && !empty)
             rd_ptr <= rd_ptr + 1;
       end
    end

    //empty and full indicator
    assign full = ((rd_ptr[6] == !wr_ptr[6]) && (rd_ptr[5:0] == wr_ptr[5:0])) ? 1 : 0;
    assign empty = (rd_ptr == wr_ptr) ? 1 : 0;
    //data
    assign rsp_data = buffer[rd_ptr];

endmodule