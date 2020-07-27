//---------------------------------------------------------------------------
//Class: axi_wrap_narrow_write_to_read_vseq
//sequence that generate traffic for narrow wrap burst write and read back
//---------------------------------------------------------------------------
class axi_wrap_narrow_write_to_read_vseq extends axi_virtual_sequence_base;

    //UVM factory registration macro
    `uvm_object_utils(axi_wrap_narrow_write_to_read_vseq)

    //---------------------------------------------------------------------
    //Data Members:
    //---------------------------------------------------------------------
    int no_of_iteration = 2;

    //---------------------------------------------------------------------
    //Methods: 
    //---------------------------------------------------------------------
    //Class Constructor Method:
    extern function new(string name = "narrow_write_to_read_vseq");

    //body method
    extern task body();

endclass:axi_wrap_narrow_write_to_read_vseq



//------------------------------------------------------------------------------------
//Implementation
//------------------------------------------------------------------------------------
//
//
//
//------------------------------------------------------------------------------------
//Class Constructor Method: new
//------------------------------------------------------------------------------------
function axi_wrap_narrow_write_to_read_vseq::new(string name = "narrow_write_to_read_vseq");

    super.new(name);

endfunction:new


//------------------------------------------------------------------------------------
//Method: body
//create and execute axi_master_wrap_write_seq, axi_master_wrap_read_seq and axi_slave_main_seq on corresponding
//sequencer
//------------------------------------------------------------------------------------
task axi_wrap_narrow_write_to_read_vseq::body();

    //axi master sequence that generate legal wrap burst traffic
    axi_master_wrap_write_seq wrap_write_seq;
    axi_master_wrap_read_seq wrap_read_seq;
    //axi_slave_main_seq
    axi_slave_main_seq slave_main_seq;

    //create slave sequence
    slave_main_seq = axi_slave_main_seq::type_id::create("slave_main_seq");

    if(no_of_iteration == 0) begin
        `uvm_fatal("NO_VALID_ITERATION", {"no_of_iteration must be non-zero for", get_full_name(), ".no_of_iteration"});
    end
    
    //execute slave_main_seq
    fork
        slave_main_seq.start(slave_seqr[0]);
    join_none

    repeat(no_of_iteration) begin

        //create master sequences
        wrap_write_seq = axi_master_wrap_write_seq::type_id::create("wrap_write_seq");
        wrap_read_seq = axi_master_wrap_read_seq::type_id::create("wrap_read_seq");

        //randomize wrap_write_seq and execute it
        if(!wrap_write_seq.randomize() with {2**burst_size < `DATA_BUS_BYTES;}) begin
            `uvm_fatal("RANDOMIZATION_FAIL", {"randmozation fails in body method of: ", get_full_name(), ", for ", wrap_write_seq.get_name(), " sequence"})
        end
        wrap_write_seq.start(master_seqr[0]);

        //randomize wrap_read_seq and execute it
        if(!wrap_read_seq.randomize() with {start_addr == wrap_write_seq.start_addr;
                                             burst_length == wrap_write_seq.burst_length;
                                             burst_size == wrap_write_seq.burst_size;
                                            }) begin
            `uvm_fatal("RANDOMIZATION_FAIL", {"randmozation fails in body method of: ", get_full_name(), ", for ", wrap_read_seq.get_name(), " sequence"})
        end
        wrap_read_seq.start(master_seqr[0]);

    end

endtask
