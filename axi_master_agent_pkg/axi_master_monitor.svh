//------------------------------------------------------------------------------
//Class: axi_master_monitor
//Samples the interface activity and capture them in tranaction that will be
//sent out via analysis port to rest of the testbench.
//------------------------------------------------------------------------------
class axi_master_monitor extends uvm_monitor;
    
    //UVM factory registration
    `uvm_component_utils(axi_master_monitor)

    //------------------------------------------------------------------------------
    //Data Members:
    //------------------------------------------------------------------------------
    //master port id
    protected bit [7: 0] m_port_id;

    //virtual interface handle
    virtual axi_master_if.mmon_mp AXI;

    //master request handle
    master_seq_item req_item;

    //configuration object handle
    master_agent_config cfg;

    //analysis port handle
    uvm_analysis_port #(master_seq_item) ap;

    //Class Constructor Method:
    extern function new(string name, uvm_component parent);

    //UVM standard Phases Method:
    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
    extern function void end_of_elaboration_phase(uvm_phase phase);

    //Method for each AXI channel
    extern protected virtual task write_addr_ch();
    extern protected virtual task write_data_ch();
    extern protected virtual task write_response_ch();
    extern protected virtual task read_addr_ch();
    extern protected virtual task read_data_ch();

    //monitor the reset siganl
    extern function void reset_sample();

    extern function void set_master_port_id(bit [7: 0] port_id);
    extern function bit [7: 0] get_master_port_id();

endclass:axi_master_monitor

//------------------------------------------------------------------------------------
//Implementation
//------------------------------------------------------------------------------------



//------------------------------------------------------------------------------------
//Class Constructor Method: new
//------------------------------------------------------------------------------------
function axi_master_monitor::new(string name, uvm_component parent);

    super.new(name,parent);

endfunction:new



//------------------------------------------------------------------------------------
//Method: build_phase
//call to super.build_phase and constuct the analysis port.
//------------------------------------------------------------------------------------
function void axi_master_monitor::build_phase(uvm_phase phase);
  
    super.build_phase(phase);

    //create analysis port ap
    ap = new("ap",this);

    //get the configuration 
    if(!uvm_config_db#(master_agent_config)::get(this, "", "master_agent_config", cfg)) begin
        `config_retrival_fatal(cfg);
    end

endfunction:build_phase


//----------------------------------------------------------------------------
//Method: end_of_elaboration_phase
//----------------------------------------------------------------------------
function void axi_master_monitor::end_of_elaboration_phase(uvm_phase phase);

    super.end_of_elaboration_phase(phase);
    set_master_port_id(cfg.port_id);

endfunction:end_of_elaboration_phase


//------------------------------------------------------------------------------------
//Method: run_phase
//Reset monitoring and observes interface activity and capture them in sequence_item.
//------------------------------------------------------------------------------------
task axi_master_monitor::run_phase(uvm_phase phase);

    if(AXI == null) begin
        `vif_null_fatal(AXI)
    end
    
    forever begin

        fork

            begin:reset_detect_process

                wait(AXI.ARESETn === `LOW);
                do begin
                    `uvm_info("RESET", {"\nreset assertion detected by component: ", get_full_name(),"\n"}, UVM_LOW)
                    disable mon_process;
                    reset_sample();
                    ap.write(req_item);
                    @(posedge AXI.ACLK);
                end
                while(AXI.ARESETn !== `HIGH);
                `uvm_info("RESET", {"\nreset de-assertion detected by component: ", get_full_name(),"\n"}, UVM_LOW)
            
            end:reset_detect_process
           
            begin:mon_process

                wait(AXI.ARESETn === `HIGH);

                fork
                    write_addr_ch();
                    write_data_ch();
                    write_response_ch();
                    read_addr_ch();
                    read_data_ch();
                join

                disable reset_detect_process;

            end:mon_process

        join
    end

endtask:run_phase



