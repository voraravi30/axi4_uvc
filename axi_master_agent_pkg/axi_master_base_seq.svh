//------------------------------------------------------------------------
//Class: axi_master_base_seq
//All sequence API derive from this base sequence 
//------------------------------------------------------------------------
`ifndef AXI_MASTER_BASE_SEQ
`define AXI_MASTER_BASE_SEQ
class axi_master_base_seq extends uvm_sequence#(master_seq_item);

    //UVM factory registration macro
    `uvm_object_utils(axi_master_base_seq)

    //--------------------------------------------------------------------
    //Data Members:
    //--------------------------------------------------------------------
    rand access_type_e access_type;
    rand axi_addr_t start_addr;
    rand axi_mid_t trans_id;
    rand axi_burst_e burst_type;
    rand axi_size_e burst_size;
    rand axi_length_t burst_length;
    rand axi_lock_type_e lock_type;
    rand axi_region_identifier_t region_identifier;
    rand axi_privileged_access_e  privileged_access_bit;
    rand axi_secure_access_e secure_access_bit;
    rand axi_data_instruction_access_e data_instruction_access_bit;
    rand axi_bufferable_bit_e bufferable_bit;
    rand axi_cacheable_bit_e cacheable_bit;
    rand axi_read_allocate_bit_e read_allocate_bit;
    rand axi_write_allocate_bit_e write_allocate_bit;

    //requeset transaction handle
    master_seq_item req;

    //master agent configuration handle
    master_agent_config cfg;

    //--------------------------------------------------------------------
    //Constraints:
    //--------------------------------------------------------------------
    //Constraint a burst_size to have legall value:
    constraint burst_size_c {2**burst_size <= `DATA_BUS_BYTES;}

    constraint address_alignement { 
        (burst_type == WRAP) -> start_addr % (2**burst_size) == 0;
        lock_type -> start_addr % ((2**burst_size)*burst_length) == 0;
    }

    //constraint a burst_length to have legall value:
    constraint burst_length_c {
        
        if(burst_type == FIXED){
            burst_length inside {[0:15]};
        }
        if(burst_type == INCR) {
            if(lock_type) {
                burst_length inside {[0:15]};
            }
            else {
                burst_length inside {[0:255]};
            }
        }
        if(burst_type == WRAP) {
            burst_length inside {1,3,7,15};
        }
    }

    //set default value of lock_type
    constraint deflt_lock_type_c { /*soft*/ lock_type == 0;}

    //set default value of privileged_access_bit, secure_access_bit and
    //data_instruction_access_bit
    constraint deflt_privileged_bit_c { /*soft*/ privileged_access_bit == 0;}
    constraint deflt_secure_bit_c { /*soft*/ secure_access_bit == 0;}
    constraint deflt_data_instruction_bit_c { /*soft*/ data_instruction_access_bit == 0;}

    //set the default value of write_allocate_bit, read_allocate_bit,
    //cacheable_bit, bufferable_bit
    constraint deflt_write_allocate_bit_c { /*soft*/ write_allocate_bit == 0;}
    constraint deflt_read_allocate_bit_c { /*soft*/ read_allocate_bit == 0;}
    constraint deflt_cacheable_bit_c { /*soft*/ cacheable_bit == 0;}
    constraint deflt_bufferable_bit_c { /*soft*/ bufferable_bit == 0;}

    //--------------------------------------------------------------------
    //Method:
    //--------------------------------------------------------------------
    //Class constructor method:
    extern function new(string name = "base_seq");
    extern task pre_start();
    extern task post_start();

endclass:axi_master_base_seq

//------------------------------------------------------------------------
//Implementation
//------------------------------------------------------------------------
//
//
//------------------------------------------------------------------------
//Class constructor method
//------------------------------------------------------------------------
function axi_master_base_seq::new(string name = "base_seq");

    super.new(name);

endfunction:new

//------------------------------------------------------------------------
//Method: pre_start
//------------------------------------------------------------------------
task axi_master_base_seq::pre_start();
    `uvm_info("PRE_START", {"starting a sequence ", get_name(), " on ", m_sequencer.get_full_name()}, UVM_HIGH)
endtask:pre_start


//------------------------------------------------------------------------
//Method: post_start
//------------------------------------------------------------------------
task axi_master_base_seq::post_start();
    `uvm_info("POST_START", {"ending a sequence ", get_name(), " on ", m_sequencer.get_full_name()}, UVM_HIGH)
endtask:post_start
`endif
