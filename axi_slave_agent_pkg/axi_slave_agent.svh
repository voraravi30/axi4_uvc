//---------------------------------------------------------------------------
//Class: axi_slave_agent
//AXI Slave Agent component is a continer component that encapsulates all the
//component that are dealing with axi interface and has analysis port.
//---------------------------------------------------------------------------
class axi_slave_agent extends uvm_agent;

    //UVM factory registration macro
    `uvm_component_utils(axi_slave_agent)
    
    //---------------------------------------------------------------------------
    //Component and Configuration Object Members:
    //---------------------------------------------------------------------------
    //AXI Master driver, sequencer, monitor handles.
    axi_slave_driver    slave_drv;
    axi_slave_monitor   slave_mon;
    axi_slave_sequencer slave_seqr;
    
    //Storage component
    axi_storage_component storage;

    //Configuration object
    slave_agent_config  slave_cfg;

    //Analysis port to broadcast the transaction
    uvm_analysis_port #(slave_seq_item) ap;

    //---------------------------------------------------------------------------
    //Methods:
    //---------------------------------------------------------------------------
    //Class Constructor Method:
    extern function new(string name, uvm_component parent);

    //UVM Standard Phase Method:
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);

endclass:axi_slave_agent


//---------------------------------------------------------------------------
//Implementation
//---------------------------------------------------------------------------


//---------------------------------------------------------------------------
//Class Constructor Method: new
//---------------------------------------------------------------------------

function axi_slave_agent::new(string name, uvm_component parent);

    super.new(name,parent);

endfunction:new


//---------------------------------------------------------------------------
//Method: build_phase
//Get the Slave Agent Configuration object and conditionally build driver and 
//sequencer Component if Agent is ACTIVE. Monitor always build rather Agent is 
//ACTIVE or PASSIVE.
//---------------------------------------------------------------------------
function void axi_slave_agent::build_phase(uvm_phase phase);

    super.build_phase(phase);

    //Get the Configuration object from config space.
    if(!uvm_config_db #(slave_agent_config)::get(this, "", "slave_agent_config", slave_cfg)) begin
        `config_retrival_fatal(slave_cfg);
    end

    //always build Monitor.
    slave_mon = axi_slave_monitor::type_id::create("slave_mon", this);

    //test the is_active field of master config object to build driver and
    //sequencer sub-component.
    if(slave_cfg.is_active == UVM_ACTIVE) begin

        slave_drv   = axi_slave_driver::type_id::create("slave_drv", this);
        slave_seqr  = axi_slave_sequencer::type_id::create("slave_seqr", this);
        storage = axi_storage_component::type_id::create("storage", this);

    end

endfunction:build_phase


//---------------------------------------------------------------------------
//Method: connect_phase
//connect seq_item_port of driver to seq_item_export of sequencer. And assign analysis port 
//of monitor to analysis port of this agent. Connect virtual interface of driver and monitor 
//from config object's virtual interface
//---------------------------------------------------------------------------
function void axi_slave_agent::connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    //actual interface assignment to virtual interface
    slave_mon.AXI = slave_cfg.axi;
    //assign the analysis port of monitor to analysis port of this component.
    ap = slave_mon.ap;

    //connection of driver's port and sequencer's export and connect virtual
    //interface of drive from confgi object's virtual interface.
    if(slave_cfg.is_active == UVM_ACTIVE) begin

        slave_drv.seq_item_port.connect(slave_seqr.seq_item_export);
        slave_mon.req_port.connect(slave_seqr.req_imp);

        slave_drv.AXI = slave_cfg.axi;

        slave_drv.storage = this.storage;
        slave_seqr.storage = this.storage;
    
    end

endfunction:connect_phase
