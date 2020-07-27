class axi_master_sequencer extends uvm_sequencer #(master_seq_item);
  `uvm_component_utils(axi_master_sequencer)

  extern function new(string name = "", uvm_component parent = null);
endclass:axi_master_sequencer

function axi_master_sequencer::new(string name = "",uvm_component parent = null);
  super.new(name,parent);
endfunction:new
