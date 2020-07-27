//------------------------------------------------------------------------------------
//Class : axi_master_driver
//axi_master_driver component responsible for taking actual simulation
//traffic from the sequencer and drives it on the axi interface
//------------------------------------------------------------------------------------

`ifndef AXI_MASTER_DRIVER
`define AXI_MASTER_DRIVER
class axi_master_driver extends uvm_driver #(master_seq_item);

    //UVM factory registration Method:
    `uvm_component_utils(axi_master_driver)

    //-----------------------------------------------------------------
    //Data Members:
    //-----------------------------------------------------------------
    //master port id
    protected bit [7: 0] m_port_id;

    //virtual interface handle of axi master interface
    virtual axi_master_if.mdrv_mp AXI;

    //configuration object handle
    master_agent_config cfg;

    //requeset queues
    master_seq_item write_request_que[$];
    master_seq_item read_request_que[$];

    //ensure anyone address channel thread have access to get_request at
    //a time
    semaphore get_request_lock;

    //-----------------------------------------------------------------
    //Prototype of Methods:
    //-----------------------------------------------------------------
    //Class Constructor Method:
    extern function new(string name, uvm_component parent);
    
    //UVM Standard Phase Method:
    extern task run_phase(uvm_phase phase);
    extern function void build_phase(uvm_phase phase);
    extern function void end_of_elaboration_phase(uvm_phase phase);

    //Master driver specific method
    extern protected virtual task write_addr_ch();
    extern protected virtual task write_data_ch();    //write data channel operation
    extern protected virtual task write_response_ch();    //get the response of write operation
    extern protected virtual task read_addr_ch();    //initiate the read addr channel operation
    extern protected virtual task read_data_ch();    //perform the read data channel operation

    //get the request item from the sequence
    extern protected virtual task get_transaction_item();

    //method route back response to sequence for sequence_item which are
    //stopped due to reset assertion
    extern protected virtual task put_response_on_reset();
    
    //find request_index of particular request from request_que for which response has been given
    //using RESPONSE ID value(BID or RID)
    extern protected virtual function int find_request(axi_mid_t response_id, access_type_e access_type);

    //find strobe value:
    extern function axi_wstrb_t find_valid_byte_lane(int nth_transfer, data_bus_bytes, axi_addr_t start_addr, axi_length_t length, axi_size_e burst_size, axi_burst_e burst_type, ref bit wrapped, output int lower_byte_lane, upper_byte_lane);
    
    //Conveience method:
    extern function void set_master_port_id(bit [7: 0] port_id);
    extern function bit [7: 0] get_master_port_id();

endclass:axi_master_driver

//----------------------------------------------------------------------------
//Implementation:
//----------------------------------------------------------------------------



//----------------------------------------------------------------------------
//function : Class constructor method
//Create the master driver component and return the handle
//----------------------------------------------------------------------------
function axi_master_driver::new(string name, uvm_component parent);
    
    super.new(name, parent);

endfunction:new


//----------------------------------------------------------------------------
//Method: build_phase
//----------------------------------------------------------------------------
function void axi_master_driver::build_phase(uvm_phase phase);

    super.build_phase(phase);

    //get the configuration 
    if(!uvm_config_db#(master_agent_config)::get(this, "", "master_agent_config", cfg)) begin
        `config_retrival_fatal(cfg);
    end

endfunction:build_phase


//----------------------------------------------------------------------------
//Method: end_of_elaboration_phase
//----------------------------------------------------------------------------
function void axi_master_driver::end_of_elaboration_phase(uvm_phase phase);

    super.end_of_elaboration_phase(phase);

    set_master_port_id(cfg.port_id);

endfunction:end_of_elaboration_phase


