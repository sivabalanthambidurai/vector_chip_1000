class my_scrbd extends uvm_scoreboard;
  
  uvm_analysis_imp#(seq_item, my_scrbd) scrbd_import;
  
  seq_item seq_queue[$];
  bit [63:0] ref_model [16777215:0];
  
  `uvm_component_utils(my_scrbd)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scrbd_import = new("scrbd_import", this);
  endfunction
  
  function void write(seq_item seq);
    seq_queue.push_back(seq);
  endfunction  
  
  task run_phase(uvm_phase phase);
    seq_item seq_local;
    forever begin
      wait(seq_queue.size()>0);
      seq_local = seq_queue.pop_front();
      if(seq_local.operation == 1'b1)
        begin
          ref_model[seq_local.addr] = seq_local.data;
        end
      else
        begin
          if(seq_local.data != ref_model[seq_local.addr])
            begin
            `uvm_error("scrbd",$sformatf("rtl mismatches ref model"))
            end
          else
            `uvm_info("scrbd",$sformatf("rtl equals ref model"), UVM_LOW)
        end
    end
    
  endtask
  
  
endclass