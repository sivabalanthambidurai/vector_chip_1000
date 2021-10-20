class my_mon extends uvm_monitor;
  
  virtual mem_if vif;
  
  uvm_analysis_port #(seq_item) mon_port;
  
  `uvm_component_utils(my_mon)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_port = new("mon_port",this);
    uvm_config_db#(virtual mem_if)::get(this,"","vif",vif);
  endfunction 
  
  task run_phase(uvm_phase phase);
    seq_item seq_mon;
    seq_mon = seq_item::type_id::create("seq_mon");
    forever begin
      @(posedge vif.clk);
      if(vif.req_write)
        begin
          seq_mon.operation = 1'b1;
          seq_mon.addr = vif.req_addr;
          seq_mon.data = vif.req_write_data;
          @(posedge vif.clk);
          mon_port.write(seq_mon);
        end
      else if(vif.rsp_read)
        begin
          seq_mon.operation = 1'b0;
          seq_mon.addr = vif.req_addr;
          seq_mon.data = vif.rsp_read_data;
          @(posedge vif.clk);
          mon_port.write(seq_mon);
        end
    end
  endtask
    
endclass