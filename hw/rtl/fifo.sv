//____________________________________________________________________________________________________________________
//file name : fifo.sv
//author : sivabalan
//____________________________________________________________________________________________________________________

module fifo #(parameter FIFO_DEPTH = 8)
             (input clk, rst, write, read, wr_data, output rd_data, empty, full);

logic FIFO_ARRAY [FIFO_DEPTH];
logic wr_ptr[$log2(FIFO_DEPTH)-1:0], rd_ptr[$log2(FIFO_DEPTH)-1:0];


logic direction;
//direction = 0 indicates the FIFO is approaching towards empty
//direction = 1 indicates the FIFO is approaching towards full

assign full = direction ?  &(wr_ptr ~^ rd_ptr) : 0;
assign empty = direction ? 0 : &(wr_ptr ~^ rd_ptr);

   always_ff @(posedge clk or negedge rst) begin
      if(!rst) begin
         direction <= 0;
      end
      else if(write && !read) begin
         direction <= 1;
      end
      else if(!write && read) begin
         direction <= 0;
      end 
   end

   always_ff @(posedge clk or negedge rst) begin
      if(rst) begin
         wr_ptr <= 0;
         rd_ptr <= 0;
      end
      else begin
         if(write && !full) begin
            wr_ptr <= wr_ptr + 1;
            FIFO_ARRAY[wr_ptr] <= wr_data;
         end
         if(read && !empty) begin
            rd_ptr <= rd_ptr + 1;
         end
      end
   end

   assign rd_data = FIFO_ARRAY[rd_ptr];

endmodule