//---------------------------------------------------------------------------
//Class: axi_fixed_simultaneous_write_read_vseq
//execute the axi_master_outstand_write_seq, axi_master_outstand_read_seq and
//axi_slave_main_seq
//---------------------------------------------------------------------------
class axi_fixed_simultaneous_write_read_vseq extends axi_virtual_sequence_base;

    //UVM factory registration macro
    `uvm_object_utils(axi_fixed_simultaneous_write_read_vseq)

    //---------------------------------------------------------------------
    //Data Members:
    //---------------------------------------------------------------------
    int no_of_iteration = 2;

    //---------------------------------------------------------------------
    //Methods: 
    //---------------------------------------------------------------------
    //Class Constructor Method:
    extern function new(string name = "simultaneous_write_read");

    //body method
    extern task body();

endclass:axi_fixed_simultaneous_write_read_vseq



//------------------------------------------------------------------------------------
//Implementation
//------------------------------------------------------------------------------------
//
//
//
//------------------------------------------------------------------------------------
//Class Constructor Method: new
//------------------------------------------------------------------------------------
function axi_fixed_simultaneous_write_read_vseq::new(string name = "simultaneous_write_read");

    super.new(name);

endfunction:new

//------------------------------------------------------------------------------------
//Method: body
//execute axi_master_outstand_write_seq, axi_master_outstand_read_seq and
//axi_slave_main_seq sequences
//------------------------------------------------------------------------------------
task axi_fixed_simultaneous_write_read_vseq::body();

    //axi master sequence that generate legal fixed burst traffic
    axi_master_outstand_write_seq rand_outstand_write_seq[] = new[no_of_iteration];
    axi_master_outstand_read_seq rand_outstand_read_seq[] = new[no_of_iteration];
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

    //create, randomize and execute master write and read sequences
    fork
        foreach(rand_outstand_write_seq[index]) begin
            $sformat(name, "rand_outstnd_write_seq[%0d]", index);
            rand_outstand_write_seq[index] = axi_master_outstand_write_seq::type_id::create(name);
            rand_outstand_write_seq[index].num_of_outstand = 3;
            if(!rand_outstand_write_seq[index].randomize() with {burst_type == FIXED;}) begin
                `uvm_fatal("RANDOMIZATION_FAIL", {"randmozation fails in body method of: ", get_full_name(), ", for ", rand_outstand_write_seq[index].get_name()})
            end
            rand_outstand_write_seq[index].start(master_seqr[0]);
        end
        foreach(rand_outstand_read_seq[index]) begin
            $sformat(name, "rand_outstnd_read_seq[%0d]", index);
            rand_outstand_read_seq[index] = axi_master_outstand_read_seq::type_id::create(name);
            rand_outstand_read_seq[index].num_of_outstand = 3;
            if(!rand_outstand_read_seq[index].randomize() with {burst_type == FIXED;}) begin
                `uvm_fatal("RANDOMIZATION_FAIL", {"randmozation fails in body method of: ", get_full_name(), ", for ", rand_outstand_read_seq[index].get_name()})
            end
            rand_outstand_read_seq[index].start(master_seqr[0]);
        end
    join

endtask