//------------------------------------------------------------------------------------
//Method: write_addr_ch
//------------------------------------------------------------------------------------
task axi_master_monitor::write_addr_ch();

    master_seq_item req_item;
    
    forever begin
        
        req_item = master_seq_item::type_id::create("req_item");
        req_item.set_master_port_id(get_master_port_id());

        `uvm_info("MASTER.MON.WRITE_ADDR_CH", "waiting for AWVALID assertion", UVM_HIGH);
        wait(AXI.mmon_cb.AWVALID === `HIGH);
        `uvm_info("MASTER.MON.WRITE_ADDR_CH", "AWVALID assertion detected", UVM_HIGH);

        req_item.access_type = AXI_WRITE;

        req_item.addr_valid = AXI.mmon_cb.AWVALID;
        req_item.start_addr = AXI.mmon_cb.AWADDR;
        req_item.trans_id = AXI.mmon_cb.AWID;
        req_item.burst_length = AXI.mmon_cb.AWLEN;
        req_item.burst_type = axi_burst_e'(AXI.mmon_cb.AWBURST);
        req_item.burst_size = axi_size_e'(AXI.mmon_cb.AWSIZE);
        req_item.lock_type = axi_lock_type_e'(AXI.mmon_cb.AWLOCK);
        req_item.prot_type =  axi_prot_type_e'(AXI.mmon_cb.AWPROT);
        req_item.memory_type =  axi_memory_type_e'(AXI.mmon_cb.AWCACHE);
        req_item.region_identifier =  AXI.mmon_cb.AWREGION;
        req_item.quality_of_service = AXI.mmon_cb.AWQOS;
        `uvm_info("MASTER.MON.WRITE_ADDR_CH", req_item.convert2string(), UVM_HIGH)

        `uvm_info("MASTER.MON.WRITE_ADDR_CH", "waiting for AWREADY assertion", UVM_HIGH);
        wait(AXI.mmon_cb.AWREADY === `HIGH);
        `uvm_info("MASTER.MON.WRITE_ADDR_CH", "AWREADY assertion detected", UVM_HIGH);
        req_item.addr_ready = AXI.mmon_cb.AWREADY;
        ap.write(req_item);

        `uvm_info("MASTER.MON.WRITE_ADDR_CH", "AW channel transfer complete and published via ap port for analysis", UVM_HIGH);
        @(posedge AXI.ACLK);

    end

endtask:write_addr_ch



//------------------------------------------------------------------------------------
//Method: write_data_ch
//------------------------------------------------------------------------------------
task axi_master_monitor::write_data_ch();

    master_seq_item req_item;

    forever begin
        
        req_item = master_seq_item::type_id::create("req_item");
        req_item.set_master_port_id(get_master_port_id());

        `uvm_info("MASTER.MON.WRITE_DATA_CH", "waiting for WVALID assertion", UVM_HIGH);
        wait(AXI.mmon_cb.WVALID === `HIGH);
        `uvm_info("MASTER.MON.WRITE_DATA_CH", "WVALID assertion detected", UVM_HIGH);

        req_item.access_type = AXI_WRITE;

        req_item.write_valid = AXI.mmon_cb.WVALID;
        req_item.write_strobe = AXI.mmon_cb.WSTRB;
        req_item.write_data_q[0] = AXI.mmon_cb.WDATA;
        req_item.write_last = AXI.mmon_cb.WLAST;
        `uvm_info("MASTER.MON.WRITE_DATA_CH", req_item.convert2string(), UVM_HIGH)

        `uvm_info("MASTER.MON.WRITE_DATA_CH", "waiting WREADY assertion", UVM_HIGH);
        wait(AXI.mmon_cb.WREADY === `HIGH);
        `uvm_info("MASTER.MON.WRITE_DATA_CH", "WREADY assertion detected", UVM_HIGH);
        req_item.write_ready = AXI.mmon_cb.WREADY;
        ap.write(req_item);

        `uvm_info("MASTER.MON.WRITE_DATA_CH", "W channel transfer complete and published via ap port for analysis", UVM_HIGH);
        @(posedge AXI.ACLK);

    end

endtask:write_data_ch



//------------------------------------------------------------------------------------
//Method: write_response_ch
//------------------------------------------------------------------------------------
task axi_master_monitor::write_response_ch();

    master_seq_item req_item;

    forever begin

        req_item = master_seq_item::type_id::create("req_item");
        req_item.set_master_port_id(get_master_port_id());

        `uvm_info("MASTER.MON.WRITE_RESPONSE_CH", "waiting for BVALID assertion", UVM_HIGH);
        wait(AXI.mmon_cb.BVALID === `HIGH);
        `uvm_info("MASTER.MON.WRITE_RESPONSE_CH", "BVALID assertion detected", UVM_HIGH);

        req_item.access_type = AXI_WRITE;

        req_item.write_response_valid = AXI.mmon_cb.BVALID;
        req_item.write_response_id = AXI.mmon_cb.BID;
        req_item.write_response = axi_resp_e'(AXI.mmon_cb.BRESP);
        `uvm_info("MASTER.MON.WRITE_RESPONSE_CH", req_item.convert2string(), UVM_HIGH)
            
        `uvm_info("MASTER.MON.WRITE_RESPONSE_CH", "waiting for BREADY assertion", UVM_HIGH);
        wait(AXI.mmon_cb.BREADY === `HIGH);
        `uvm_info("MASTER.MON.WRITE_RESPONSE_CH", "BREADY assertion detected", UVM_HIGH);
        req_item.write_response_ready = AXI.mmon_cb.BREADY;

        ap.write(req_item);
        `uvm_info("MASTER.MON.WRITE_RESPONSE_CH", "B channel transfer complete and published via ap port for analysis", UVM_HIGH);
        @(posedge AXI.ACLK);

    end

endtask:write_response_ch


