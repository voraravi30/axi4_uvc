//------------------------------------------------------------------------
//Class: axi_slave_main_seq
//main sequence that executes on slave sequencer and executes sub-sequences
//write and read on slave sequencer
//------------------------------------------------------------------------
class axi_slave_main_seq extends axi_slave_base_seq;

    //UVM factory registration
    `uvm_object_utils(axi_slave_main_seq)

    //--------------------------------------------------------------------
    //Method:
    //--------------------------------------------------------------------
    extern function new(string name = "slave_main_seq");
    extern task body();
 
endclass:axi_slave_main_seq


//--------------------------------------------------------------------
//Implementation:
//--------------------------------------------------------------------


//--------------------------------------------------------------------
//Class Constructor Method: new
//--------------------------------------------------------------------
function axi_slave_main_seq::new(string name = "slave_main_seq");
    
    super.new(name);

endfunction:new


//--------------------------------------------------------------------
//Method: body
//executes write and read sequences on slave sequencer
//--------------------------------------------------------------------
task axi_slave_main_seq::body();

    //write sequence
    axi_slave_write_seq slave_write_seq;
    //read sequence
    axi_slave_read_seq slave_read_seq;

    //create sub-sequences
    slave_write_seq = axi_slave_write_seq::type_id::create("slave_write_seq");
    slave_read_seq = axi_slave_read_seq::type_id::create("slave_read_seq");

    //execute sub-sequenes on this main sequence started
    fork
        slave_write_seq.start(m_sequencer, this);
        slave_read_seq.start(m_sequencer, this);
    join

endtask:body