//----------------------------------------------------------------------------
//task : run phase
//Continuously drives the stimuls on dut interface and monitor the reset
//----------------------------------------------------------------------------
task axi_master_driver::run_phase(uvm_phase phase);

    if(AXI == null) begin
        `vif_null_fatal(AXI)
    end

    //concurrently excutes the reset_detection process and stimuls drive
    forever begin

        //create semaphore with one key
        get_request_lock = new(1);

        fork
            
            begin:reset_detect_process

                //wait for reset to be asserted
                wait(AXI.ARESETn === 0);

                //reset response route back to the sequences for seqence_item
                //which are stopped due to reset
                put_response_on_reset();

                do begin
                    `uvm_info("RESET", {"\nreset assertion detected by component: ", get_full_name(),"\n"}, UVM_LOW)
                    disable drv_process;

                    AXI.mdrv_cb.AWVALID <= `LOW;
                    AXI.mdrv_cb.WVALID  <= `LOW;
                    AXI.mdrv_cb.ARVALID <= `LOW;
                    AXI.mdrv_cb.RREADY <= `LOW;
                    AXI.mdrv_cb.BREADY <= `LOW;

                    @(posedge AXI.ACLK);
                end
                while(AXI.ARESETn !== `HIGH);
                `uvm_info("RESET", {"\nreset de-assertion detected by component: ", get_full_name(),"\n"}, UVM_LOW)

            end:reset_detect_process

            begin:drv_process

                //wait until reset de-asserted
                wait(AXI.ARESETn === 1);

                //All AXI Channels starts concurrently
                fork
                    get_transaction_item();
                    write_addr_ch();
                    write_data_ch();
                    write_response_ch();
                    read_addr_ch();
                    read_data_ch();
                join
                
                disable reset_detect_process;

            end:drv_process

        join
    
    end

endtask:run_phase


//----------------------------------------------------------------------------
//Method: get_transaction_item
//get the request item from the sequence
//----------------------------------------------------------------------------
task axi_master_driver::get_transaction_item();

    forever begin

        master_seq_item req;

        seq_item_port.get(req);

        case(req.access_type)
            AXI_WRITE: write_request_que.push_back(req);
            AXI_READ: read_request_que.push_back(req);
        endcase

    end

endtask:get_transaction_item


//----------------------------------------------------------------------------
//Method: put_response_on_reset
//Method will route back the response from driver to sequence for
//sequence_item which are stopped/unserved due to reset assertion
//----------------------------------------------------------------------------
task axi_master_driver::put_response_on_reset();

    if(write_request_que.size() != 0 || read_request_que.size() != 0) begin

        `uvm_info("MASTER.DRV.PUT_RESPONSE_ON_RESET", "start of put_response_on_reset method", UVM_HIGH)
        
        //put reponse for the remaining request which are stopped due to reset
        foreach(write_request_que[response_index]) begin
            if(write_request_que[response_index].get_tr_state() != AXI_FINISHED) begin
                write_request_que[response_index].set_tr_state(AXI_STOPPED);
                `uvm_info("MASTER.DRV.PUT_RESPONSE_ON_RESET", $sformatf("puting reset response for m_sequence_id: 0x%0x and request_index: 0x%0x with response:- transfer_state: %0s", write_request_que[response_index].get_sequence_id(), response_index, write_request_que[response_index].get_tr_state()), UVM_HIGH)
                seq_item_port.put(write_request_que[response_index]);
            end
        end
        //flush the request_que
        write_request_que.delete();

        foreach(read_request_que[response_index]) begin
            if(read_request_que[response_index].get_tr_state() != AXI_FINISHED) begin
                read_request_que[response_index].set_tr_state(AXI_STOPPED);
                `uvm_info("MASTER.DRV.PUT_RESPONSE_ON_RESET", $sformatf("puting reset response for m_sequence_id: 0x%0x and request_index: 0x%0x with response:- transfer_state: %0s", read_request_que[response_index].get_sequence_id(), response_index, read_request_que[response_index].get_tr_state()), UVM_HIGH)
                seq_item_port.put(read_request_que[response_index]);
            end
        end
        //flush the request_que
        read_request_que.delete();

        `uvm_info("MASTER.DRV.PUT_RESPONSE_ON_RESET", "end of put_response_on_reset method", UVM_HIGH)
    
    end

endtask:put_response_on_reset


//----------------------------------------------------------------------------
//task: write_addr_ch
//----------------------------------------------------------------------------
task axi_master_driver::write_addr_ch();

    master_seq_item req_item;
    int request_index = 0;

    forever begin

        `uvm_info("MASTER.DRV.WRITE_ADDR_CH", "requesting for transaction from sequence", UVM_HIGH)
        wait(write_request_que.size() > request_index);
        req_item = write_request_que[request_index];
        `uvm_info("MASTER.DRV.WRITE_ADDR_CH", $sformatf("get the request of type: %0s", req_item.access_type.name()), UVM_HIGH)

        `uvm_info("MASTER.DRV.WRITE_ADDR_CH", $sformatf("AW channel transfer initiate with start_addr: 0x%0h trans_id: 0x%0h burst_type: %0s burst_length: 0x%0h burst_size: %0s", req_item.start_addr, req_item.trans_id, req_item.burst_type.name(), req_item.burst_length, req_item.burst_size.name()), UVM_MEDIUM)
            
        //drives the valid address and control information
        AXI.mdrv_cb.AWVALID <= `HIGH;
        AXI.mdrv_cb.AWID <= req_item.trans_id;
        AXI.mdrv_cb.AWADDR <= req_item.start_addr;
        AXI.mdrv_cb.AWBURST <= req_item.burst_type;
        AXI.mdrv_cb.AWSIZE <= req_item.burst_size;
        AXI.mdrv_cb.AWLEN <= req_item.burst_length;
        AXI.mdrv_cb.AWLOCK <= req_item.lock_type;
        AXI.mdrv_cb.AWPROT <= req_item.prot_type;
        AXI.mdrv_cb.AWCACHE <= req_item.memory_type;
        AXI.mdrv_cb.AWREGION <= req_item.region_identifier;
        AXI.mdrv_cb.AWQOS <= req_item.quality_of_service;

        `uvm_info("MASTER.DRV.WRITE_ADDR_CH", "waiting for AWREADY assertion", UVM_HIGH)
        @(posedge AXI.ACLK);
        wait(AXI.mdrv_cb.AWREADY === `HIGH);
        `uvm_info("MASTER.DRV.WRITE_ADDR_CH", "AWREADY assertion detected", UVM_HIGH)
        `uvm_info("MASTER.DRV.WRITE_ADDR_CH", $sformatf("AW channel transfer complete for  start_addr: 0x%0h and trans_id: 0x%0h",req_item.start_addr, req_item.trans_id), UVM_MEDIUM)

        AXI.mdrv_cb.AWVALID <= `LOW;

        request_index++;

    end

endtask:write_addr_ch



//----------------------------------------------------------------------------
//task: write_data_ch
//----------------------------------------------------------------------------
task axi_master_driver::write_data_ch();

    master_seq_item req_item;
    int request_index = 0;
    int lower_byte_lane;
    int upper_byte_lane;
    bit wrapped;

    forever begin

        `uvm_info("MASTER.DRV.WRITE_DATA_CH", "requesting for transaction from sequence", UVM_HIGH)
        wait(write_request_que.size() > request_index);
        req_item = write_request_que[request_index];
        `uvm_info("MASTER.DRV.WRITE_DATA_CH", $sformatf("get the request of type: %0s", req_item.access_type.name()), UVM_HIGH)

        `uvm_info("MASTER.DRV.WRITE_DATA_CH", $sformatf("W channel transfer initiate for start_addr: 0x%0h trans_id: 0x%0h burst_type: %0s burst_length: 0x%0h burst_size: %0s", req_item.start_addr, req_item.trans_id, req_item.burst_type.name(), req_item.burst_length, req_item.burst_size.name()), UVM_MEDIUM)

        //drive valid write data
        foreach(req_item.write_data_q[transfer_num]) begin:w_data
                
            AXI.mdrv_cb.WVALID <= `HIGH;
            AXI.mdrv_cb.WLAST <= (transfer_num == req_item.burst_length) ? `HIGH : `LOW;
            AXI.mdrv_cb.WSTRB <= find_valid_byte_lane(transfer_num, cfg.data_bus_bytes, req_item.start_addr, req_item.burst_length, req_item.burst_size, req_item.burst_type, wrapped, lower_byte_lane, upper_byte_lane);

            //drive write_data bytes on only valid bus bytes using strobe value
            for(int valid_byte=lower_byte_lane; valid_byte<=upper_byte_lane; valid_byte++) begin
                AXI.mdrv_cb.WDATA[8*valid_byte+: 8] <= req_item.write_data_q[transfer_num][8*valid_byte+: 8];
            end
                
            `uvm_info("MASTER.DRV.WRITE_DATA_CH", $sformatf("waiting for WREADY assertion to complete write transfer 0x%0h of total 0x%0h", transfer_num+1, req_item.burst_length+1), UVM_HIGH)
            @(posedge AXI.ACLK);
            wait(AXI.mdrv_cb.WREADY === `HIGH);
            `uvm_info("MASTER.DRV.WRITE_DATA_CH", $sformatf("WREADY assertion detected to complete write transfer 0x%0h of total 0x%0h", transfer_num+1, req_item.burst_length+1), UVM_HIGH)

            AXI.mdrv_cb.WVALID <= `LOW;
            AXI.mdrv_cb.WLAST <= `LOW;

        end:w_data

        `uvm_info("MASTER.DRV.WRITE_DATA_CH", $sformatf("All W channel transfer complete for  start_addr: 0x%0h and trans_id: 0x%0h",req_item.start_addr, req_item.trans_id), UVM_MEDIUM)

        request_index++;

    end

