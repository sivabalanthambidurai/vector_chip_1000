class my_sqr extends uvm_sequencer#(seq_item,seq_item);
  `uvm_component_utils(my_sqr)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass