//------------------------------------------------------------------------------
//Class: axi_slave_monitor
//Samples the interface activity and capture them in tranaction that will be
//sent out via analysis port to rest of the testbench.
//------------------------------------------------------------------------------
class axi_slave_monitor extends uvm_monitor;

    //UVM factory registration
    `uvm_component_utils(axi_slave_monitor)

    //------------------------------------------------------------------------------
    //Data Members:
    //------------------------------------------------------------------------------
    //port_id
    protected bit [7: 0] m_port_id;

    //virtual interface handle
    virtual axi_slave_if.smon_mp AXI;

    //slave port_id
    protected bit [7: 0] port_id;

    //slave sequemce_item handle
    slave_seq_item item;

    //configuration object handle
    slave_agent_config cfg;

    //analysis port to publish transaction to rest of the testbench
    uvm_analysis_port #(slave_seq_item) ap;

    //analysis port that to connected with analysis_imp in
    //slave sequencer
    uvm_analysis_port #(slave_seq_item) req_port;

    //Class Constructor Method:
    extern function new(string name, uvm_component parent);

    //UVM standard Phases Method:
    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);

    //method for each AXI channel
    extern protected virtual task write_addr_ch();
    extern protected virtual task write_data_ch();
    extern protected virtual task write_response_ch();
    extern protected virtual task read_addr_ch();
    extern protected virtual task read_data_ch();

    //monitor the reset siganl
    extern function void reset_sample(output slave_seq_item item);

    //Convenience method for checks
    extern function void burst_size_check(slave_seq_item check_tr);

    extern function void set_slave_port_id(bit [7: 0] port_id);
    extern function bit [7: 0] get_slave_port_id();

endclass:axi_slave_monitor


//------------------------------------------------------------------------------------
//Implementation
//------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------
//Class Constructor Method: new
//------------------------------------------------------------------------------------
function axi_slave_monitor::new(string name, uvm_component parent);

    super.new(name, parent);

endfunction:new



//------------------------------------------------------------------------------------
//Method: build_phase
//call to super.build_phase and constuct the analysis port.
//------------------------------------------------------------------------------------
function void axi_slave_monitor::build_phase(uvm_phase phase);
  
    super.build_phase(phase);

    //create analysis ports
    ap = new("ap", this);
    req_port = new("req_port", this);

endfunction:build_phase




//------------------------------------------------------------------------------------
//Method: run_phase
//Reset monitoring and observes interface activity and capture them in sequence_item.
//------------------------------------------------------------------------------------
task axi_slave_monitor::run_phase(uvm_phase phase);

    if(!uvm_config_db#(slave_agent_config)::get(this, "", "slave_agent_config", cfg)) begin
        `config_retrival_fatal(cfg)
    end

    if(AXI == null) begin
        `vif_null_fatal(AXI);
    end

    forever begin

        fork

            begin:rst_detect_process

                wait(AXI.ARESETn === `LOW);

                do begin
                    `uvm_info("RESET", {"\nreset assertion detected by component: ", get_full_name(),"\n"}, UVM_LOW)
                    disable mon;
                    reset_sample(item);
                    req_port.write(item);
                    ap.write(item);
                    @(posedge AXI.ACLK);
                end
                while(AXI.ARESETn !== `HIGH);
                `uvm_info("RESET", {"\nreset de-assertion detected by component: ", get_full_name(),"\n"}, UVM_LOW)

            end:rst_detect_process

            begin:mon

                wait(AXI.ARESETn === `HIGH);

                fork
                    write_addr_ch();
                    write_data_ch();
                    write_response_ch();
                    read_addr_ch();
                    read_data_ch();
                join

                disable rst_detect_process;

            end:mon

        join

    end

endtask:run_phase



