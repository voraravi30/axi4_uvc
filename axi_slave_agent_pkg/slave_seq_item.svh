//-------------------------------------------------------------------------------
//Class : slave_seq_item
//Defines the variables and sub-routines that used to responsed to initiated AXI
//transaction
//-------------------------------------------------------------------------------
class slave_seq_item extends uvm_sequence_item;

    //UVM factory registration
    `uvm_object_utils(slave_seq_item)

    //-----------------------------------------------------------------
    //Data Members:
    //-----------------------------------------------------------------
    rand bit [2: 0] delay;
    bit reset_detected;
    protected bit [7: 0] m_port_id;
    protected tr_state_e m_tr_state;
    access_type_e access_type;

    //WRITE ADDRESS CHANNEL FIELDS
    bit addr_valid;
    axi_addr_t start_addr;
    axi_burst_e burst_type;
    axi_size_e burst_size;
    axi_length_t burst_length;
    axi_sid_t trans_id;
    axi_lock_type_e lock_type;
    axi_prot_type_e prot_type;
    axi_memory_type_e memory_type;
    axi_region_identifier_t region_identifier;
    axi_qos_t quality_of_service;
    rand bit addr_ready;

    //WRITE DATA CHANNEL FIELDS
    axi_data_t write_data;
    axi_wstrb_t write_strobe;
    bit write_last;
    bit write_valid;
    rand bit write_ready;

    //WRITE RESPONSE CHANNEL FIELDS
    rand bit write_response_valid;
    rand axi_resp_e write_response;
    rand axi_sid_t write_response_id;
    bit write_response_ready;

    //READ DATA CHANNEL FIELDS
    rand bit read_valid;
    rand axi_data_t read_data;
    rand axi_sid_t read_id;
    rand axi_resp_e read_response;
    rand bit read_last;
    bit read_ready;

    //Class Constructor Method:
    extern function new(string name = "rsp_item");
    
    //do_copy method:
    extern function void do_copy(uvm_object rhs);
    
    //clone method:
    extern function uvm_object clone();
    
    //convert2string method:
    extern virtual function string convert2string();

    //Conveience menthod:
    extern virtual function void set_tr_state(tr_state_e state);
    extern virtual function tr_state_e get_tr_state();

    extern function void set_slave_port_id(bit [7: 0] port_id);
    extern function bit [7: 0] get_slave_port_id();

endclass:slave_seq_item



//-------------------------------------------------------------------
//Implementation:
//-------------------------------------------------------------------


//-------------------------------------------------------------------
//Class Constructor Method: new
//-------------------------------------------------------------------
function slave_seq_item::new(string name = "rsp_item");
    
    super.new(name);

endfunction:new




//-------------------------------------------------------------------
//Method: do_copy
//-------------------------------------------------------------------
function void slave_seq_item::do_copy(uvm_object rhs);

    slave_seq_item rhs_;
    if(!$cast(rhs_, rhs)) begin
        `object_casting_fatal(do_copy)
    end

    this.delay = rhs_.delay;
    this.reset_detected = rhs_.reset_detected;
    this.m_tr_state = rhs_.m_tr_state;
    this.access_type = rhs_.access_type;
   
    this.addr_valid = rhs_.addr_valid;
    this.addr_ready = rhs_.addr_ready;
    this.start_addr = rhs_.start_addr;
    this.burst_type = rhs_.burst_type;
    this.burst_length = rhs_.burst_length;
    this.burst_size = rhs_.burst_size;
    this.trans_id = rhs_.trans_id;
    this.lock_type = rhs_.lock_type;
    this.prot_type = rhs_.prot_type;
    this.memory_type = rhs_.memory_type;
    this.region_identifier = rhs_.region_identifier;
    this.quality_of_service = rhs_.quality_of_service;

    this.write_data = rhs_.write_data;
    this.write_valid = rhs_.write_valid;
    this.write_ready = rhs_.write_ready;
    this.write_last = rhs_.write_last;
    this.write_strobe = rhs_.write_strobe;
   
    this.write_response_valid = rhs_.write_response_valid;
    this.write_response_ready = rhs_.write_response_ready;
    this.write_response = rhs_.write_response;
    this.write_response_id = rhs_.write_response_id;

    this.read_valid = rhs_.read_valid;
    this.read_ready = rhs_.read_ready;
    this.read_data = rhs_.read_data;
    this.read_id = rhs_.read_id;
    this.read_response = rhs_.read_response;
    this.read_last = rhs_.read_last;

endfunction:do_copy


//-------------------------------------------------------------------
//Method: clone
//-------------------------------------------------------------------
function uvm_object slave_seq_item::clone();

    slave_seq_item lhs;
    lhs = slave_seq_item::type_id::create();

    lhs.copy(this);
    return lhs;

endfunction:clone



//-------------------------------------------------------------------
//Method: convert2string
//-------------------------------------------------------------------
function string slave_seq_item::convert2string();

    convert2string = $sformatf("AXI Slave[%0d]'s %0s Transaction:\n", m_port_id, access_type.name());

    //valid address and control info
    if(addr_valid) begin
        convert2string = {convert2string, $sformatf("\ntrans_id: 0x%0h\nstart_addr: 0x%0h\nburst_type: %0s\nburst_length: 0x%0h\nburst_size: %0s\nlock_type: %0s\nmemory_type: %0s\nprot_type: %0s\nregion_identifier: 0x%0h\nquality_of_service: 0x%0h\n", trans_id, start_addr, burst_type.name(), burst_length, burst_size.name(), lock_type.name(), memory_type.name(), prot_type.name(), region_identifier, quality_of_service)};
    end

    //valid W ch info
    if(write_valid) begin
        convert2string = {convert2string, $sformatf("\nwrite_data: 0x%h\nwrite_strobe: 0b%b\nwrite_last: %0b\n", write_data, write_strobe, write_last)};
    end
    
    //valid B ch info
    if(write_response_valid) begin
        convert2string = {convert2string, $sformatf("write_response_id: 0x%0h\nwrite_response: %0s\n",write_response_id, write_response.name())};
    end
    
    //valid R ch info
    if(read_valid) begin
        convert2string = {convert2string, $sformatf("\nread_last: 0b%b\nread data = 0x%h\nread_id: 0x%0h\nread_response: %0s\n", read_last, read_data, read_id, read_response)};
    end

endfunction:convert2string


//-------------------------------------------------------------------
//Method: set_tr_state
//-------------------------------------------------------------------
function void slave_seq_item::set_tr_state(tr_state_e state);
    this.m_tr_state = state;
endfunction:set_tr_state


//-------------------------------------------------------------------
//Method: get_tr_state
//-------------------------------------------------------------------
function tr_state_e slave_seq_item::get_tr_state();
    return this.m_tr_state;
endfunction


//----------------------------------------------------------------------------
//Method: set_slave_port_id
//----------------------------------------------------------------------------
function void slave_seq_item::set_slave_port_id(bit [7: 0] port_id);

    this.m_port_id = port_id;

endfunction:set_slave_port_id


//----------------------------------------------------------------------------
//Method: get_slave_port_id
//----------------------------------------------------------------------------
function bit [7: 0] slave_seq_item::get_slave_port_id();

    return this.m_port_id;

endfunction:get_slave_port_id
