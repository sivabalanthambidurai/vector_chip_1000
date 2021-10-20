`include "base_test.sv"


interface mem_if();
logic clk;
logic reset;
logic req_write;
logic req_read;
logic [3:0] req_id;
logic [31:0] req_addr;
logic [7:0] req_byte_en;
logic [63:0] req_write_data;

logic  rsp_write;
logic rsp_read;
logic [3:0] rsp_id;
logic [63:0] rsp_read_data;
logic  mem_ready;

endinterface 

module tb_top;
  
  mem_if vif();
    
  mainmemory dut(.clk(vif.clk),
                 .reset(vif.reset),
                 .req_write(vif.req_write),
                 .req_read(vif.req_read),
                 .req_id(vif.req_id),
                 .req_addr(vif.req_addr),
                 .req_byte_en(vif.req_byte_en),
                 .req_write_data(vif.req_write_data),
                 .rsp_write(vif.rsp_write),
                 .rsp_read(vif.rsp_read),
                 .rsp_id(vif.rsp_id),
                 .rsp_read_data(vif.rsp_read_data),
                 .mem_ready(vif.mem_ready)
                    );
  
//clock generation;
  initial begin
      vif.clk=0;
  end
  
  always begin
    #1 vif.clk = ~vif.clk;
  end
  
//reset generation
  initial begin
    vif.reset=1;
    #2ns;
    vif.reset=0;
  end
  
//covergroup
    covergroup cg @ (posedge vif.clk);
      cp : coverpoint vif.rsp_read_data {bins data = {16'h7857};}
    endgroup
  
  
//test
  initial begin
    uvm_config_db#(virtual mem_if)::set( uvm_root::get(), "*.drv", "vif", vif);
    uvm_config_db#(virtual mem_if)::set( uvm_root::get(), "*.mon", "vif", vif);
    //making it available only to drv & mon.
    run_test("base_test");
  end
  
  
//dumps
 initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule