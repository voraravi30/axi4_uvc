//-----------------------------------------------------------------------
//Class: axi_master_txn_buffer
//temparory buffer the initiated transaction by the master
//-----------------------------------------------------------------------
`ifndef AXI_MASTER_TXN_BUFFER
`define AXI_MASTER_TXN_BUFFER
class axi_master_txn_buffer extends uvm_object;

    //UVM factory registration
    `uvm_object_utils(axi_master_txn_buffer)

    //-------------------------------------------------------------------
    //Data members:
    //-------------------------------------------------------------------
    bit write_trans_is_valid[int][$];
    axi_addr_t write_addr_q[int][$];
    axi_burst_e write_burst_type_q[int][$];
    axi_size_e write_burst_size_q[int][$];
    axi_length_t write_burst_length_q[int][$];
    axi_sid_t write_addr_id_q[int][$];
    axi_lock_type_e write_lock_type_q[int][$];
    axi_prot_type_e write_prot_type_q[int][$];
    axi_memory_type_e write_memory_type_q[int][$];
    axi_region_identifier_t write_region_identifier_q[int][$];
    axi_qos_t write_qos_q[int][$];

    axi_wstrb_t write_strobe_q[int][$];
    axi_data_t write_data_q[int][$];

    bit read_trans_is_valid[int][$];
    axi_addr_t read_addr_q[int][$];
    axi_burst_e read_burst_type_q[int][$];
    axi_size_e read_burst_size_q[int][$];
    axi_length_t read_burst_length_q[int][$];
    axi_sid_t read_addr_id_q[int][$];
    axi_lock_type_e read_lock_type_q[int][$];
    axi_prot_type_e read_prot_type_q[int][$];
    axi_memory_type_e read_memory_type_q[int][$];
    axi_region_identifier_t read_region_identifier_q[int][$];
    axi_qos_t read_qos_q[int][$];

    //-------------------------------------------------------------------
    //Method:
    //-------------------------------------------------------------------
    extern function new(string name = "txn_buffer");
    extern function void flush(int id);
    extern function void accept_write_addr_ch_info(master_seq_item item, bit is_valid);
    extern function void accept_write_data_ch_info(master_seq_item item);
    extern function void accept_read_addr_ch_info(master_seq_item item, bit is_valid);
    extern function void remove_write_addr_ch_info(int id);
    extern function void remove_read_addr_ch_info(int id);

endclass:axi_master_txn_buffer

//--------------------------------------------------------------------
//Class Constructor method: new
//--------------------------------------------------------------------
function axi_master_txn_buffer::new(string name = "txn_buffer");

    super.new(name);

endfunction:new

//------------------------------------------------------------------------------
//Method: flush
//flush the buffer on reset
//------------------------------------------------------------------------------
function void axi_master_txn_buffer::flush(int id);

    if(write_addr_q.exists(id)) begin
        if(write_addr_q[id].size() != 0) begin
            write_trans_is_valid[id].delete();
            write_addr_q[id].delete();
            write_burst_type_q[id].delete();
            write_burst_size_q[id].delete();
            write_burst_length_q[id].delete();
            write_addr_id_q[id].delete();
            write_lock_type_q[id].delete();
            write_prot_type_q[id].delete();
            write_memory_type_q[id].delete();
            write_region_identifier_q[id].delete();
            write_qos_q[id].delete();
        end
    end
    
    if(write_strobe_q.exists(id)) begin
        if(write_strobe_q[id].size() != 0) begin
            write_strobe_q[id].delete();
        end
    end

    if(write_data_q.exists(id)) begin
        if(write_data_q[id].size() != 0) begin
            write_data_q[id].delete();
        end
    end

    if(read_addr_q.exists(id)) begin
        if(read_addr_q[id].size() != 0) begin
            read_trans_is_valid[id].delete();
            read_addr_q[id].delete();
            read_burst_type_q[id].delete();
            read_burst_size_q[id].delete();
            read_burst_length_q[id].delete();
            read_addr_id_q[id].delete();
            read_lock_type_q[id].delete();
            read_prot_type_q[id].delete();
            read_memory_type_q[id].delete();
            read_region_identifier_q[id].delete();
            read_qos_q[id].delete();
        end
    end
    
endfunction:flush

//--------------------------------------------------------------------
//Method: accept_write_addr_ch_info
//--------------------------------------------------------------------
function void axi_master_txn_buffer::accept_write_addr_ch_info(master_seq_item item, bit is_valid);

    int id = item.get_master_port_id();
    write_trans_is_valid[id].push_back(is_valid);
    write_addr_q[id].push_back(item.start_addr);
    write_burst_type_q[id].push_back(item.burst_type);
    write_burst_size_q[id].push_back(item.burst_size);
    write_burst_length_q[id].push_back(item.burst_length);
    write_addr_id_q[id].push_back(item.trans_id);
    write_lock_type_q[id].push_back(item.lock_type);
    write_prot_type_q[id].push_back(item.prot_type);
    write_memory_type_q[id].push_back(item.memory_type);
    write_region_identifier_q[id].push_back(item.region_identifier);
    write_qos_q[id].push_back(item.quality_of_service);

endfunction:accept_write_addr_ch_info

//--------------------------------------------------------------------
//Method: accept_write_data_ch_info
//--------------------------------------------------------------------
function void axi_master_txn_buffer::accept_write_data_ch_info(master_seq_item item);

    int id = item.get_master_port_id();
    write_data_q[id].push_back(item.write_data_q[0]);
    write_strobe_q[id].push_back(item.write_strobe);

endfunction:accept_write_data_ch_info

//--------------------------------------------------------------------
//Method: remove_write_addr_ch_info
//--------------------------------------------------------------------
function void axi_master_txn_buffer::remove_write_addr_ch_info(int id);

    if(write_addr_q.exists(id)) begin
        if(write_addr_q[id].size != 0) begin
            write_trans_is_valid[id].delete(0);
            write_addr_q[id].delete(0);
            write_burst_type_q[id].delete(0);
            write_burst_size_q[id].delete(0);
            write_burst_length_q[id].delete(0);
            write_addr_id_q[id].delete(0);
            write_lock_type_q[id].delete(0);
            write_prot_type_q[id].delete(0);
            write_memory_type_q[id].delete(0);
            write_region_identifier_q[id].delete(0);
            write_qos_q[id].delete(0);
        end
    end

endfunction:remove_write_addr_ch_info

//--------------------------------------------------------------------
//Method: accept_read_addr_ch_info
//--------------------------------------------------------------------
function void axi_master_txn_buffer::accept_read_addr_ch_info(master_seq_item item, bit is_valid);

    int id = item.get_master_port_id();

    read_trans_is_valid[id].push_back(is_valid);
    read_addr_q[id].push_back(item.start_addr);
    read_burst_type_q[id].push_back(item.burst_type);
    read_burst_size_q[id].push_back(item.burst_size);
    read_burst_length_q[id].push_back(item.burst_length);
    read_addr_id_q[id].push_back(item.trans_id);
    read_lock_type_q[id].push_back(item.lock_type);
    read_prot_type_q[id].push_back(item.prot_type);
    read_memory_type_q[id].push_back(item.memory_type);
    read_region_identifier_q[id].push_back(item.region_identifier);
    read_qos_q[id].push_back(item.quality_of_service);

endfunction:accept_read_addr_ch_info


//--------------------------------------------------------------------
//Method: remove_write_addr_ch_info
//--------------------------------------------------------------------
function void axi_master_txn_buffer::remove_read_addr_ch_info(int id);

    if(read_addr_q.exists(id)) begin
        if(read_addr_q[id].size != 0) begin
            read_trans_is_valid[id].delete(0);
            read_addr_q[id].delete(0);
            read_burst_type_q[id].delete(0);
            read_burst_size_q[id].delete(0);
            read_burst_length_q[id].delete(0);
            read_addr_id_q[id].delete(0);
            read_lock_type_q[id].delete(0);
            read_prot_type_q[id].delete(0);
            read_memory_type_q[id].delete(0);
            read_region_identifier_q[id].delete(0);
            read_qos_q[id].delete(0);
        end
    end

endfunction:remove_read_addr_ch_info
`endif
