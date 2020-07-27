//------------------------------------------------------------------------
//Class: axi_master_outstand_read_seq
//Sequence API that used to initiate outstanding read transfer
//------------------------------------------------------------------------
class axi_master_outstand_read_seq extends axi_master_base_seq;

    //UVM factory registration macro
    `uvm_object_utils(axi_master_outstand_read_seq)

    //--------------------------------------------------------------------
    //Data Members:
    //--------------------------------------------------------------------
    rand bit [`ADDR_BUS_WIDTH-1: 0] start_addr[$];
    int num_of_outstand = 0;

    //--------------------------------------------------------------------
    //Constraints:
    //--------------------------------------------------------------------
    //constraint addr size
    constraint addr_size {start_addr.size() == num_of_outstand+1;}

    //constraint the transfer type to read
    constraint read_tr {access_type == AXI_READ;}

    //address alignment constraint... if wrap, start address must be aligned
    constraint address_alignement { 
        (burst_type == WRAP) -> foreach(start_addr[index]){start_addr[index] % (2**burst_size) == 0};
    }

    //--------------------------------------------------------------------
    //Method prototypes:
    //--------------------------------------------------------------------
    //Class Constructor method:
    extern function new(string name = "outstand_read_seq");

    //body method:
    extern task body();

endclass:axi_master_outstand_read_seq


//------------------------------------------------------------------------
//Implementation
//------------------------------------------------------------------------
//
//
//------------------------------------------------------------------------
//Class constructor method: new
//------------------------------------------------------------------------
function axi_master_outstand_read_seq::new(string name = "outstand_read_seq");

    super.new(name);

endfunction:new


//------------------------------------------------------------------------
//Method: body
//------------------------------------------------------------------------
task axi_master_outstand_read_seq::body();

    string name;
    //axi_master_read_seq handle
    axi_master_read_seq read_seq[] = new[num_of_outstand+1];

    if(num_of_outstand == 0) begin
        `uvm_error("NO_VALID_OUTSTAND_NUM", {"number of outstanding must be non-zero for: ", get_full_name(), ".num_of_outstand"})
    end

    //create and randomize all master read seq
    foreach(read_seq[index]) begin
        $sformat(name, "read_seq[%0d]", index);
        read_seq[index] = axi_master_read_seq::type_id::create(name);

    if(!read_seq[index].randomize() with { start_addr == local::start_addr[index];})begin
            `uvm_fatal("RANDOMIZATION_FAILS", $sformatf("randomization fails in body method of %0s sequence while randomizing %0s sequence", this.get_full_name(), read_seq[index].get_name()))
        end
    end

    //execute all sequences parallel
    foreach(read_seq[index]) begin
        axi_master_read_seq seq;
        $cast(seq, read_seq[index]);
        fork
            seq.start(m_sequencer, this);
        join_none
    end
    wait fork;

endtask:body
