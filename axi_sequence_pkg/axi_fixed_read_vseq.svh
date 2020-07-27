//---------------------------------------------------------------------------
//Class: axi_fixed_read_vseq
//sequence that randomaly generate traffic for read transfer
//---------------------------------------------------------------------------
class axi_fixed_read_vseq extends axi_virtual_sequence_base;

    //UVM factory registration macro
    `uvm_object_utils(axi_fixed_read_vseq)

    //---------------------------------------------------------------------
    //Data Members:
    //---------------------------------------------------------------------
    int no_of_iteration = 2;

    //---------------------------------------------------------------------
    //Methods: 
    //---------------------------------------------------------------------
    //Class Constructor Method:
    extern function new(string name = "fixed_read_vseq");

    //body method
    extern task body();

endclass:axi_fixed_read_vseq



//------------------------------------------------------------------------------------
//Implementation
//------------------------------------------------------------------------------------
//
//
//
//------------------------------------------------------------------------------------
//Class Constructor Method: new
//------------------------------------------------------------------------------------
function axi_fixed_read_vseq::new(string name = "fixed_read_vseq");

    super.new(name);

endfunction:new

//------------------------------------------------------------------------------------
//Method: body
//create and execute axi_master_fixed_read_seq and axi_slave_main_seq on corresponding
//sequencer
//------------------------------------------------------------------------------------
task axi_fixed_read_vseq::body();

    //axi master sequence that generate legal fixed burst traffic
    axi_master_fixed_read_seq fixed_read_seq[] = new[no_of_iteration];
    //axi_slave_main_seq
    axi_slave_main_seq slave_main_seq;
    string name;

    //create slave sequence
    slave_main_seq = axi_slave_main_seq::type_id::create("slave_main_seq");

    if(no_of_iteration == 0) begin
        `uvm_fatal("NO_VALID_ITERATION", {"no_of_iteration must be non-zero for", get_full_name(), ".no_of_iteration"});
    end
    //create master sequences
    foreach(fixed_read_seq[index]) begin
        fixed_read_seq[index] = axi_master_fixed_read_seq::type_id::create(name);
    end

    //randomize the fixed_read_seq
    foreach(fixed_read_seq[index]) begin
        if(!fixed_read_seq[index].randomize()) begin
            `uvm_fatal("RANDOMIZATION_FAIL", {"randmozation fails in body method of: ", get_full_name(), ", for ", fixed_read_seq[index].get_name()})
        end
    end

    //start the sequences
    fork
        slave_main_seq.start(slave_seqr[0]);
    join_none

    foreach(fixed_read_seq[index]) begin
        fixed_read_seq[index].start(master_seqr[0]);
    end

endtask
