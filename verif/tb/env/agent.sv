`include "driver.sv"
`include "sequencer.sv"
`include "monitor.sv"

class my_agnt extends uvm_agent;
  my_drv drv;
  my_sqr sqr;
  my_mon mon;
  
  virtual mem_if vif;
  
  `uvm_component_utils(my_agnt)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv = my_drv::type_id::create("drv",this);
    sqr = my_sqr::type_id::create("sqr",this);
    mon = my_mon::type_id::create("mon",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
  
  
endclass