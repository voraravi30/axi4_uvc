//-------------------------------------------------------------------------
//Class: axi_slave_sequencer
//Provides Channels and Arbitration mechanism which facilate the
//commnication between sequences and driver and also have the functionality of
//analysis seqr_fifo which used to buffer the request initiated by axi master
//-------------------------------------------------------------------------
class axi_slave_sequencer extends uvm_sequencer #(slave_seq_item);

    //UVM factory registration
    `uvm_component_utils(axi_slave_sequencer)

    //------------------------------------------------------------------------------
    //Data Members:
    //------------------------------------------------------------------------------
    //analysis imp that connect to slave monitor's analysis req_port to
    //initiated request transaction
    uvm_analysis_imp #(slave_seq_item, axi_slave_sequencer) req_imp;

    //analysis fifo for each write and read for seprate handling of write and
    //read fifo
    uvm_tlm_analysis_fifo #(slave_seq_item) write_req_fifo;
    uvm_tlm_analysis_fifo #(slave_seq_item) read_req_fifo;

    //points to storage component inside slave agent
    axi_storage_component storage;

    //queues to buffer address and control information of write and read, and
    //write data
    axi_addr_t write_addr_q[$];
    axi_burst_e write_burst_type_q[$];
    axi_size_e write_burst_size_q[$];
    axi_length_t write_burst_length_q[$];
    axi_sid_t write_addr_id_q[$];
    axi_lock_type_e write_lock_type_q[$];
    axi_prot_type_e write_prot_type_q[$];
    axi_memory_type_e write_memory_type_q[$];
    axi_region_identifier_t write_region_identifier_q[$];
    axi_qos_t write_quality_of_service_q[$];

    axi_wstrb_t write_strobe_q[$];
    axi_data_t write_data_q[$];

    axi_addr_t read_addr_q[$];
    axi_burst_e read_burst_type_q[$];
    axi_size_e read_burst_size_q[$];
    axi_length_t read_burst_length_q[$];
    axi_sid_t read_addr_id_q[$];
    axi_lock_type_e read_lock_type_q[$];
    axi_prot_type_e read_prot_type_q[$];
    axi_memory_type_e read_memory_type_q[$];
    axi_region_identifier_t read_region_identifier_q[$];
    axi_qos_t read_quality_of_service_q[$];

    //------------------------------------------------------------------------------
    //Methods:
    //------------------------------------------------------------------------------
    //Class Constructor Method: new
    extern function new(string name, uvm_component parent);

    //UVM Standard Phases:
    extern function void build_phase(uvm_phase phase);

    //write method for analysis_imp port req_imp 
    extern virtual function void write(slave_seq_item t);

    //flsuh internal buffer queue
    extern virtual function void flush_queue();
    extern virtual function void keep_aw_channel_info(slave_seq_item req_item);
    extern virtual function void keep_w_channel_info(slave_seq_item req_item);
    extern virtual function void keep_ar_channel_info(slave_seq_item req_item);
    extern virtual function void remove_write_info();
    extern virtual function void remove_ar_info();

endclass:axi_slave_sequencer



//------------------------------------------------------------------------------
//Implementation:
//------------------------------------------------------------------------------



//------------------------------------------------------------------------------
//Class Constructor Method: new
//------------------------------------------------------------------------------
function axi_slave_sequencer::new(string name, uvm_component parent);

    super.new(name,parent);

endfunction:new



//------------------------------------------------------------------------------
//Method: build_phase
//------------------------------------------------------------------------------
function void axi_slave_sequencer::build_phase(uvm_phase phase);

    super.build_phase(phase);

    //create analysis req_imp
    req_imp = new("req_imp", this);

    //create write and read analyis fifo 
    write_req_fifo = new("write_req_fifo", this);
    read_req_fifo = new("read_req_fifo", this);

endfunction:build_phase


//------------------------------------------------------------------------------
//Method: write
//provide write method impelentation for analysis_imp port req_imp
//------------------------------------------------------------------------------
function void axi_slave_sequencer::write(slave_seq_item t);

    slave_seq_item item;

    if(!$cast(item, t.clone())) begin
        `object_casting_fatal(write);
    end

    //delete information that are buffered and reset the storage component
    //using reset_memory API
    if(item.reset_detected == `HIGH) begin

        flush_queue();
        storage.reset_memory();

    end

    else begin

        if((item.addr_valid && item.access_type == AXI_WRITE) || item.write_valid) begin
            write_req_fifo.write(item);
        end

        if(item.addr_valid && item.access_type == AXI_READ) begin
            read_req_fifo.write(item);
        end
    
    end

endfunction:write


//------------------------------------------------------------------------------
//Method: flush_queue
//------------------------------------------------------------------------------
function void axi_slave_sequencer::flush_queue();

    write_addr_q.delete();
    write_burst_type_q.delete();
    write_burst_size_q.delete();
    write_burst_length_q.delete();
    write_addr_id_q.delete();
    write_lock_type_q.delete();
    write_prot_type_q.delete();
    write_memory_type_q.delete();
    write_region_identifier_q.delete();
    write_quality_of_service_q.delete();

    write_strobe_q.delete();
    write_data_q.delete();

    read_addr_q.delete();
    read_burst_type_q.delete();
    read_burst_size_q.delete();
    read_burst_length_q.delete();
    read_addr_id_q.delete();
    read_lock_type_q.delete();
    read_prot_type_q.delete();
    read_memory_type_q.delete();
    read_region_identifier_q.delete();
    read_quality_of_service_q.delete();


endfunction:flush_queue

//--------------------------------------------------------------------
//Method: keep_aw_channel_info
//--------------------------------------------------------------------
function void axi_slave_sequencer::keep_aw_channel_info(slave_seq_item req_item);

    write_addr_q.push_back(req_item.start_addr);
    write_burst_type_q.push_back(req_item.burst_type);
    write_burst_size_q.push_back(req_item.burst_size);
    write_burst_length_q.push_back(req_item.burst_length);
    write_addr_id_q.push_back(req_item.trans_id);
    write_lock_type_q.push_back(req_item.lock_type);
    write_prot_type_q.push_back(req_item.prot_type);
    write_memory_type_q.push_back(req_item.memory_type);
    write_region_identifier_q.push_back(req_item.region_identifier);
    write_quality_of_service_q.push_back(req_item.quality_of_service);

endfunction:keep_aw_channel_info


//--------------------------------------------------------------------
//Method: keep_w_channel_info
//--------------------------------------------------------------------
function void axi_slave_sequencer::keep_w_channel_info(slave_seq_item req_item);

    write_data_q.push_back(req_item.write_data);
    write_strobe_q.push_back(req_item.write_strobe);

endfunction:keep_w_channel_info

//--------------------------------------------------------------------
//Method: remove_write_info
//--------------------------------------------------------------------
function void axi_slave_sequencer::remove_write_info();

    //remove written data from queue
    repeat(write_burst_length_q[0]+1) begin
        if(write_data_q.size() != 0) begin
            write_data_q.delete(0);
        end
        if(write_strobe_q.size() != 0) begin
            write_strobe_q.delete(0);
        end
    end

    //remove write address channel information after write operation
    if(write_addr_q.size != 0) begin
        write_addr_q.delete(0);
        write_burst_type_q.delete(0);
        write_burst_size_q.delete(0);
        write_burst_length_q.delete(0);
        write_addr_id_q.delete(0);
        write_lock_type_q.delete(0);
        write_prot_type_q.delete(0);
        write_memory_type_q.delete(0);
        write_region_identifier_q.delete(0);
        write_quality_of_service_q.delete(0);

    end

endfunction:remove_write_info


//--------------------------------------------------------------------
//Method: keep_ar_channel_info
//--------------------------------------------------------------------
function void axi_slave_sequencer::keep_ar_channel_info(slave_seq_item req_item);

    read_addr_q.push_back(req_item.start_addr);
    read_burst_type_q.push_back(req_item.burst_type);
    read_burst_size_q.push_back(req_item.burst_size);
    read_burst_length_q.push_back(req_item.burst_length);
    read_addr_id_q.push_back(req_item.trans_id);
    read_lock_type_q.push_back(req_item.lock_type);
    read_prot_type_q.push_back(req_item.prot_type);
    read_memory_type_q.push_back(req_item.memory_type);
    read_region_identifier_q.push_back(req_item.region_identifier);
    read_quality_of_service_q.push_back(req_item.quality_of_service);

endfunction:keep_ar_channel_info


//--------------------------------------------------------------------
//Method: remove_ar_info
//--------------------------------------------------------------------
function void axi_slave_sequencer::remove_ar_info();

    if(read_addr_q.size != 0) begin
         read_addr_q.delete(0);
         read_burst_type_q.delete(0);
         read_burst_size_q.delete(0);
         read_burst_length_q.delete(0);
         read_addr_id_q.delete(0);
         read_lock_type_q.delete(0);
         read_prot_type_q.delete(0);
         read_memory_type_q.delete(0);
         read_region_identifier_q.delete(0);
         read_quality_of_service_q.delete(0);
     end

endfunction:remove_ar_info
