//--------------------------------------------------------------------
//Class: axi_slave_write_seq
//defines capability of write for slave agent
//--------------------------------------------------------------------
class axi_slave_write_seq extends axi_slave_base_seq;

    //UVM factory registration
    `uvm_object_utils(axi_slave_write_seq)

    //----------------------------------------------------------------
    //Methods:
    //----------------------------------------------------------------
    extern function new(string name = "slave_write_seq");
    extern task body();
    extern protected virtual task write_addr_ch();
    extern protected virtual task write_data_ch();
    extern protected virtual task write_response_ch();
    extern virtual function void accept_write_transfer(int transfer_num);

endclass


//--------------------------------------------------------------------
//Implementation:
//--------------------------------------------------------------------


//--------------------------------------------------------------------
//Class Constructor Method: new
//--------------------------------------------------------------------
function axi_slave_write_seq::new(string name = "slave_write_seq");
    
    super.new(name);

endfunction:new


//--------------------------------------------------------------------
//Method: body
//--------------------------------------------------------------------
task axi_slave_write_seq::body();

    //retrive the slave agent configuration object
    if(!uvm_config_db#(slave_agent_config)::get(null, get_full_name(), "slave_agent_config", cfg)) begin
        `config_retrival_fatal(cfg)
    end

    cfg.wait_for_reset_end();

    fork
        write_addr_ch();
        write_data_ch();
        write_response_ch();
    join


endtask:body


//--------------------------------------------------------------------
//Method: write_addr_ch
//give response for AW channel and accept it's address and control info
//--------------------------------------------------------------------
task axi_slave_write_seq::write_addr_ch();

    slave_seq_item req_item;
    slave_seq_item rsp_item;

    forever begin

        //peek write request information from write_req_fifo
        p_sequencer.write_req_fifo.peek(req_item);

        //if request information is for AW channel get it and give response.
        if(req_item.addr_valid == `HIGH) begin: addr_valid_branch
            p_sequencer.write_req_fifo.get(req_item);

            if(p_sequencer.write_addr_q.size() == `MAXWBURSTS) begin
                wait(p_sequencer.write_addr_q.size() < `MAXWBURSTS);
                if(p_sequencer.write_addr_q.size() == 0) begin
                    disable addr_valid_branch;
                end
            end
            //tell driver to assert AWREADY signal
            rsp_item = slave_seq_item::type_id::create("rsp_item");
            start_item(rsp_item);
            `uvm_info("SLAVE.WRITE_SEQ.WRITE_ADDR_CH","telling slave driver to assert --> AWREADY", UVM_HIGH)
                
            //build response for write address channel transfer
            rsp_item.addr_valid = `HIGH;
            rsp_item.access_type = AXI_WRITE;

            finish_item(rsp_item);
            get_response(rsp_item);
            if(cfg.axi.ARESETn !== `LOW) begin
                p_sequencer.keep_aw_channel_info(req_item);
            end

        end

    end

endtask:write_addr_ch


//--------------------------------------------------------------------
//Method: write_data_ch
//give response for W channel and accept the write info on this channel
//--------------------------------------------------------------------
task axi_slave_write_seq::write_data_ch();

    slave_seq_item req_item;
    slave_seq_item rsp_item;

    forever begin

        //peek write request information from write_req_fifo
        p_sequencer.write_req_fifo.peek(req_item);

        //if request information is for W channel get it and give response.
        if(req_item.write_valid == `HIGH) begin:data_valid_branch

            p_sequencer.write_req_fifo.get(req_item);

            if(p_sequencer.write_data_q.size() == (`MAXWBURSTS*cfg.data_bus_bytes*cfg.burst_length)) begin
                wait(p_sequencer.write_data_q.size() < (`MAXWBURSTS*cfg.data_bus_bytes*cfg.burst_length));
                if(p_sequencer.write_addr_q.size() == 0) begin
                    disable data_valid_branch;
                end
            end
            //tell driver to assert WREADY signal
            rsp_item = slave_seq_item::type_id::create("rsp_item");
            start_item(rsp_item);
            `uvm_info("SLAVE.WRITE_SEQ.WRITE_DATA_CH", "telling slave driver to assert --> WREADY", UVM_HIGH)
                
            //build response for write address channel transfer
            rsp_item.write_valid = `HIGH;
            rsp_item.access_type = AXI_WRITE;

            finish_item(rsp_item);
            get_response(rsp_item);
            if(cfg.axi.ARESETn !== `LOW) begin
                p_sequencer.keep_w_channel_info(req_item);
            end

        end

    end

endtask:write_data_ch


//--------------------------------------------------------------------
//Method: write_response_ch
//generate write response for complete write transfer
//--------------------------------------------------------------------
task axi_slave_write_seq::write_response_ch();

    slave_seq_item response_item;

    forever begin:forever_loop

        //must have address
        wait(p_sequencer.write_addr_q.size() !=0);

        //check for burst is supported or not
        //if not supported give SLVERR response and discard write transfer 
        //else OKAY response and accept the transfer
        if(!(p_sequencer.write_burst_length_q[0] inside {[0: cfg.burst_length-1]})
            || (2**p_sequencer.write_burst_size_q[0] > cfg.data_bus_bytes) 
               || !(cfg.supported_burst_type[p_sequencer.write_burst_type_q[0]] == 1'b1)
               || !(p_sequencer.write_addr_q[0] inside {[cfg.lower_addr: cfg.upper_addr]})) begin

            //wait until enough write data available for the current burst
            wait(p_sequencer.write_data_q.size() == p_sequencer.write_burst_length_q[0]+1 || p_sequencer.write_addr_q.size() == 0);

            if(p_sequencer.write_addr_q.size != 0) begin
                //create response_item with SLVERR response for unsupported burst
                response_item = slave_seq_item::type_id::create("response_item");
                start_item(response_item);
                `uvm_info("SLAVE.WRITE_SEQ.WRITE_RESPONSE_CH","telling slave driver to assert --> BVALID", UVM_HIGH)
                response_item.write_response_valid = `HIGH;
                $cast(response_item.write_response, SLVERR_RESP);
                response_item.access_type = AXI_WRITE;
                response_item.write_response_id = p_sequencer.write_addr_id_q[0];
                finish_item(response_item);
                //discard the transfer
                p_sequencer.remove_write_info();
                get_response(response_item);
            end
        end

        else begin
            for(int transfer_num=0; transfer_num<=p_sequencer.write_burst_length_q[0]; transfer_num++) begin
                wait(p_sequencer.write_data_q.size() >= transfer_num+1 || p_sequencer.write_addr_q.size() == 0);
                if(p_sequencer.write_addr_q.size() == 0) begin
                    break;
                end
                accept_write_transfer(transfer_num);
            end

            if(p_sequencer.write_addr_q.size() != 0) begin
                //create response_item with OKAY response for complete write transfer
                response_item = slave_seq_item::type_id::create("response_item");
                start_item(response_item);
                `uvm_info("SLAVE.WRITE_SEQ.WRITE_RESPONSE_CH","telling slave driver to assert --> BVALID", UVM_HIGH)
                response_item.write_response_valid = `HIGH;
                $cast(response_item.write_response, OKAY_RESP);
                response_item.write_response_id = p_sequencer.write_addr_id_q[0];
                response_item.access_type = AXI_WRITE;
                finish_item(response_item);
                //remove served write transfer info
                p_sequencer.remove_write_info();
                get_response(response_item);
            end
        end

    end:forever_loop

endtask:write_response_ch


//--------------------------------------------------------------------
//Method: accept_write_transfer
//--------------------------------------------------------------------
function void axi_slave_write_seq::accept_write_transfer(int transfer_num);

    axi_addr_t addr;

    //find address of nth transfer
    addr = address_n(transfer_num, cfg.data_bus_bytes, p_sequencer.write_addr_q[0], p_sequencer.write_burst_length_q[0], p_sequencer.write_burst_size_q[0], p_sequencer.write_burst_type_q[0], wrapped, lower_byte_lane, upper_byte_lane);

    //find which byte lane has valid data
    find_valid_byte_lane(cfg.data_bus_bytes, p_sequencer.write_strobe_q[transfer_num], lower_byte_lane, upper_byte_lane);  
    for(int valid_lane=lower_byte_lane; valid_lane<=upper_byte_lane; valid_lane++,addr++) begin
        p_sequencer.storage.write(addr, p_sequencer.write_data_q[transfer_num][8*valid_lane+: 8]);
    end

endfunction:accept_write_transfer