//------------------------------------------------------------------------------------
//Method: read_addr_ch
//------------------------------------------------------------------------------------
task axi_master_monitor::read_addr_ch();
 
    master_seq_item req_item;
    
    forever begin
        
        req_item = master_seq_item::type_id::create();
        req_item.set_master_port_id(get_master_port_id());

        `uvm_info("MASTER.MON.READ_ADDR_CH", "waiting for ARVALID assertion", UVM_HIGH);
        wait(AXI.mmon_cb.ARVALID === `HIGH);
        `uvm_info("MASTER.MON.READ_ADDR_CH", "ARVALID assertion detected", UVM_HIGH);

        req_item.access_type = AXI_READ;

        req_item.addr_valid = AXI.mmon_cb.ARVALID;
        req_item.trans_id = AXI.mmon_cb.ARID;
        req_item.start_addr = AXI.mmon_cb.ARADDR;
        req_item.burst_length = AXI.mmon_cb.ARLEN;
        req_item.burst_type = axi_burst_e'(AXI.mmon_cb.ARBURST);
        req_item.burst_size = axi_size_e'(AXI.mmon_cb.ARSIZE);
        req_item.lock_type = axi_lock_type_e'(AXI.mmon_cb.ARLOCK);
        req_item.prot_type = axi_prot_type_e'(AXI.mmon_cb.ARPROT);
        req_item.memory_type = axi_memory_type_e'( AXI.mmon_cb.ARCACHE);
        req_item.region_identifier = AXI.mmon_cb.ARREGION;
        req_item.quality_of_service = AXI.mmon_cb.ARQOS;
        `uvm_info("MASTER.MON.READ_ADDR_CH", req_item.convert2string(), UVM_HIGH)

        `uvm_info("MASTER.MON.READ_ADDR_CH", "waiting for ARREADY assertion", UVM_HIGH);
        wait(AXI.mmon_cb.ARREADY === `HIGH);
        `uvm_info("MASTER.MON.READ_ADDR_CH", "ARREADY assertion detected", UVM_HIGH);
        req_item.addr_ready = AXI.mmon_cb.ARREADY;
        ap.write(req_item);

        `uvm_info("MASTER.MON.WRITE_ADDR_CH", "AW channel transfer complete and published via ap port for analysis", UVM_HIGH);
        @(posedge AXI.ACLK);
    
    end

endtask:read_addr_ch


//------------------------------------------------------------------------------------
//Method: read_data_ch
//------------------------------------------------------------------------------------
task axi_master_monitor::read_data_ch();

    master_seq_item req_item;
    
    forever begin

        req_item = master_seq_item::type_id::create();
        req_item.set_master_port_id(get_master_port_id());
        
        `uvm_info("MASTER.MON.READ_DATA_CH", "waiting for RVALID assertion", UVM_HIGH);
        wait(AXI.mmon_cb.RVALID === `HIGH);
        `uvm_info("MASTER.MON.READ_DATA_CH", "RVALID assertion detected", UVM_HIGH);

        req_item.access_type = AXI_READ;

        req_item.read_valid = AXI.mmon_cb.RVALID;
        req_item.read_data_q[0] = AXI.mmon_cb.RDATA;
        req_item.read_id_q[0] = AXI.mmon_cb.RID;
        req_item.read_last = AXI.mmon_cb.RLAST;
        req_item.read_response_q[0] = axi_resp_e'(AXI.mmon_cb.RRESP);
        `uvm_info("MASTER.MON.READ_DATA_CH", req_item.convert2string(), UVM_HIGH)

        `uvm_info("MASTER.MON.READ_DATA_CH", "waiting for RREADY assertion", UVM_HIGH);
        wait(AXI.mmon_cb.RREADY === `HIGH);
        `uvm_info("MASTER.MON.READ_DATA_CH", "RREADY assertion detected", UVM_HIGH);
        req_item.read_ready = AXI.mmon_cb.RREADY;

        ap.write(req_item);
        `uvm_info("MASTER.MON.READ_DATA_CH", "R channel transfer complete and published via ap port for analysis", UVM_HIGH);
        @(posedge AXI.ACLK);

    end

endtask:read_data_ch



//------------------------------------------------------------------------------------
//Method: reset_sample
//used to sample the interface signals when reset asserted.
//------------------------------------------------------------------------------------
function void axi_master_monitor::reset_sample();

    req_item = master_seq_item::type_id::create("req_item");

    req_item.reset_detected = `HIGH;

endfunction:reset_sample


//----------------------------------------------------------------------------
//Method: set_master_port_id
//----------------------------------------------------------------------------
function void axi_master_monitor::set_master_port_id(bit [7: 0] port_id);

    this.m_port_id = port_id;

endfunction:set_master_port_id


//----------------------------------------------------------------------------
//Method: get_master_port_id
//----------------------------------------------------------------------------
function bit [7: 0] axi_master_monitor::get_master_port_id();

    return this.m_port_id;

endfunction:get_master_port_id
