//--------------------------------------------------------------------
//Class: axi_slave_read_seq
//defines capability of read for slave agent
//--------------------------------------------------------------------
class axi_slave_read_seq extends axi_slave_base_seq;

    //UVM factory registration
    `uvm_object_utils(axi_slave_read_seq)

    //----------------------------------------------------------------
    //Data Members:
    //----------------------------------------------------------------

    //----------------------------------------------------------------
    //Methods:
    //----------------------------------------------------------------
    extern function new(string name = "slave_read_seq");
    extern task body();
    extern protected virtual task read_addr_ch();
    extern protected virtual task read_data_ch();

endclass


//--------------------------------------------------------------------
//Implementation:
//--------------------------------------------------------------------


//--------------------------------------------------------------------
//Class Constructor Method: new
//--------------------------------------------------------------------
function axi_slave_read_seq::new(string name = "slave_read_seq");
    
    super.new(name);

endfunction:new


//--------------------------------------------------------------------
//Method: body
//--------------------------------------------------------------------
task axi_slave_read_seq::body();

    //retrive the slave agent configuration object
    if(!uvm_config_db#(slave_agent_config)::get(null, get_full_name(), "slave_agent_config", cfg)) begin
        `config_retrival_fatal(cfg)
    end

    //wait for reset to end
    cfg.wait_for_reset_end();

    fork
        read_addr_ch();
        read_data_ch();
    join

endtask:body


//--------------------------------------------------------------------
//Method: read_addr_ch
//--------------------------------------------------------------------
task axi_slave_read_seq::read_addr_ch();

    slave_seq_item req_item;
    slave_seq_item rsp_item;

    forever begin:forever_loop

        //get the request from read_req_fifo of axi_slave_sequencer
        p_sequencer.read_req_fifo.get(req_item);

        //tell driver to assert AWREADY signal
        if(req_item.addr_valid == `HIGH) begin:read_valid_branch
        
            if(p_sequencer.read_addr_q.size() == `MAXRBURSTS) begin
                wait(p_sequencer.read_addr_q.size() < `MAXRBURSTS);
                if(p_sequencer.read_addr_q.size() == 0) begin
                    disable read_valid_branch;
                end
            end
            rsp_item = slave_seq_item::type_id::create("rsp_item");
            start_item(rsp_item);    //execute item on sequencer
            `uvm_info("SLV.READ_SEQ", "telling to assert --> RVALID", UVM_HIGH);
                
            //build response for read address channel transfer
            rsp_item.addr_valid = `HIGH;
            rsp_item.access_type = AXI_READ;

            finish_item(rsp_item);
            get_response(rsp_item);
            if(cfg.axi.ARESETn !== `LOW) begin
                p_sequencer.keep_ar_channel_info(req_item);
            end

        end


    end:forever_loop

endtask


//--------------------------------------------------------------------
//Method: read_data_ch
//--------------------------------------------------------------------
task axi_slave_read_seq::read_data_ch();

    slave_seq_item response_item;
    bit [`ADDR_BUS_WIDTH-1: 0] addr;

    forever begin:forever_loop

        //must have read address
        wait(p_sequencer.read_addr_q.size() != 0);

        if(!(p_sequencer.read_burst_length_q[0] inside {[0: cfg.burst_length-1]}) 
            || (2**p_sequencer.read_burst_size_q[0] > cfg.data_bus_bytes) 
            || !(cfg.supported_burst_type[p_sequencer.read_burst_type_q[0]] == 1'b1)
            || !(p_sequencer.read_addr_q[0] inside {[cfg.lower_addr: cfg.upper_addr]})) begin
                for(int transfer_num=0; transfer_num<=p_sequencer.read_burst_length_q[0]; transfer_num++) begin
                    if(p_sequencer.read_addr_q.size == 0) begin
                        break;
                    end
                    response_item = slave_seq_item::type_id::create("response_item");
                    start_item(response_item);
                    `uvm_info("SLV.READ_SEQ", "telling to assert --> RVALID", UVM_HIGH);
                    response_item.read_valid = `HIGH;
                    response_item.read_last = (transfer_num == p_sequencer.read_burst_length_q[0]) ? `HIGH : `LOW;
                    response_item.read_id = p_sequencer.read_addr_id_q[0];
                    $cast(response_item.read_response, SLVERR_RESP);
                    response_item.access_type = AXI_READ;
                    finish_item(response_item);
                    get_response(response_item);
                end
        end

        else begin
            for(int transfer_num=0; transfer_num<=p_sequencer.read_burst_length_q[0]; transfer_num++) begin
                if(p_sequencer.read_addr_q.size == 0) begin
                    break;
                end
                //find address of nth transfer
                addr = address_n(transfer_num, cfg.data_bus_bytes, p_sequencer.read_addr_q[0], p_sequencer.read_burst_length_q[0], p_sequencer.read_burst_size_q[0], p_sequencer.read_burst_type_q[0], wrapped, lower_byte_lane, upper_byte_lane);

                response_item = slave_seq_item::type_id::create("response_item");
                start_item(response_item);

                `uvm_info("SLV.READ_SEQ", "telling to assert --> RVALID", UVM_HIGH);
                response_item.read_valid = `HIGH;
                for(int byte_num=lower_byte_lane; byte_num<=upper_byte_lane; byte_num++, addr++) begin
                    if(!p_sequencer.storage.mem.exists(addr)) begin
                        response_item.read_data[8*byte_num+: 8] = 8'hAB;
                    end
                    else begin
                        response_item.read_data[8*byte_num+: 8] = p_sequencer.storage.read(addr);
                    end
                end

                response_item.read_last = (transfer_num == p_sequencer.read_burst_length_q[0]) ? `HIGH : `LOW;
                response_item.read_id = p_sequencer.read_addr_id_q[0];
                $cast(response_item.read_response, OKAY_RESP);
                response_item.access_type = AXI_READ;

                finish_item(response_item);
                get_response(response_item);

            end

        end
        p_sequencer.remove_ar_info();

    end:forever_loop

endtask:read_data_ch
