//----------------------------------------------------------------------------------------
//Class: axi_virtual_sequence_base
//axi_virtual_sequence_base class contains the handles of target sequncers
//which is initialize using init_vseq method of axi_test_base class prior to
//executing the virtual sequence. This axi_virtual_sequence_base can be
//extended to have execution of certain sequences on particular sequencer.
//----------------------------------------------------------------------------------------
class axi_virtual_sequence_base extends uvm_sequence #(uvm_sequence_item);

    //UVM factory registration macro
    `uvm_object_utils(axi_virtual_sequence_base)

    //------------------------------------------------------------------------------------
    //Data Members:
    //------------------------------------------------------------------------------------
    //agents' sequencer handle on which sequences going to be start
    uvm_sequencer_base  master_seqr[];
    uvm_sequencer_base  slave_seqr[];

    //Class Constructor Method:
    extern function new(string name = "axi_v_seqc");

endclass:axi_virtual_sequence_base

//------------------------------------------------------------------------------------
//Class Constuctor Method: new
//------------------------------------------------------------------------------------
function axi_virtual_sequence_base::new(string name = "axi_v_seqc");

    super.new(name);

endfunction:new
