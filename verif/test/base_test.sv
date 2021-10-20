`include "sequence.sv"
`include "environment.sv"

class base_test extends uvm_test;
  my_env env;
  my_seq seq;
  
  virtual mem_if vif;

  
  `uvm_component_utils(base_test)
  function new(string name, uvm_component parent);
    super.new(name, parent);
    set_type_override_by_type(my_seq::get_type(), my_seq_ext::get_type());
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    user_phase(phase);
    env = my_env::type_id::create("env",this);
    seq = my_seq::type_id::create("seq");
    //set_type_override_by_type(my_seq::get_type(), my_seq_ext::get_type());
  endfunction
  
  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction
  
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(env.agnt.sqr);
    #100ns;
    phase.drop_objection(this);  
  endtask
  
  virtual task user_phase(uvm_phase phase);
    `uvm_info("phase",$sformatf("In %0s",phase.get_name()),UVM_LOW)
  endtask
  
endclass
    
  