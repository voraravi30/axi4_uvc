//---------------------------------------------------------------------------
//Class: axi_master_agent
//AXI Master Agent component is a continer component that encapsulates all the
//component that are dealing with axi interface and has analysis port.
//---------------------------------------------------------------------------
class axi_master_agent extends uvm_agent;

    //factory_registration
    `uvm_component_utils(axi_master_agent)

    //---------------------------------------------------------------------------
    //Component and Configuration Object Members:
    //---------------------------------------------------------------------------
    //AXI Master driver, sequencer, monitor handles.
    axi_master_driver    master_drv;
    axi_master_sequencer master_seqr;
    axi_master_monitor   master_mon;
    axi_master_checks    master_checks;

    //configuration object
    master_agent_config cfg;

    //analysis port to broadcast the transaction
    uvm_analysis_port #(master_seq_item) ap;

    //master port id
    protected bit [7: 0] port_id;

    //Class Constructor Method:
    extern function new(string name, uvm_component parent);

    //UVM Standard Phase Method:
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern function void end_of_elaboration_phase(uvm_phase phase);

    //Convenience method:
    extern function void set_master_port_id(bit [7: 0] port_id);
    extern function bit [7: 0] get_master_port_id();

endclass:axi_master_agent

//---------------------------------------------------------------------------
//Implementation
//---------------------------------------------------------------------------


//---------------------------------------------------------------------------
//Class Constructor Method: new
//---------------------------------------------------------------------------
function axi_master_agent::new(string name, uvm_component parent);

    super.new(name,parent);

endfunction:new

//---------------------------------------------------------------------------
//Method: build_phase
//Get the Master Agent Configuration object and conditionally build driver and 
//sequencer Component if Agent is ACTIVE. Monitor always build rather Agent is 
//ACTIVE or PASSIVE.
//---------------------------------------------------------------------------
function void axi_master_agent::build_phase(uvm_phase phase);

    //Get the Configuration object from config space.
    if(!uvm_config_db #(master_agent_config)::get(this, "", "master_agent_config", cfg)) begin
        `config_retrival_fatal(cfg);
    end

    //always build Monitor.
    master_mon  = axi_master_monitor::type_id::create("master_mon", this);
    
    //test the is_active field of master config object to build driver and
    //sequencer sub-component.
    if(cfg.is_active == UVM_ACTIVE) begin

        master_drv  = axi_master_driver::type_id::create("master_drv", this);
        master_seqr = axi_master_sequencer::type_id::create("master_seqr", this);
   
    end

    //conditionally build checks component
    if(cfg.has_master_checks == 1'b1) begin
        master_checks = axi_master_checks::type_id::create("master_checks", this);
    end

endfunction:build_phase

//---------------------------------------------------------------------------
//Method: connect_phase
//connect seq_item_port of driver to seq_item_export of sequencer. And assign analysis port 
//of monitor to analysis port of this agent. Connect virtual interface of driver and monitor 
//from config object's virtual interface
//---------------------------------------------------------------------------
function void axi_master_agent::connect_phase(uvm_phase phase);

    //actual interface assignment to virtual interface
    master_mon.AXI = cfg.axi;
    //assign the analysis port of monitor to analysis port of this component.
    ap = master_mon.ap;

    //if checks enable, connect it's analysis_export with monitor's ap port
    if(cfg.has_master_checks == 1'b1) begin
        master_mon.ap.connect(master_checks.analysis_export);
    end

    //connection of driver's port and sequencer's export and connect virtual
    //interface of drive from config object's virtual interface.
    if(cfg.is_active == UVM_ACTIVE) begin
        master_drv.seq_item_port.connect(master_seqr.seq_item_export);
        master_drv.AXI = cfg.axi;
    end

endfunction:connect_phase


//----------------------------------------------------------------------------
//Method: end_of_elaboration_phase
//----------------------------------------------------------------------------
function void axi_master_agent::end_of_elaboration_phase(uvm_phase phase);

    super.end_of_elaboration_phase(phase);
    set_master_port_id(cfg.port_id);

endfunction:end_of_elaboration_phase


//----------------------------------------------------------------------------
//Method: set_master_port_id
//----------------------------------------------------------------------------
function void axi_master_agent::set_master_port_id(bit [7: 0] port_id);

    this.port_id = port_id;

endfunction:set_master_port_id


//----------------------------------------------------------------------------
//Method: get_master_port_id
//----------------------------------------------------------------------------
function bit [7: 0] axi_master_agent::get_master_port_id();

    return this.port_id;

endfunction:get_master_port_id
