class seq_item extends uvm_sequence_item;

  rand bit operation; //1'b1 = write & 1'b0 = read.
  rand bit [31:0] addr;
  rand bit [63:0] data;
  
  
  `uvm_object_utils_begin(seq_item)
  `uvm_field_int(operation,UVM_ALL_ON)
  `uvm_field_int(addr,UVM_ALL_ON)
  `uvm_field_int(data,UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name="seq_item");
    super.new(name);
  endfunction
endclass
