//-------------------------------------------------------------------------------
//Class : master_seq_item
//Defines the variables and sub-routines that used to create the axi
//transaction
//-------------------------------------------------------------------------------

`ifndef MASTER_SEQ_ITEM
`define MASTER_SEQ_ITEM
class master_seq_item extends uvm_sequence_item;

    //UVM factory registration macro
    `uvm_object_utils(master_seq_item)
    
    //--------------------------------------------------------------------------
    //Data Members:
    //--------------------------------------------------------------------------
    rand int unsigned delay;
    bit reset_detected;

    //represent the state of AXI transaction
    protected tr_state_e m_tr_state = AXI_CREATED;

    //master port_id
    protected bit [7: 0] m_port_id;

    //indicate type of access AXI_READ or AXI_WRITE
    rand access_type_e access_type;

    //address and control information field
    rand bit addr_valid;
    rand axi_addr_t start_addr;
    rand axi_mid_t trans_id;
    rand axi_burst_e burst_type;
    rand axi_size_e burst_size;
    rand axi_length_t burst_length;
    rand axi_lock_type_e lock_type;
    rand axi_prot_type_e prot_type;
    rand axi_memory_type_e memory_type;
    rand axi_region_identifier_t region_identifier;
    rand axi_qos_t quality_of_service;
    bit addr_ready;

    //write data channel field
    rand axi_data_t write_data_q[$];
    rand bit write_valid;
    axi_wstrb_t write_strobe;
    bit write_last;
    bit write_ready;

    //write response channel field
    bit write_response_valid;
    bit write_response_ready;
    axi_resp_e write_response;
    axi_mid_t  write_response_id;

    //read data channel field
    bit read_valid;
    bit read_ready;
    axi_data_t read_data_q[$];
    axi_mid_t read_id_q[$];
    axi_resp_e read_response_q[$];
    bit read_last;

    //
    rand axi_bufferable_bit_e bufferable_bit;
    rand axi_cacheable_bit_e cacheable_bit;
    rand axi_read_allocate_bit_e read_allocate_bit;
    rand axi_write_allocate_bit_e write_allocate_bit;

    rand axi_privileged_access_e privileged_access_bit;
    rand axi_secure_access_e secure_access_bit;
    rand axi_data_instruction_access_e data_instruction_access_bit;

    //---------------------------------------------------------------------------
    //CONSTRAINTS
    //---------------------------------------------------------------------------
    //make delay in justified range
    constraint delay_c {delay < 1000;}

    //constraint a burst_size to have legall value:
    constraint burst_size_c {2**burst_size <= `DATA_BUS_BYTES;}

    //valid indication constranits
    constraint write_valid_con {if(access_type == AXI_WRITE) write_valid == 1'b1; else write_valid == 1'b0;}
    constraint addr_valid_con {addr_valid == 1'b1;}
    constraint type_before_valid {solve access_type before write_valid;}

    //address alignment constraint... if wrap, start address must be aligned
    //and for lock type address must be aligned to total bytes in
    //a transaction that is product of burst size and burst length
    constraint address_alignement { 
        (burst_type == WRAP) -> start_addr % (2**burst_size) == 0;
        lock_type -> start_addr % ((2**burst_size)*burst_length) == 0;
    }

    //write_data_q array size constraint
    constraint write_data_q_size {write_data_q.size() == burst_length + 1'b1;}

    //contraint burst length
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
    constraint deflt_lock_type_c { /*soft*/ lock_type == NORMAL_ACCESS;}

    //set default value of privileged_access_bit, secure_access_bit and
    //data_instruction_access_bit
    constraint deflt_privileged_bit_c { /*soft*/ privileged_access_bit == 0;}
    constraint deflt_secure_bit_c { /*soft*/ secure_access_bit == 0;}
    constraint deflt_data_instruction_bit_c { /*soft*/ data_instruction_access_bit == 0;}

    //constraint prot_type field
    constraint prot_type_c {prot_type == {data_instruction_access_bit, secure_access_bit, privileged_access_bit};}

    //set the default value of write_allocate_bit, read_allocate_bit,
    //cacheable_bit, bufferable_bit
    constraint deflt_write_allocate_bit_c { /*soft*/ write_allocate_bit == 0;}
    constraint deflt_read_allocate_bit_c { /*soft*/ read_allocate_bit == 0;}
    constraint deflt_cacheable_bit_c { /*soft*/ cacheable_bit == 0;}
    constraint deflt_bufferable_bit_c { /*soft*/ bufferable_bit == 0;}

    //constraint memory_type field
    constraint memory_type_c {memory_type == {write_allocate_bit, read_allocate_bit, cacheable_bit, bufferable_bit};}

    //---------------------------------------------------------------------------
    //Method Prototype:
    //---------------------------------------------------------------------------
    //Class Constructor Method:
    extern function new(string name = "req_item");
    
    //do_copy method:
    extern function void do_copy(uvm_object rhs);

    //clone method:
    extern function uvm_object clone();

    //do_compare method:
    extern function bit do_compare(uvm_object rhs, uvm_comparer comparer);

    //convert2string method:
    extern virtual function string convert2string();

    //get the status of transaction item
    extern virtual function tr_state_e get_tr_state();

    //set the status of transaction item
    extern virtual function void set_tr_state(tr_state_e state);

    extern function void set_master_port_id(bit [7: 0] port_id);
    extern function bit [7: 0] get_master_port_id();
    
endclass:master_seq_item


//--------------------------------------------------------------------------------
//Implementation
//--------------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//Class Constructor Method: new
//--------------------------------------------------------------------------------
function master_seq_item::new(string name = "req_item");
    
    super.new(name);

endfunction:new

//--------------------------------------------------------------------------------
//Method: do_copy
//Called by the copy method... user do not this method directly
//--------------------------------------------------------------------------------
function void master_seq_item::do_copy(uvm_object rhs);

    master_seq_item rhs_;
    
    //downcast the argumnet object handle
    //to access the derived class properties
    if(!$cast(rhs_, rhs)) begin
        `object_casting_fatal(do_copy)
    end

    this.m_port_id = rhs_.m_port_id;
    this.delay = rhs_.delay;
    this.reset_detected = rhs_.reset_detected;
   
    this.access_type = rhs_.access_type;
    this.m_tr_state = rhs_.m_tr_state;

    this.addr_valid = rhs_.addr_valid;
    this.addr_ready = rhs_.addr_ready;
    this.start_addr = rhs_.start_addr;
    this.trans_id = rhs_.trans_id;
    this.burst_type = rhs_.burst_type;
    this.burst_length = rhs_.burst_length;
    this.burst_size = rhs_.burst_size;
    this.lock_type = rhs_.lock_type;
    this.prot_type = rhs_.prot_type;
    this.memory_type = rhs_.memory_type;
    this.region_identifier = rhs_.region_identifier;
    this.quality_of_service = rhs_.quality_of_service;

    this.write_valid = rhs_.write_valid;  
    this.write_ready = rhs_.write_ready;  
    this.write_data_q = rhs_.write_data_q;
    this.write_last = rhs_.write_last;   
    this.write_strobe = rhs_.write_strobe;
   
    this.write_response_valid = rhs_.write_response_valid;  
    this.write_response_ready = rhs_.write_response_ready;  
    this.write_response = rhs_.write_response;
    this.write_response_id = rhs_.write_response_id;  

    this.read_valid = rhs_.read_valid;
    this.read_ready = rhs_.read_ready;
    this.read_data_q = rhs_.read_data_q;
    this.read_id_q = rhs_.read_id_q;
    this.read_response_q = rhs_.read_response_q;
    this.read_last = rhs_.read_last;

endfunction:do_copy

//--------------------------------------------------------------------------------
//Method: clone
//create the object and deep copy this object and returns it.
//--------------------------------------------------------------------------------
function uvm_object master_seq_item::clone();

    master_seq_item lhs;
    lhs = master_seq_item::type_id::create();

    lhs.copy(this);
    return lhs;

endfunction:clone

//--------------------------------------------------------------------------------
//Method: convert2string
//returns the contents of object in string format.
//--------------------------------------------------------------------------------
function string master_seq_item::convert2string();

    convert2string = $sformatf("AXI Master[%0d]'s Transaction:\n", m_port_id);

    if(reset_detected) begin
        convert2string = {convert2string, "reset applied\n"};
    end

    //valid address and control info
    if(addr_valid) begin
        convert2string = {convert2string, $sformatf("address channel info for: %0s access\n",access_type.name())};
        convert2string = {convert2string, $sformatf("trans_id: 0x%0h\nstart_addr: 0x%0h\nburst_type: %0s\nburst_length: 0x%0h\nburst_size: %0s\nlock_type: %0s\nmemory_type: %0s\nprot_type: %0s\nregion_identifier: 0x%0h\nquality_of_service: 0x%h\n", trans_id, start_addr, burst_type.name(), burst_length, burst_size.name(), lock_type.name(), memory_type.name(), prot_type.name(), region_identifier, quality_of_service)};
    end

    //valid write data ch info
    if(write_valid) begin
        convert2string = {convert2string, $sformatf("\nwrite_strobe: 0b%b\n", write_strobe)};
        convert2string = {convert2string, "| write_data[index] = byte_value |\n"};
        foreach(write_data_q[num]) begin
            convert2string = {convert2string, $sformatf("|    data[0x%0h]      = 0x%0h\n", num, write_data_q[num])};
        end
    end
    
    //valid B ch info
    if(write_response_valid) begin
        convert2string = {convert2string, $sformatf("\nwrite_response_id: 0x%0h\nwrite_response: %0s\n",write_response_id, write_response.name())};
    end
    
    //valid R ch info
    if(read_valid) begin
        if(read_data_q.size != 0) begin
            convert2string = {convert2string, "\n| num = byte_value | read_id_q | read_response_q |\n"};
            foreach(read_data_q[num]) begin
                convert2string = {convert2string, $sformatf("| data[0x%0h] = 0x%0h| 0x%0h | %0s |\n", num, read_data_q[num], read_id_q[num], read_response_q[num].name())};
            end
        end
    end

endfunction:convert2string


//--------------------------------------------------------------------------------
//Method: do_compare
//--------------------------------------------------------------------------------
function bit master_seq_item::do_compare(uvm_object rhs, uvm_comparer comparer);
endfunction:do_compare


//--------------------------------------------------------------------------------
//Method: set_tr_state
//set the transaction item state
//--------------------------------------------------------------------------------
function void master_seq_item::set_tr_state(tr_state_e state);
    this.m_tr_state = state;
endfunction:set_tr_state


//--------------------------------------------------------------------------------
//Method: get_tr_state
//get the transaction item state
//--------------------------------------------------------------------------------
function tr_state_e master_seq_item::get_tr_state();
    return this.m_tr_state;
endfunction:get_tr_state


//----------------------------------------------------------------------------
//Method: set_master_port_id
//----------------------------------------------------------------------------
function void master_seq_item::set_master_port_id(bit [7: 0] port_id);

    this.m_port_id = port_id;

endfunction:set_master_port_id


//----------------------------------------------------------------------------
//Method: get_master_port_id
//----------------------------------------------------------------------------
function bit [7: 0] master_seq_item::get_master_port_id();

    return this.m_port_id;

endfunction:get_master_port_id
`endif