//------------------------------------------------------------------------------------
//Method: write_addr_ch()
//------------------------------------------------------------------------------------
task axi_slave_monitor::write_addr_ch();

    slave_seq_item item;

    forever begin

        `uvm_info("SLAVE.MON.WRITE_ADDR_CH", "waiting for AWVALID assertion", UVM_HIGH);
        wait(AXI.smon_cb.AWVALID === `HIGH);
        `uvm_info("SLAVE.MON.WRITE_ADDR_CH", "AWVALID assertion detected", UVM_HIGH);
        item = slave_seq_item::type_id::create("item");
        item.access_type = AXI_WRITE;

        item.addr_valid = AXI.smon_cb.AWVALID;
        item.addr_ready = AXI.smon_cb.AWREADY;
        item.trans_id = AXI.smon_cb.AWID;
        item.start_addr = AXI.smon_cb.AWADDR;
        item.burst_length = AXI.smon_cb.AWLEN;
        item.burst_type = axi_burst_e'(AXI.smon_cb.AWBURST);
        item.burst_size = axi_size_e'(AXI.smon_cb.AWSIZE);
        item.lock_type = axi_lock_type_e'(AXI.smon_cb.AWLOCK);
        item.prot_type = axi_prot_type_e'(AXI.smon_cb.AWPROT);
        item.memory_type = axi_memory_type_e'(AXI.smon_cb.AWCACHE);
        item.region_identifier = AXI.smon_cb.AWREGION;
        item.quality_of_service = AXI.smon_cb.AWQOS;

        req_port.write(item);
        `uvm_info("SLAVE.MON.WRITE_ADDR_CH", "AW info published via req_port", UVM_HIGH);

        `uvm_info("SLAVE.MON.WRITE_ADDR_CH", "waiting for AWREADY assertion", UVM_HIGH);
        wait(AXI.smon_cb.AWREADY === `HIGH);
        `uvm_info("SLAVE.MON.WRITE_ADDR_CH", "AWREADY assertion detected", UVM_HIGH);
        item.addr_ready = AXI.smon_cb.AWREADY;

        ap.write(item);
        `uvm_info("SLAVE.MON.WRITE_ADDR_CH", "AW channel transfer complete and published via ap port for analysis", UVM_HIGH);
        if(cfg.enable_checks) begin
            burst_size_check(item);
        end
        @(posedge AXI.ACLK);

    end

endtask:write_addr_ch



//------------------------------------------------------------------------------------
//Method: write_data_ch
//------------------------------------------------------------------------------------
task axi_slave_monitor::write_data_ch();

    slave_seq_item item;

    forever begin

        `uvm_info("SLAVE.MON.WRITE_DATA_CH", "waiting for WVALID assertion", UVM_HIGH);
        wait(AXI.smon_cb.WVALID === `HIGH);
        `uvm_info("SLAVE.MON.WRITE_DATA_CH", "WVALID assertion detected", UVM_HIGH);
        item = slave_seq_item::type_id::create("item");
        item.access_type = AXI_WRITE;

        item.write_valid = AXI.smon_cb.WVALID;
        item.write_ready = AXI.smon_cb.WREADY;
        item.write_data = AXI.smon_cb.WDATA;
        item.write_last = AXI.smon_cb.WLAST;
        item.write_strobe = AXI.smon_cb.WSTRB;

        req_port.write(item);
        `uvm_info("SLAVE.MON.WRITE_DATA_CH", "W info published via req_port", UVM_HIGH);

        `uvm_info("SLAVE.MON.WRITE_DATA_CH", "waiting WREADY assertion", UVM_HIGH);
        wait(AXI.smon_cb.WREADY === `HIGH);
        `uvm_info("SLAVE.MON.WRITE_DATA_CH", "WREADY assertion detected", UVM_HIGH);
        item.write_ready = AXI.smon_cb.WREADY;

        ap.write(item);
        `uvm_info("SLAVE.MON.WRITE_DATA_CH", "W channel transfer complete and published via ap port for analysis", UVM_HIGH);
        @(posedge AXI.ACLK);

    
    end

endtask:write_data_ch



