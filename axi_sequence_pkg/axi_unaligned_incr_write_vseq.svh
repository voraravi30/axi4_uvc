
//---------------------------------------------------------------------------
//Class: axi_unaligned_incr_write_vseq
//sequence that generate traffic for unaligned write transfer
//---------------------------------------------------------------------------
class axi_unaligned_incr_write_vseq extends axi_virtual_sequence_base;

    //UVM factory registration macro
    `uvm_object_utils(axi_unaligned_incr_write_vseq)

    //---------------------------------------------------------------------
    //Data Members:
    //---------------------------------------------------------------------
    int no_of_iteration = 2;

    //---------------------------------------------------------------------
    //Methods: 
    //---------------------------------------------------------------------
    //Class Constructor Method:
    extern function new(string name = "unaligned_incr_write_vseq");

    //body method
    extern task body();

endclass:axi_unaligned_incr_write_vseq



//------------------------------------------------------------------------------------
//Implementation
//------------------------------------------------------------------------------------
//
//
//
//------------------------------------------------------------------------------------
//Class Constructor Method: new
//------------------------------------------------------------------------------------
function axi_unaligned_incr_write_vseq::new(string name = "unaligned_incr_write_vseq");

    super.new(name);

endfunction:new

//------------------------------------------------------------------------------------
//Method: body
//create and execute axi_master_incr_write_seq and axi_slave_main_seq on corresponding
//sequencer
//------------------------------------------------------------------------------------
task axi_unaligned_incr_write_vseq::body();

    //axi master sequence that generate legal incr burst traffic
    axi_master_incr_write_seq incr_write_seq[] = new[no_of_iteration];
    //axi_slave_main_seq
    axi_slave_main_seq slave_main_seq;
    string name;

    //create slave sequence
    slave_main_seq = axi_slave_main_seq::type_id::create("slave_main_seq");

    if(no_of_iteration == 0) begin
        `uvm_fatal("NO_VALID_ITERATION", {"no_of_iteration must be non-zero for", get_full_name(), ".no_of_iteration"});
    end

    fork
        slave_main_seq.start(slave_seqr[0]);
    join_none

    //create, randomize and execute master sequences
    foreach(incr_write_seq[index]) begin
        $sformat(name, "incr_write_seq[%0d]", index);
        incr_write_seq[index] = axi_master_incr_write_seq::type_id::create(name);
        if(!incr_write_seq[index].randomize() with {start_addr%(2**burst_size) != 0;}) begin
            `uvm_fatal("RANDOMIZATION_FAIL", {"randmozation fails in body method of: ", get_full_name(), ", for ", incr_write_seq[index].get_name()})
        end
        incr_write_seq[index].start(master_seqr[0]);
    end

endtask
