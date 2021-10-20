`include "sequence_item.sv"

class my_seq extends uvm_sequence#(seq_item);
  seq_item seqW, seqR;
  
  `uvm_object_utils_begin(my_seq)
  `uvm_field_object(seqW,UVM_ALL_ON)
  `uvm_field_object(seqR,UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name="my_seq");
    super.new(name);
    seqW = seq_item::type_id::create("seqW");
    seqR = seq_item::type_id::create("seqR");
  endfunction
  task body();
    
    bit [31:0] address;
    bit [63:0] data;
    
    repeat(1) begin
      //write(posted)
      seqW.operation  = 1'b1;
      std::randomize(address) with {address[31:22] == 8'h00;};
      std::randomize(data);
      seqW.addr = address;
      seqW.data = data;
      start_item(seqW);
      finish_item(seqW);
      #4ns;
      //read(non-posted)
      seqR.operation  = 1'b0;
      seqR.addr = address;
      start_item(seqR);
      finish_item(seqR);

      if(seqR.data != seqW.data)
        `uvm_error("seq","read != write")
      else
        `uvm_info("seq",$sformatf("read : %0h & write : %0h ",seqR.data,seqW.data),UVM_LOW)
      $display("write seq trans id %0d",seqR.get_transaction_id());
      $display("read seq trans id %0d",seqW.get_transaction_id());
      
    end
  endtask
  
endclass

class my_seq_ext extends my_seq;
  seq_item seqW, seqR;
  
  `uvm_object_utils_begin(my_seq_ext)
  `uvm_field_object(seqW,UVM_ALL_ON)
  `uvm_field_object(seqR,UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name="my_seq_ext");
    super.new(name);
    seqW = seq_item::type_id::create("seqW");
    seqR = seq_item::type_id::create("seqR");
  endfunction
  task body();
    
    bit [31:0] address;
    bit [63:0] data;
    
    repeat(1) begin
      //write(posted)
      seqW.operation  = 1'b1;
      std::randomize(address) with {address[31:22] == 8'h00;};
      std::randomize(data);
      seqW.addr = address;
      seqW.data = data;
      start_item(seqW);
      finish_item(seqW);
      #4ns;
      //read(non-posted)
      seqR.operation  = 1'b0;
      seqR.addr = address;
      start_item(seqR);
      finish_item(seqR);

      if(seqR.data != seqW.data)
        `uvm_error("seq","read != write")
      else
        `uvm_info("seq",$sformatf("read : %0h & write : %0h ",seqR.data,seqW.data),UVM_LOW)
      $display("extended write seq trans id %0d",seqR.get_transaction_id());
      $display("extended read seq trans id %0d",seqW.get_transaction_id());
      
    end
  endtask
  
endclass