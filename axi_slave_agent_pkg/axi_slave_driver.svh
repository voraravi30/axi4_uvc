//--------------------------------------------------------------------
//Class: axi_slave_driver
//responde to the request initiated from master
//--------------------------------------------------------------------
class axi_slave_driver extends uvm_driver #(slave_seq_item);

    //UVM factory registration Method:
    `uvm_component_utils(axi_slave_driver)

    //------------------------------------------------------------------------------
    //Data Members:
    //------------------------------------------------------------------------------
    //slave port_id
    protected bit [7: 0] m_port_id;

    //storage component
    axi_storage_component storage;

    //virtual interface handle
    virtual axi_slave_if.sdrv_mp AXI;

    //configuration object handle
    slave_agent_config cfg;

    //response_que
    slave_seq_item response_que[$];

    //ensure anyone address channel thread have access to get_request at
    //a time
    semaphore get_response_lock;

    //Class Constructor method:
    extern function new(string name, uvm_component parent);

    //UVM Standard phases method:
    extern task run_phase(uvm_phase phase);

    //method for each AXI channel:
    extern protected virtual task write_addr_ch();
    extern protected virtual task write_data_ch();
    extern protected virtual task write_response_ch();
    extern protected virtual task read_addr_ch();
    extern protected virtual task read_data_ch();

    //get the response from sequence
    extern protected virtual task get_response_item(int response_index, output slave_seq_item rsp_item);
    extern protected virtual task put_response_on_reset();

    extern function void set_slave_port_id(bit [7: 0] port_id);
    extern function bit [7: 0] get_slave_port_id();

endclass:axi_slave_driver




//----------------------------------------------------------------------------
//Implementation:
//----------------------------------------------------------------------------



//----------------------------------------------------------------------------
//function : Class constructor method
//Create the master driver component and return the handle
//----------------------------------------------------------------------------
function axi_slave_driver::new(string name, uvm_component parent);
    
    super.new(name, parent);

endfunction:new



//----------------------------------------------------------------------------
//Method: run_phase
//Continuously responds to stimuls initiated by the master and monitor the reset
//----------------------------------------------------------------------------
task axi_slave_driver::run_phase(uvm_phase phase);

    if(!uvm_config_db#(slave_agent_config)::get(this,"","slave_agent_config",cfg)) begin
        `config_retrival_fatal(cfg)
    end

    if(AXI == null) begin
        `vif_null_fatal(AXI)
    end

    forever begin:forever_loop

        //create semaphore with one key
        get_response_lock = new(1);

        fork

            begin:reset_detect

                wait(AXI.ARESETn === `LOW);
                put_response_on_reset();

                do begin
                    `uvm_info("RESET", {"\nreset assertion detected by component: ", get_full_name(),"\n"}, UVM_LOW)
                    disable drv;
                    response_que.delete();
                    AXI.sdrv_cb.BVALID <= `LOW;
                    AXI.sdrv_cb.RVALID <= `LOW;
                    AXI.sdrv_cb.AWREADY <= `LOW;
                    AXI.sdrv_cb.WREADY <= `LOW;
                    AXI.sdrv_cb.ARREADY <= `LOW;
                    @(posedge AXI.ACLK);
                end
                while(AXI.ARESETn !== `HIGH);
                `uvm_info("RESET", {"\nreset de-assertion detected by component: ", get_full_name(),"\n"}, UVM_LOW)

            end:reset_detect

            begin:drv

                wait(AXI.ARESETn === `HIGH);

                fork
                    write_addr_ch();
                    write_data_ch();
                    write_response_ch();
                    read_addr_ch();
                    read_data_ch();
                join
                
                disable reset_detect;

            end:drv

        join
    
    end:forever_loop

endtask:run_phase


//----------------------------------------------------------------------------
//Method: put_response_on_reset
//Method will route back the response from driver to sequence for
//sequence_item which are stopped/unserved due to reset assertion
//----------------------------------------------------------------------------
task axi_slave_driver::put_response_on_reset();

    if(response_que.size() != 0) begin

        `uvm_info("SLAVE.DRV.PUT_RESPONSE_ON_RESET", "start of put_response_on_reset method", UVM_HIGH)
        
        //put reponse for the remaining request which are stopped due to reset
        foreach(response_que[response_index]) begin
            if(response_que[response_index].get_tr_state() != AXI_FINISHED) begin
                response_que[response_index].set_tr_state(AXI_STOPPED);
                `uvm_info("MASTER.DRV.PUT_RESPONSE_ON_RESET", $sformatf("puting reset response for m_sequence_id: 0x%0h and response_index: 0x%0h", response_que[response_index].get_sequence_id(), response_index), UVM_HIGH)
                seq_item_port.put(response_que[response_index]);
            end
        end
        //flush the response_que
        response_que.delete();

        `uvm_info("SLAVE.DRV.PUT_RESPONSE_ON_RESET", "end of put_response_on_reset method", UVM_HIGH)
    
    end

endtask:put_response_on_reset


//----------------------------------------------------------------------------
//Method: get_response_item
//get the response_item from the sequence to drive
//----------------------------------------------------------------------------
task axi_slave_driver::get_response_item(int response_index, output slave_seq_item rsp_item);

    if(response_que[response_index] == null) begin
            get_response_lock.get(1);
            if(response_que[response_index] == null) begin
                seq_item_port.get(rsp_item);
                if(!$cast(response_que[response_index], rsp_item.clone())) begin
                    `object_casting_fatal(get_response_item);
                end
                response_que[response_index].set_id_info(rsp_item);
            end
            get_response_lock.put(1);
        end
        if(!$cast(rsp_item, response_que[response_index].clone())) begin
            `object_casting_fatal(get_response_item);
        end
        rsp_item.set_id_info(response_que[response_index]);

endtask:get_response_item


//----------------------------------------------------------------------------
//Method: write_addr_ch
//----------------------------------------------------------------------------
task axi_slave_driver::write_addr_ch();

    slave_seq_item rsp_item;
    int response_index = 0;

    forever begin

        get_response_item(response_index, rsp_item);

        if(rsp_item.addr_valid && rsp_item.access_type == AXI_WRITE) begin

            //delay the respond driving
            repeat(rsp_item.delay) @(posedge AXI.ACLK); 

            `uvm_info("SLAVE.DRV.WRITE_ADDR_CH", "asserting --> AWREADY", UVM_HIGH)
            
            AXI.sdrv_cb.AWREADY <= `HIGH;

            @(posedge AXI.ACLK);

            AXI.sdrv_cb.AWREADY <= `LOW;

            response_que[response_index].set_tr_state(AXI_FINISHED);
            seq_item_port.put(response_que[response_index]);
            `uvm_info("SLAVE.DRV.WRITE_ADDR_CH", "AW channel transfer complete", UVM_HIGH)

        end
        response_index++;

    end

endtask:write_addr_ch


//----------------------------------------------------------------------------
//Method: write_data_ch
//----------------------------------------------------------------------------
task axi_slave_driver::write_data_ch();

    slave_seq_item rsp_item;
    int response_index = 0;

    forever begin

        get_response_item(response_index, rsp_item);

        if(rsp_item.write_valid) begin

            //delay the response driving
            repeat(rsp_item.delay) @(posedge AXI.ACLK); 

            `uvm_info("SLAVE.DRV.WRITE_DATA_CH",  "asserting --> WREADY", UVM_HIGH)

            AXI.sdrv_cb.WREADY <= `HIGH;

            @(posedge AXI.ACLK);

            AXI.sdrv_cb.WREADY <= `LOW;

            response_que[response_index].set_tr_state(AXI_FINISHED);
            seq_item_port.put(response_que[response_index]);
            `uvm_info("SLAVE.DRV.WRITE_DATA_CH", "W channel transfer complete", UVM_HIGH)

        end
        response_index++;

    end
    
endtask:write_data_ch


//----------------------------------------------------------------------------
//Method: write_response_ch
//----------------------------------------------------------------------------
task axi_slave_driver::write_response_ch();
    
    slave_seq_item rsp_item;
    int response_index = 0;
    
    forever begin

        get_response_item(response_index, rsp_item);

        if(rsp_item.write_response_valid) begin

            //delay the response driving
            repeat(rsp_item.delay) @(posedge AXI.ACLK);

            `uvm_info("SLAVE.DRV.WRITE_RESPONSE_CH", "asserting --> BVALID", UVM_HIGH)
            
            AXI.sdrv_cb.BVALID <= `HIGH;
            AXI.sdrv_cb.BRESP <= rsp_item.write_response;
            AXI.sdrv_cb.BID <= rsp_item.write_response_id;

            @(posedge AXI.ACLK);
            wait(AXI.sdrv_cb.BREADY === `HIGH);

            AXI.sdrv_cb.BVALID <= `LOW;

            response_que[response_index].set_tr_state(AXI_FINISHED);
            seq_item_port.put(response_que[response_index]);
            `uvm_info("SLAVE.DRV.WRITE_RESPONSE_CH", "B channel transfer complete", UVM_HIGH)
        end
        response_index++;

    end

endtask:write_response_ch


//----------------------------------------------------------------------------
//Method: read_addr_ch
//----------------------------------------------------------------------------
task axi_slave_driver::read_addr_ch();

    slave_seq_item rsp_item;
    int response_index = 0;

    forever begin

        get_response_item(response_index, rsp_item);

        if(rsp_item.addr_valid && rsp_item.access_type == AXI_READ) begin

            //delay the response driving
            repeat(rsp_item.delay) @(posedge AXI.ACLK);

            `uvm_info("SLAVE.DRV.READ_ADDR_CH", "asserting --> ARREADY", UVM_HIGH)

            AXI.sdrv_cb.ARREADY <= `HIGH;

            @(posedge AXI.ACLK);
            
            AXI.sdrv_cb.ARREADY <= `LOW;

            response_que[response_index].set_tr_state(AXI_FINISHED);
            seq_item_port.put(response_que[response_index]);
            `uvm_info("SLAVE.DRV.READ_ADDR_CH", "AR channel transfer complete", UVM_HIGH)

        end
        response_index++;
    
    end

endtask:read_addr_ch


//----------------------------------------------------------------------------
//Method: read_data_ch
//----------------------------------------------------------------------------
task axi_slave_driver::read_data_ch();

    slave_seq_item rsp_item;
    int response_index = 0;

    forever begin

        get_response_item(response_index, rsp_item);

        if(rsp_item.read_valid) begin

            //delay the response driving
            repeat(rsp_item.delay) @(posedge AXI.ACLK);

            `uvm_info("SLAVE.DRV.READ_DATA_CH", "asserting --> RVALID", UVM_HIGH)

            AXI.sdrv_cb.RVALID <= `HIGH;
            AXI.sdrv_cb.RRESP <= rsp_item.read_response;
            if(rsp_item.read_response == OKAY_RESP) begin
                AXI.sdrv_cb.RDATA <= rsp_item.read_data;
            end
            AXI.sdrv_cb.RLAST <= rsp_item.read_last; 
            $cast(AXI.sdrv_cb.RID, rsp_item.read_id);

            @(posedge AXI.ACLK);
            wait(AXI.sdrv_cb.RREADY === `HIGH);

            AXI.sdrv_cb.RVALID <= 1'b0;
            AXI.sdrv_cb.RLAST  <= 1'b0;
            response_que[response_index].set_tr_state(AXI_FINISHED);
            seq_item_port.put(response_que[response_index]);
            `uvm_info("SLAVE.DRV.READ_DATA_CH", "R channel transfer complete", UVM_HIGH)

       end
       response_index++;
   
   end

endtask:read_data_ch


//----------------------------------------------------------------------------
//Method: set_slave_port_id
//----------------------------------------------------------------------------
function void axi_slave_driver::set_slave_port_id(bit [7: 0] port_id);

    this.m_port_id = port_id;

endfunction:set_slave_port_id


//----------------------------------------------------------------------------
//Method: get_slave_port_id
//----------------------------------------------------------------------------
function bit [7: 0] axi_slave_driver::get_slave_port_id();

    return this.m_port_id;

endfunction:get_slave_port_id
