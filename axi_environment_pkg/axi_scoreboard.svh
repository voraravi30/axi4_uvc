//----------------------------------------------------------------------------------------
//Class: axi_scoreboard
//instantiate axi_predictor and axi_comparator component to implement
//self-checking functionality
//----------------------------------------------------------------------------------------
class axi_scoreboard extends uvm_scoreboard;

    //UVM factory registration macro
    `uvm_component_utils(axi_scoreboard)

    //----------------------------------------------------------------------------------------
    //Data members:
    //----------------------------------------------------------------------------------------
    //environment config object handle
    axi_env_config cfg;

    //analysis export for input stimuls transaction
    uvm_analysis_export #(master_seq_item) input_export[];

    //analysis fifo that stores input stimuls
    uvm_tlm_analysis_fifo #(master_seq_item) input_fifo;

    //storage space for all slave
    bit [7: 0] mem[int unsigned];

    //buffer initiated txn
    axi_master_txn_buffer txn_buffer;

    //write response buffer
    axi_resp_e write_response_q[int][$];
    axi_mid_t write_response_id_q[int][$];

    //read response buffer
    axi_data_t read_data_q[int][$];
    axi_mid_t read_id_q[int][$];
    axi_resp_e read_response_q[int][$];

    bit write_trans_is_valid;
    bit read_trans_is_valid;

    int transfer_num[int] = '{default: 0};
    bit wrapped[int] = '{default: 0};

    //keeps track of total ran, passed and failed transaction
    int trans_cnt, pass_cnt, fail_cnt;

    //Class Constructor Method:
    extern function new(string name, uvm_component parent);
    
    //UVM Standard Phases:
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
    extern function void report_phase(uvm_phase phase);

    //Predictor method:
    extern function void predictor(master_seq_item item);

    //comapre and search method:
    extern function void compare_and_search(master_seq_item item);

    //calculate next transfer address
    extern virtual function axi_addr_t address_n(int nth_transfer, data_bus_bytes, axi_addr_t start_addr, axi_length_t length, axi_size_e burst_size, axi_burst_e burst_type, inout bit wrapped, output int lower_byte_lane, upper_byte_lane);

    //calculate valid byte lane
    extern function void find_valid_byte_lane(int data_bus_bytes, axi_wstrb_t wstrb, output int lower_byte_lane, upper_byte_lane);

    //search read response in a queue
    extern function bit search_read_resp(int id, read_id, output int transaction_num);

endclass:axi_scoreboard


//----------------------------------------------------------------------------------------
//Implementation
//----------------------------------------------------------------------------------------


//----------------------------------------------------------------------------------------
//Class Constructor Method: new
//----------------------------------------------------------------------------------------
function axi_scoreboard::new(string name, uvm_component parent);
  
    super.new(name, parent);

endfunction:new


//----------------------------------------------------------------------------------------
//Method: build_phase
//create required numbre of analysis export and txn_buffer
//----------------------------------------------------------------------------------------
function void axi_scoreboard::build_phase(uvm_phase phase);

    string name;

    super.build_phase(phase);

    //Get the AXI Environment Configuration from Configuration space.
    if(!uvm_config_db #(axi_env_config)::get(this, "", "axi_env_config", cfg)) begin
        `config_retrival_fatal(cfg)
    end

    //create analysis export for input stimuls transaction
    input_export = new[cfg.num_of_master];
    for(int num=0; num<cfg.num_of_master; num++) begin
        $sformat(name, "input_export[%0d]", num);
        input_export[num] = new(name, this);
    end

    //create analyis fifo: input_fifo
    input_fifo =  new("input fifo", this);

endfunction:build_phase


//----------------------------------------------------------------------------------------
//Method: connect_phase
//connect input stimuls export to predictor analyis_export
//connect predictor analysis port to expected analysis export of comparator
//----------------------------------------------------------------------------------------
function void axi_scoreboard::connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    //connect input stimuls transaction export to predictor's analyis export
    foreach(input_export[num]) begin
        input_export[num].connect(input_fifo.analysis_export);
    end

endfunction:connect_phase