endtask:write_data_ch

//----------------------------------------------------------------------------
//task: write_response_ch
//----------------------------------------------------------------------------
task axi_master_driver::write_response_ch();

    int request_index = 0;

    forever begin

        AXI.mdrv_cb.BREADY <= `HIGH;

        `uvm_info("MASTER.DRV.WRITE_RESPONSE_CH", "waiting for BVALID assertion", UVM_HIGH)
        @(posedge AXI.ACLK);
        wait(AXI.mdrv_cb.BVALID === `HIGH);
        `uvm_info("MASTER.DRV.WRITE_RESPONSE_CH", "BVALID asserion detected", UVM_HIGH)

        //find the request_index from request_que for which response is given using BID value
        request_index = find_request(AXI.mdrv_cb.BID, AXI_WRITE);

        //capture the response
        write_request_que[request_index].write_response_id = AXI.mdrv_cb.BID;
        $cast(write_request_que[request_index].write_response, AXI.mdrv_cb.BRESP);

        //put response back to sequence
        write_request_que[request_index].set_tr_state(AXI_FINISHED);
        seq_item_port.put(write_request_que[request_index]);

        AXI.mdrv_cb.BREADY <= `LOW;

    end

endtask:write_response_ch


//----------------------------------------------------------------------------
//task: read_addr_ch()
//----------------------------------------------------------------------------
task axi_master_driver::read_addr_ch();

    master_seq_item req_item;
    int request_index = 0;

    forever begin

        `uvm_info("MASTER.DRV.READ_ADDR_CH", "requesting for transaction from sequence", UVM_HIGH)
        wait(read_request_que.size() > request_index);
        req_item = read_request_que[request_index];
        `uvm_info("MASTER.DRV.READ_ADDR_CH", $sformatf("get the request of type: %0s", req_item.access_type.name()), UVM_HIGH)

        `uvm_info("MASTER.DRV.READ_ADDR_CH", $sformatf("AR channel transfer initiate with start_addr: 0x%0h trans_id: 0x%0h burst_type: %0s burst_length: 0x%0h burst_size: %0s", req_item.start_addr, req_item.trans_id, req_item.burst_type.name(), req_item.burst_length, req_item.burst_size.name()), UVM_MEDIUM)

        AXI.mdrv_cb.ARVALID <= `HIGH;    //drives the address and control information on read address channel
        AXI.mdrv_cb.ARID <= req_item.trans_id;
        AXI.mdrv_cb.ARADDR <= req_item.start_addr;
        AXI.mdrv_cb.ARBURST <= req_item.burst_type;
        AXI.mdrv_cb.ARLEN <= req_item.burst_length;
        AXI.mdrv_cb.ARSIZE <= req_item.burst_size;
        AXI.mdrv_cb.ARLOCK <= req_item.lock_type;
        AXI.mdrv_cb.ARPROT <= req_item.prot_type;
        AXI.mdrv_cb.ARCACHE <= req_item.memory_type;
        AXI.mdrv_cb.ARREGION <= req_item.region_identifier;
        AXI.mdrv_cb.ARQOS <= req_item.quality_of_service;

        `uvm_info("MASTER.DRV.READ_ADDR_CH", "waiting for ARREADY assertion", UVM_HIGH)
        @(posedge AXI.ACLK);
        wait(AXI.mdrv_cb.ARREADY);
        `uvm_info("MASTER.DRV.READ_ADDR_CH", "ARREADY assertion detected", UVM_HIGH)
        `uvm_info("MASTER.DRV.READ_ADDR_CH", $sformatf("AR channel transfer complete for  start_addr: 0x%0h and trans_id: 0x%0h",req_item.start_addr, req_item.trans_id), UVM_MEDIUM)

        AXI.mdrv_cb.ARVALID <= `LOW;    //de-assert the ARVALID on successful transfer

        request_index++;
    
    end

endtask:read_addr_ch


//----------------------------------------------------------------------------
//task : read_data_ch()
//method read_data_ch perform the axi read data (R) channel operation 
//to get the actual data and response for the read transfer from the slave
//----------------------------------------------------------------------------
task axi_master_driver::read_data_ch();

    bit [3: 0] read_id_q[$];
    bit [(`DATA_BUS_BYTES*8)-1: 0] read_data_q[$];
    axi_resp_e read_response_q[$];
    int request_index = 0;
    int lower_byte_lane;
    int upper_byte_lane;
    bit wrapped;

    forever begin

        AXI.mdrv_cb.RREADY <= `HIGH;

        `uvm_info("MASTER.DRV.READ_DATA_CH", "waiting for RVALID assertion", UVM_HIGH)
        @(posedge AXI.ACLK);
        wait(AXI.mdrv_cb.RVALID === `HIGH);
        `uvm_info("MASTER.DRV.READ_DATA_CH", "RREADY assertion detected", UVM_HIGH)
        
        //capture the read response
        read_id_q.push_back(AXI.mdrv_cb.RID);
        read_response_q.push_back(AXI.mdrv_cb.RRESP);
        read_data_q.push_back(AXI.mdrv_cb.RDATA);

        //if response is last, segregate the response to give response back to
        //sequence
        if(AXI.mdrv_cb.RLAST === `HIGH) begin
            //find request from request_que for which response to be given to
            //sequence
            request_index = find_request(AXI.mdrv_cb.RID, AXI_READ);

            for(int transfer_num=0; transfer_num<=read_request_que[request_index].burst_length; transfer_num++) begin
                
                //find valid byte lane for nth read transfer
                void'(find_valid_byte_lane(transfer_num, cfg.data_bus_bytes, read_request_que[request_index].start_addr, read_request_que[request_index].burst_length, read_request_que[request_index].burst_size, read_request_que[request_index].burst_type, wrapped, lower_byte_lane, upper_byte_lane));
                foreach(read_id_q[index]) begin

                    if(read_id_q[index] == read_request_que[request_index].trans_id) begin
                        read_request_que[request_index].read_id_q.push_back(read_id_q[index]);
                        read_request_que[request_index].read_response_q.push_back(read_response_q[index]);
                        read_request_que[request_index].read_data_q.push_back(read_data_q[index]);
                        read_id_q.delete(index);
                        read_response_q.delete(index);
                        read_data_q.delete(index);
                        break;
                    end
                
                end
            
            end
            read_request_que[request_index].set_tr_state(AXI_FINISHED);
            seq_item_port.put(read_request_que[request_index]);
            `uvm_info("MASTER.DRV.READ_DATA_CH", $sformatf("All R channel transfer complete for start_addr: 0x%0h and trans_id: 0x%0h", read_request_que[request_index].start_addr, read_request_que[request_index].trans_id), UVM_MEDIUM)
        end

        AXI.mdrv_cb.RREADY <= `LOW;

    end

endtask:read_data_ch


//----------------------------------------------------------------------------
//Method: find_request
//find request_index of particular request from request_que for which response
//has been given using RESPONSE ID value(BID or RID)
//----------------------------------------------------------------------------
function int axi_master_driver::find_request(axi_mid_t response_id, access_type_e access_type);

    case(access_type)
        
        AXI_WRITE: begin
            foreach(write_request_que[index]) begin
                if(write_request_que[index].trans_id == response_id && write_request_que[index].get_tr_state != AXI_FINISHED) begin
                    return index;
                end
            end
        end

        AXI_READ: begin
            foreach(read_request_que[index]) begin
                if(read_request_que[index].trans_id == response_id && read_request_que[index].get_tr_state != AXI_FINISHED) begin
                    return index;
                end
            end
        end

    endcase

    `uvm_error("MASTER.DRV.FIND_REQUEST", $sformatf("unserved request having trans_id: 0x%0h not found in request_queues", response_id))

endfunction:find_request

//----------------------------------------------------------------------------
//Method: find_valid_byte_lane
//finds valid byte lane usign write_strobe value
//----------------------------------------------------------------------------
function axi_wstrb_t axi_master_driver::find_valid_byte_lane(int nth_transfer, data_bus_bytes, axi_addr_t start_addr, axi_length_t length, axi_size_e burst_size, axi_burst_e burst_type, ref bit wrapped, output int lower_byte_lane, upper_byte_lane);
    
    bit [8: 0] burst_length = length + 1'b1;
    bit [7: 0] number_bytes = 2**burst_size;
    axi_addr_t aligned_addr = (((start_addr/number_bytes))*(number_bytes));
    axi_addr_t lower_wrap_boundary = ((start_addr/(number_bytes*burst_length))*(number_bytes*burst_length));
    axi_addr_t upper_wrap_boundary = (lower_wrap_boundary + (number_bytes*burst_length));
    axi_addr_t address_n;
   
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
            uvm_report_error("BURST_TYPE_ERROR", "unsupported burst type encounterd while calculating next address");
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
    
    find_valid_byte_lane = 0;
    for(int lane=0; lane<data_bus_bytes; lane++ ) begin
        if(lane>=lower_byte_lane && lane<=upper_byte_lane) begin
            find_valid_byte_lane[lane] = 1'b1;
        end
        else begin
            find_valid_byte_lane[lane] = 1'b0;
        end
    end

endfunction:find_valid_byte_lane

//----------------------------------------------------------------------------
//Method: set_master_port_id
//----------------------------------------------------------------------------
function void axi_master_driver::set_master_port_id(bit [7: 0] port_id);

    this.m_port_id = port_id;

endfunction:set_master_port_id


//----------------------------------------------------------------------------
//Method: get_master_port_id
//----------------------------------------------------------------------------
function bit [7: 0] axi_master_driver::get_master_port_id();

    return this.m_port_id;

endfunction:get_master_port_id
`endif
