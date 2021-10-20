class my_drv extends uvm_driver#(seq_item);
  
  virtual mem_if vif;
  
  `uvm_component_utils(my_drv)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db#(virtual mem_if)::get( this, "", "vif", vif);
  endfunction 
  
  task run_phase(uvm_phase phase);
    seq_item seq_req;
    @(negedge vif.reset);
    forever begin
      seq_item_port.get_next_item(seq_req);
      @(posedge vif.clk);
      if(seq_req.operation == 1'b1)
        begin
          vif.req_write <= 1'b1;
          vif.req_read <= 1'b0;
          vif.req_addr <= seq_req.addr;
          vif.req_byte_en <= 8'hff;
          vif.req_write_data <= seq_req.data;
          @(posedge vif.clk);
          vif.req_write <= 1'b0;
          vif.req_byte_en <= 8'h00;
        end
      else
        begin
          vif.req_read <= 1'b1;
          vif.req_write <= 1'b0;
          vif.req_addr <= seq_req.addr;
          @(posedge vif.clk);
          vif.req_read <= 1'b0;
        end
      
      if(seq_req.operation == 1'b0) begin
         @(posedge vif.rsp_read);
         seq_req.data <= vif.rsp_read_data;
         @(negedge vif.rsp_read);
      end
      else if(seq_req.operation == 1'b1) begin
        @(negedge vif.rsp_write);
      end     
      seq_item_port.item_done();
    end
    
  endtask
endclass