//----------------------------------------------------------------------------------------
//Method: run_phase
//----------------------------------------------------------------------------------------
task axi_scoreboard::run_phase(uvm_phase phase);

    master_seq_item item;
    master_seq_item req;
    int id;

    //create txn buffer
    txn_buffer = axi_master_txn_buffer::type_id::create("txn_buffer");

    forever begin

        //get the input stimuls from input_fifo
        input_fifo.get(item);
        if(!$cast(req, item.clone())) begin
            `object_casting_fatal(run_phase)
        end

        if(req.reset_detected) begin
            id = item.get_master_port_id();
            txn_buffer.flush(id);
            foreach(mem[addr]) begin
                mem[addr] = 0;
            end
            if(transfer_num.exists(id)) begin
                transfer_num[id] = 0;
            end
            if(wrapped.exists(id)) begin
                wrapped[id] = 0;
            end
            if(write_response_q.exists(id)) begin
                if(write_response_q[id].size() != 0) begin
                    write_response_q[id].delete();
                    write_response_id_q[id].delete();
                end
            end
            if(read_response_q.exists(id)) begin
                if(read_id_q[id].size() != 0) begin
                    read_id_q[id].delete();
                    read_response_q[id].delete();
                end
            end
        end
        else begin
            //calculate the expected value
            if(req.addr_valid || req.write_valid) begin
                predictor(req);
                if(req.addr_valid) begin
                    trans_cnt++;
                end
            end

            //search expected value in buffer and compare againts actual value
            if(req.write_response_valid || req.read_valid) begin
                compare_and_search(req);
            end
        end

    end

endtask

//----------------------------------------------------------------------------------------
//Method: report_phase
//prints the total ran, passed and failed transaction count
//----------------------------------------------------------------------------------------
function void axi_scoreboard::report_phase(uvm_phase phase);

    uvm_report_info("SCOREBOARD", $sformatf("\n\t\t----------------------------------\n\t\tTotal ran Tansaction: %0d\n\t\tPassed Transaction: %0d\n\t\tFailed Tranaction: %0d\n\t\t----------------------------------\n", trans_cnt, pass_cnt, fail_cnt), UVM_NONE);

endfunction:report_phase

//----------------------------------------------------------------------------------------
//Method: predictor
//predict the expected output or response for applied input stimuls
//----------------------------------------------------------------------------------------
function void axi_scoreboard::predictor(master_seq_item item);

    int lower_byte_lane;
    int upper_byte_lane;
    int id = item.get_master_port_id();

    //write_addr
    if(item.addr_valid && item.access_type == AXI_WRITE) begin:AW_CH

        //check for correctness of write address and control information
        foreach(cfg.slave_cfg[num]) begin

            //check for correctness of write address
            if(item.start_addr inside {[cfg.slave_cfg[num].lower_addr: cfg.slave_cfg[num].upper_addr]}) begin

                //check for correctness of write control information
                if(!(item.burst_length inside {[0: cfg.slave_cfg[num].burst_length-1]}) || (2**item.burst_size > cfg.slave_cfg[num].data_bus_bytes) || !(cfg.slave_cfg[num].supported_burst_type[item.burst_type] == 1'b1)) begin
                    //illegal write transaction is initiated
                    write_trans_is_valid = 0;
                end
                else begin
                    //legal write transaction is initiated
                    write_trans_is_valid = 1;
                end
                break;
            end

        end
        //buffer the write address channel information
        txn_buffer.accept_write_addr_ch_info(item, write_trans_is_valid);

        //buffer OKAY_RESP for correct write transaction initiation
        if(write_trans_is_valid) begin
            write_response_q[id].push_back(OKAY_RESP);
            write_response_id_q[id].push_back(item.trans_id);
        end
        //buffer SLVERR_RESP for illegal write transaction initiation
        else begin
            write_response_q[id].push_back(SLVERR_RESP);
            write_response_id_q[id].push_back(item.trans_id);
        end

        //check write data available for given master port id
        if(txn_buffer.write_data_q.exists(id)) begin
            //check for enough write data available for write transaction...
            if(txn_buffer.write_data_q[id].size() >= item.burst_length+1) begin
                //if write transaction address and control info is correct,
                //store write data into memory
                if(txn_buffer.write_trans_is_valid[id][0]) begin
                    for(int transfer_num=0, bit wrapped=0, axi_addr_t addr=0; transfer_num<=item.burst_length; transfer_num++) begin
                        addr = address_n(transfer_num, cfg.master_cfg[id].data_bus_bytes, txn_buffer.write_addr_q[id][0], txn_buffer.write_burst_length_q[id][0], txn_buffer.write_burst_size_q[id][0], txn_buffer.write_burst_type_q[id][0], wrapped, lower_byte_lane, upper_byte_lane);
                        find_valid_byte_lane(cfg.master_cfg[id].data_bus_bytes, txn_buffer.write_strobe_q[id].pop_front(), lower_byte_lane, upper_byte_lane);
                        for(int valid_lane=lower_byte_lane; valid_lane<=upper_byte_lane; valid_lane++,addr++) begin
                            mem[addr] = txn_buffer.write_data_q[id][0][8*valid_lane+: 8];
                        end
                        txn_buffer.write_data_q[id].delete(0);
                    end
                end
                //if write transaction address and control info is not correct,
                //ignore write data for that transaction 
                else begin
                    repeat(item.burst_length+1) begin
                        txn_buffer.write_data_q[id].delete(0);
                        txn_buffer.write_strobe_q[id].delete(0);
                    end
                end
                //remove served write addr and control info
                txn_buffer.remove_write_addr_ch_info(id);
            end
        end
    end:AW_CH

    //write_data
    if(item.write_valid) begin:W_CH
        
        //buffer write data channel info
        txn_buffer.accept_write_data_ch_info(item);

        //check for AW channel info is buffered for given master port id
        if(txn_buffer.write_addr_q.exists(id) && txn_buffer.write_trans_is_valid.exists(id)) begin

            //write a data into memory if there is AW info already buffered
            //and that write address and control info is correct
            if(txn_buffer.write_trans_is_valid[id][0]) begin
                while(txn_buffer.write_addr_q[id].size() != 0 && txn_buffer.write_data_q[id].size() != 0) begin
                    axi_addr_t addr = address_n(transfer_num[id], cfg.master_cfg[id].data_bus_bytes, txn_buffer.write_addr_q[id][0], txn_buffer.write_burst_length_q[id][0], txn_buffer.write_burst_size_q[id][0], txn_buffer.write_burst_type_q[id][0], wrapped[id], lower_byte_lane, upper_byte_lane);
                    find_valid_byte_lane(cfg.master_cfg[id].data_bus_bytes, txn_buffer.write_strobe_q[id].pop_front(), lower_byte_lane, upper_byte_lane);
                    for(int valid_lane=lower_byte_lane; valid_lane<=upper_byte_lane; valid_lane++,addr++) begin
                        mem[addr] = txn_buffer.write_data_q[id][0][8*valid_lane+: 8];
                    end
                    txn_buffer.write_data_q[id].delete(0);
                    transfer_num[id]++;
                    if(transfer_num[id] == txn_buffer.write_burst_length_q[id][0]) begin
                        txn_buffer.remove_write_addr_ch_info(id);
                        transfer_num[id] = 0;
                        wrapped[id] = 0;
                    end
                end
            end
            //ignore write data if write address and control info is not correct
            else begin
                while(txn_buffer.write_addr_q[id].size() != 0 && txn_buffer.write_data_q[id].size() != 0) begin
                    txn_buffer.write_data_q[id].delete(0);
                    txn_buffer.write_strobe_q[id].delete(0);
                    transfer_num[id]++;
                    if(transfer_num[id] == txn_buffer.write_burst_length_q[id][0]) begin
                        txn_buffer.remove_write_addr_ch_info(id);
                        transfer_num[id] = 0;
                        wrapped[id] = 0;
                    end
                end
            end
        end
    end:W_CH

    //read_addr
    if(item.addr_valid && item.access_type == AXI_READ) begin:AR_CH

        //check for correctness of read address and control information
        foreach(cfg.slave_cfg[num]) begin

            //check for correctness of read address
            if(item.start_addr inside {[cfg.slave_cfg[num].lower_addr: cfg.slave_cfg[num].upper_addr]}) begin
                //check for correctness of read control info
                if(!(item.burst_length inside {[0: cfg.slave_cfg[num].burst_length-1]}) || (2**item.burst_size > cfg.slave_cfg[num].data_bus_bytes) || !(cfg.slave_cfg[num].supported_burst_type[item.burst_type] == 1'b1)) begin
                    //illegal read transaction is initiated
                    read_trans_is_valid = 0;
                end
                else begin
                    //llegal read transaction is initiated
                    read_trans_is_valid = 1;
                end
                break;
            end

        end
        //buffer the read address channel info
        txn_buffer.accept_read_addr_ch_info(item, read_trans_is_valid);

        //buffer the response for read transaction
        if(read_trans_is_valid) begin
            repeat(item.burst_length + 1) begin
                //OKAY_RESP for legal read transaction
                read_id_q[id].push_back(item.trans_id);
                read_response_q[id].push_back(OKAY_RESP);
            end
        end
        else begin
            repeat(item.burst_length + 1) begin
                //SLVERR_RESP for legal read transaction
                read_id_q[id].push_back(item.trans_id);
                read_response_q[id].push_back(SLVERR_RESP);
            end
        end
    end:AR_CH

endfunction:predictor


//----------------------------------------------------------------------------------------
//Method: compare_and_search
//compare the expected response againts the actual response from dut
//----------------------------------------------------------------------------------------
function void axi_scoreboard::compare_and_search(master_seq_item item);

    int id = item.get_master_port_id();

    //write response
    if(item.write_response_valid) begin
        if(write_response_id_q.exists(id) && write_response_q.exists(id)) begin
            if(item.write_response_id != write_response_id_q[id][0] && item.write_response != write_response_q[id][0]) begin
                fail_cnt++;
                `uvm_error("TRANSACTION_FAILS", $sformatf("\n--------------------------------\nexpected write response is:\n\twrite_response_id: 0x%0h\n\twrite_response: %0s\nactual write response is:\n\twrite_response_id: 0x%0h\n\twrite_response: %0s\n--------------------------------\n", write_response_id_q[id][0], write_response_q[id][0].name(), item.write_response_id, item.write_response.name()))
            end
            else begin
                pass_cnt++;
            end
            write_response_id_q[id].delete(0);
            write_response_q[id].delete(0);
        end
        else begin
            `uvm_error("TRANSACTION_FAILS", $sformatf("Write response is not available for AXI Master: %0d", id));
            fail_cnt++;
        end
    end

endfunction:compare_and_search


//----------------------------------------------------------------------------
//Method: address_n
//----------------------------------------------------------------------------
function axi_addr_t axi_scoreboard::address_n(int nth_transfer, data_bus_bytes, axi_addr_t start_addr, axi_length_t length, axi_size_e burst_size, axi_burst_e burst_type, inout bit wrapped, output int lower_byte_lane, upper_byte_lane);

    bit [8: 0] burst_length = length + 1'b1;
    bit [7: 0] number_bytes = 2**burst_size;
    axi_addr_t aligned_addr = (((start_addr/number_bytes))*(number_bytes));
    axi_addr_t lower_wrap_boundary = ((start_addr/(number_bytes*burst_length))*(number_bytes*burst_length));
    axi_addr_t upper_wrap_boundary = (lower_wrap_boundary + (number_bytes*burst_length));

    //address_n calculation
    case(burst_type)
        2'b00: address_n = start_addr;    //fixed burst type

        2'b01: begin    //incr burst type
            if(nth_transfer == 0)begin
                address_n = start_addr;
            end
            else begin
                address_n = aligned_addr + (nth_transfer*number_bytes);
            end
        end
        
        2'b10: begin    //wrap burst type
            
            if(nth_transfer == 0) begin
                address_n = start_addr;
            end
            else begin

                if(!wrapped) begin
                    address_n = aligned_addr + (nth_transfer*number_bytes);
                    if(address_n >= upper_wrap_boundary) begin
                        wrapped = 1'b1;
                        address_n = lower_wrap_boundary;
                    end
                end
                else begin
                    address_n = start_addr + (nth_transfer*number_bytes) - (number_bytes * burst_length);
                    if(address_n >= upper_wrap_boundary) begin
                        address_n = lower_wrap_boundary;
                    end
                end
            end
        end

        default: begin
            `uvm_error("BURST_TYPE_ERROR", {"unsupported burst type encounterd by: ", get_full_name(), "in address_n() method"})
        end
    endcase

        if(nth_transfer == length) begin
            wrapped = 0;
        end

        //strobe calculation
        case(burst_type)
            2'b00: begin
                lower_byte_lane =  address_n - (address_n/data_bus_bytes)*data_bus_bytes;
                upper_byte_lane = aligned_addr + (number_bytes - 1) - ((start_addr/data_bus_bytes)*data_bus_bytes);
            end

            2'b01, 2'b10: begin
                if(nth_transfer == 0) begin
                    lower_byte_lane =  address_n - (address_n/data_bus_bytes)*data_bus_bytes;
                    upper_byte_lane = aligned_addr + (number_bytes - 1) - ((start_addr/data_bus_bytes)*data_bus_bytes);
                end
                else begin
                    lower_byte_lane =  address_n - (address_n/data_bus_bytes)*data_bus_bytes;
                    upper_byte_lane = lower_byte_lane + number_bytes -1;
                end
            end
        endcase

endfunction:address_n


//----------------------------------------------------------------
//Method: find_valid_byte_lane
//----------------------------------------------------------------
function void axi_scoreboard::find_valid_byte_lane(int data_bus_bytes, axi_wstrb_t wstrb, output int lower_byte_lane, upper_byte_lane);

    //lower valid lane
    for(int lane=0; lane<data_bus_bytes;lane++) begin
        if(wstrb[lane] == 1'b1) begin
            lower_byte_lane = lane;
            break;
        end
    end
    //upper valid lane
    for(int lane=lower_byte_lane; lane<data_bus_bytes;lane++) begin
        if(wstrb[lane] == 1'b0) begin
            upper_byte_lane = lane - 1;
            return;
        end
    end

    upper_byte_lane = data_bus_bytes - 1;

endfunction:find_valid_byte_lane


//----------------------------------------------------------------------------------------
//Method: search_read_resp
//----------------------------------------------------------------------------------------
function bit axi_scoreboard::search_read_resp(int id, read_id, output int transaction_num);
    for(int num=0; num<read_id_q[id].size(); num++) begin
        if(read_id_q[id][num] == read_id) begin
            transaction_num = num;
            return 1;
        end
    end
    return 0;
endfunction:search_read_resp