//------------------------------------------------------------------------------------
//Method: write_response_ch()
//------------------------------------------------------------------------------------
task axi_slave_monitor::write_response_ch();

    slave_seq_item item;
    
    forever begin

        `uvm_info("SLAVE.MON.WRITE_RESPONSE_CH", "waiting for BVALID assertion", UVM_HIGH);
        wait(AXI.smon_cb.BVALID === `HIGH);
        `uvm_info("SLAVE.MON.WRITE_RESPONSE_CH", "BVALID assertion detected", UVM_HIGH);

        item = slave_seq_item::type_id::create("item");
        item.access_type = AXI_WRITE;

        item.write_response_valid = AXI.smon_cb.BVALID;
        item.write_response_id = AXI.smon_cb.BID;
        item.write_response = axi_resp_e'(AXI.smon_cb.BRESP);

        `uvm_info("SLAVE.MON.WRITE_RESPONSE_CH", "waiting for BREADY assertion", UVM_HIGH);
        wait(AXI.smon_cb.BREADY === `HIGH);
        `uvm_info("SLAVE.MON.WRITE_RESPONSE_CH", "BREADY assertion detected", UVM_HIGH);
        item.write_response_ready = AXI.smon_cb.BREADY;

        ap.write(item);
        `uvm_info("SLAVE.MON.WRITE_RESPONSE_CH", "B channel transfer complete and published via ap port for analysis", UVM_HIGH);
        @(posedge AXI.ACLK);

    end

endtask:write_response_ch



//------------------------------------------------------------------------------------
//Method: read_addr_ch()
//------------------------------------------------------------------------------------
task axi_slave_monitor::read_addr_ch();

    slave_seq_item item;

    forever begin

        `uvm_info("SLAVE.MON.READ_ADDR_CH", "waiting for ARVALID assertion", UVM_HIGH);
        wait(AXI.smon_cb.ARVALID === `HIGH);
        `uvm_info("SLAVE.MON.READ_ADDR_CH", "ARVALID assertion detected", UVM_HIGH);

        item = slave_seq_item::type_id::create("item");
        item.access_type = AXI_READ;

        item.addr_valid = AXI.smon_cb.ARVALID;
        item.addr_ready = AXI.smon_cb.ARREADY;
        item.trans_id = AXI.smon_cb.ARID;
        item.start_addr = AXI.smon_cb.ARADDR;
        item.burst_length = AXI.smon_cb.ARLEN;
        item.burst_type = axi_burst_e'(AXI.smon_cb.ARBURST);
        item.burst_size = axi_size_e'(AXI.smon_cb.ARSIZE);
        item.lock_type = axi_lock_type_e'(AXI.smon_cb.ARLOCK);
        item.prot_type = axi_prot_type_e'(AXI.smon_cb.ARPROT);
        item.memory_type = axi_memory_type_e'(AXI.smon_cb.ARCACHE);
        item.region_identifier = AXI.smon_cb.ARREGION;
        item.quality_of_service = AXI.smon_cb.ARQOS;


        req_port.write(item);
        `uvm_info("SLAVE.MON.READ_ADDR_CH", "AR info published via req_port", UVM_HIGH);

        `uvm_info("SLAVE.MON.READ_ADDR_CH", "waiting for ARREADY assertion", UVM_HIGH);
        wait(AXI.smon_cb.ARREADY === `HIGH);
        `uvm_info("SLAVE.MON.READ_ADDR_CH", "ARREADY assertion detected", UVM_HIGH);
        item.addr_ready = AXI.smon_cb.ARREADY;

        ap.write(item);
        `uvm_info("SLAVE.MON.READ_ADDR_CH", "AR channel transfer complete and published via ap port for analysis", UVM_HIGH);
        if(cfg.enable_checks) begin
            burst_size_check(item);
        end
        @(posedge AXI.ACLK);

    end

endtask:read_addr_ch



//------------------------------------------------------------------------------------
//Method: read_data_ch
//------------------------------------------------------------------------------------
task axi_slave_monitor::read_data_ch();

    slave_seq_item item;

    forever begin

        `uvm_info("SLAVE.MON.READ_DATA_CH", "waiting for RVALID assertion", UVM_HIGH);
        wait(AXI.smon_cb.RVALID === `HIGH);
        `uvm_info("SLAVE.MON.READ_DATA_CH", "RVALID assertion detected", UVM_HIGH);

        item = slave_seq_item::type_id::create("item");
        item.access_type = AXI_READ;

        item.read_valid = AXI.smon_cb.RVALID;
        item.read_data = AXI.smon_cb.RDATA;
        item.read_id[0] = AXI.smon_cb.RID;
        item.read_response[0] = axi_resp_e'(AXI.smon_cb.RRESP);
        item.read_last = AXI.smon_cb.RLAST;

        `uvm_info("SLAVE.MON.READ_DATA_CH", "waiting for RREADY assertion", UVM_HIGH);
        wait(AXI.smon_cb.RREADY === `HIGH);
        `uvm_info("SLAVE.MON.READ_DATA_CH", "RREADY assertion detected", UVM_HIGH);
        item.read_ready = AXI.smon_cb.RREADY;

        ap.write(item);
        `uvm_info("SLAVE.MON.READ_DATA_CH", "R channel transfer complete and published via ap port for analysis", UVM_HIGH);
        @(posedge AXI.ACLK);

    end

endtask:read_data_ch



//------------------------------------------------------------------------------------
//Method: reset_sample
//------------------------------------------------------------------------------------
function void axi_slave_monitor::reset_sample(output slave_seq_item item);

    item = slave_seq_item::type_id::create("item");

    item.reset_detected = `HIGH;

endfunction:reset_sample


//---------------------------------------------------------------------------
//Method: burst_size_check
//check validness of burst size
//---------------------------------------------------------------------------
function void axi_slave_monitor::burst_size_check(slave_seq_item check_tr);

    //transaction burst size check
    if(check_tr.addr_valid) begin
        if((2**check_tr.burst_size) > cfg.data_bus_bytes)
            `uvm_error("SLAVE.CHECKS", "size of any transfer must not exceed the data bus size of agent")
    end

endfunction:burst_size_check


//----------------------------------------------------------------------------
//Method: set_slave_port_id
//----------------------------------------------------------------------------
function void axi_slave_monitor::set_slave_port_id(bit [7: 0] port_id);

    this.m_port_id = port_id;

endfunction:set_slave_port_id


//----------------------------------------------------------------------------
//Method: get_slave_port_id
//----------------------------------------------------------------------------
function bit [7: 0] axi_slave_monitor::get_slave_port_id();

    return this.m_port_id;

endfunction:get_slave_port_id
