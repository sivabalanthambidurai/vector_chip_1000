module mainmemory ( input clk,
                     input reset,
                     input req_write,
                     input req_read,
                     input [3:0] req_id,
                     input [31:0] req_addr,
                     input [7:0] req_byte_en,
                     input [63:0] req_write_data,

                     output rsp_write,
                     output rsp_read,
                     output [3:0] rsp_id,
                     output [63:0] rsp_read_data,
                     output mem_ready,
                     output req_latched
                    
                    
                    ) ;

  parameter LINE_WIDTH = 64, MEMORY_SIZE = 16777216;
  
  reg [LINE_WIDTH - 1:0] main_memory_space[MEMORY_SIZE - 1:0];
  
  logic req_write_ff, req_read_ff, rsp_write_ff, rsp_read_ff, mem_ready_ff;
  logic [3:0] req_id_ff, rsp_id_ff;
  logic [7:0] req_byte_en_ff;
  logic [31:0] req_addr_ff;
  logic [63:0] req_write_data_ff, rsp_read_data_ff;
       
  always_ff@(posedge clk)
    begin
      if(reset)
        begin
          req_write_ff <= 0;
          req_read_ff <= 0;
          req_id_ff <= 0;
          req_byte_en_ff <= 0;
          req_addr_ff <= 0;
          req_write_data_ff <= 0;
        end
      else if(req_write && !req_read && mem_ready_ff)
        begin
          req_write_ff <= req_write;
          req_id_ff <= req_id;
          req_byte_en_ff <= req_byte_en;
          req_addr_ff <= req_addr;
          req_write_data_ff <= req_write_data;
        end
      else if(req_read && !req_write && mem_ready_ff)
        begin
          req_read_ff <= req_read;
          req_id_ff <= req_id;
          req_addr_ff <= req_addr;
        end
      else if(rsp_write_ff || rsp_read_ff)
        begin
          req_write_ff <= 0;
          req_read_ff <= 0;
          req_id_ff <= 0;
          req_byte_en_ff <= 0;
          req_addr_ff <= 0;
          req_write_data_ff <= 0;
        end
    end

    always_ff@(posedge clk)
    begin
      if(reset)
        begin
          rsp_write_ff <= 0;
          rsp_read_ff <= 0;
        end
      else if(req_write_ff)
        begin
          for(int i = 0; i < 8; i++)
            begin
              if(req_byte_en_ff[i])
                main_memory_space[req_addr_ff][8*i +: 8] <= req_write_data_ff[8*i +: 8];
            end
          rsp_write_ff <= 1;
          rsp_id_ff <= req_id_ff;
        end
      else if(req_read_ff)
        begin
          rsp_read_data_ff <= main_memory_space[req_addr_ff];
          rsp_read_ff <= 1;
          rsp_id_ff <= req_id_ff;
        end
      else //handshake
        begin
          rsp_read_ff <= 0;
          rsp_write_ff <= 0;
          rsp_id_ff <= 0;
        end
    end
    
  assign mem_ready_ff = (rsp_write_ff || rsp_read_ff) ? 1 : (req_write_ff || req_read_ff) ? 0 : 1;
  
  assign req_latched = !mem_ready_ff;
  assign mem_ready = mem_ready_ff;
  assign rsp_write = rsp_write_ff;
  assign rsp_read = rsp_read_ff;
  assign rsp_id = rsp_id_ff;
  assign rsp_read_data = rsp_read_data_ff;

endmodule