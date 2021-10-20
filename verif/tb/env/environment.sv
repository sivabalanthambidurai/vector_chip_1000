`include "agent.sv"
`include "scoreboard.sv"

class my_env extends uvm_env;
  my_agnt agnt;
  my_scrbd scrbd;
  
  virtual mem_if vif;
  
  `uvm_component_utils(my_env)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agnt = my_agnt::type_id::create("agnt",this);
    scrbd = my_scrbd::type_id::create("scrbd",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agnt.mon.mon_port.connect(scrbd.scrbd_import);
  endfunction
  
endclass