//------------------------------------------------------------------------
//Class: axi_master_outstand_write_seq
//Sequence API that used to initiate outstanding write transfer
//------------------------------------------------------------------------
class axi_master_outstand_write_seq extends axi_master_base_seq;

    //UVM factory registration macro
    `uvm_object_utils(axi_master_outstand_write_seq)

    //--------------------------------------------------------------------
    //Data Members:
    //--------------------------------------------------------------------
    rand bit [`ADDR_BUS_WIDTH-1: 0] start_addr[$];
    rand bit [7: 0] data[$];
    int num_of_outstand = 0;

    //--------------------------------------------------------------------
    //Constraints:
    //--------------------------------------------------------------------
    //constraint data size
    constraint data_size {data.size() == (burst_length + 1'b1)*(2**burst_size)*(num_of_outstand+1);}

    //constraint addr size
    constraint addr_size {start_addr.size() == num_of_outstand+1;}

    //constraint the transfer type to write
    constraint write_tr {access_type == AXI_WRITE;}

    //address alignment constraint... if wrap, start address must be aligned
    constraint address_alignement { 
        (burst_type == WRAP) -> foreach(start_addr[index]){start_addr[index] % (2**burst_size) == 0};
    }

    //--------------------------------------------------------------------
    //Method prototypes:
    //--------------------------------------------------------------------
    //Class Constructor method:
    extern function new(string name = "outstand_write_seq");

    //body method:
    extern task body();

endclass:axi_master_outstand_write_seq


//------------------------------------------------------------------------
//Implementation
//------------------------------------------------------------------------
//
//
//------------------------------------------------------------------------
//Class constructor method: new
//------------------------------------------------------------------------
function axi_master_outstand_write_seq::new(string name = "outstand_write_seq");

    super.new(name);

endfunction:new


//------------------------------------------------------------------------
//Method: body
//------------------------------------------------------------------------
task axi_master_outstand_write_seq::body();

    string name;
    //axi_master_write_seq handle
    axi_master_write_seq write_seq[] = new[num_of_outstand+1];

    if(num_of_outstand == 0) begin
        `uvm_error("NO_VALID_OUTSTAND_NUM", {"number of outstanding must be non-zero for: ", get_full_name(), ".num_of_outstand"})
    end

    //create and randomize all master write seq
    foreach(write_seq[index]) begin
        $sformat(name, "write_seq[%0d]", index);
        write_seq[index] = axi_master_write_seq::type_id::create(name);

        if(!write_seq[index].randomize() with { start_addr == local::start_addr[index];
                                               // foreach(data[i]){
                                                 //   if(index == 0) {data[i] == local::data[i];}
                                                   // else {data[i] == local::data[((write_seq[index-1].burst_length+1)*(2**write_seq[index-1].burst_size))+i];}
                                                //}
                                              })begin
                                                  `uvm_fatal("RANDOMIZATION_FAILS", $sformatf("randomization fails in body method of %0s sequence while randomizing %0s sequence", this.get_full_name(), write_seq[index].get_name()))
                                              end
    end

    //execute all write_seq concurrently
    foreach(write_seq[index]) begin
        axi_master_write_seq seq;
        $cast(seq, write_seq[index]);
        fork
            seq.start(m_sequencer, this);
        join_none
    end
    wait fork;

endtask:body
