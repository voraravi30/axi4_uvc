//---------------------------------------------------------------------
//Class : axi_test_base 
//Responsible for creating environment and configuring
//the testbench environment. All testcase are derived from this test base class
//---------------------------------------------------------------------
class axi_test_base extends uvm_test;

    //UVM factory registration macro
    `uvm_component_utils(axi_test_base)

    //---------------------------------------------------------------------
    //Component Members
    //---------------------------------------------------------------------
    //axi environment handle
    axi_environment axi_env;

    //---------------------------------------------------------------------
    //Sub-component configuration object handle
    //---------------------------------------------------------------------
    //environment configuration handle
    axi_env_config  env_cfg;
    //master and slave configuration handles
    master_agent_config master_cfg[];
    slave_agent_config  slave_cfg[];

    //UVM Standard phase methods:
    extern function void build_phase(uvm_phase phase);
    extern function void start_of_simulation_phase(uvm_phase phase);

    //Class Constructor method
    extern function new(string name = "axi_test_base", uvm_component parent = null);

    //Configutation methods:
    extern virtual function void axi_environment_config(bit [7: 0] num_of_master, num_of_slave, axi_env_config cfg);
    extern virtual function void axi_master_config(bit [7: 0] port_id, data_size=4, master_agent_config cfg);
    extern virtual function void axi_slave_config(bit [7: 0] port_id, data_size=4, bit [8: 0] burst_length=256, string supported_burst="FIXED, INCR, WRAP", slave_agent_config cfg, int unsigned lower_addr, upper_addr);
    
    //virtual sequence initialization method:
    extern virtual function void init_vseq(axi_virtual_sequence_base vseq);

endclass:axi_test_base

//---------------------------------------------------------------------
//Implementation
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//Class Constructor Method: new
//---------------------------------------------------------------------
function axi_test_base::new(string name = "axi_test_base",uvm_component parent = null);

    super.new(name,parent);

endfunction:new

//----------------------------------------------------------------------------
//Method : build_phase
//instantiate the configuration objects, set the configuration parameter of
//it, set it into it's configutation table and instantiate axi_env component
//class object
//----------------------------------------------------------------------------
function void axi_test_base::build_phase(uvm_phase phase);

    string name;

    super.build_phase(phase);

    //create the axi_env_config object.
    env_cfg = axi_env_config::type_id::create("env_cfg");
    //Call function to configure the env.
    axi_environment_config(1, 1, env_cfg);

    //create each master agent config object and configure and assign into env_cfg.
    master_cfg = new[env_cfg.num_of_master];
    foreach(env_cfg.master_cfg[num]) begin
        $sformat(name, "master_cfg[%0d]", num);
        master_cfg[num] = master_agent_config::type_id::create(name);
        axi_master_config(num, 4, master_cfg[num]);
        if(!uvm_config_db#(virtual axi_master_if)::get(this, "", $sformatf("axi_master[%0d]",num), master_cfg[num].axi)) begin
            `uvm_fatal("NOVIF", {"virtual interface handle must be set for: ", master_cfg[num].get_name(), ".axi"})
        end
        env_cfg.master_cfg[num] = master_cfg[num];
    end
   
    //create each slave_agent_config object and configure it.
    slave_cfg = new[env_cfg.num_of_slave];
    foreach(env_cfg.slave_cfg[num]) begin
        $sformat(name, "slave_cfg[%0d]", num);
        slave_cfg[num] = slave_agent_config::type_id::create(name);
    end

    //Call function to configure the slave agent
    axi_slave_config(0, 4, 256, "FIXED, INCR, WRAP", slave_cfg[0], 0, 4095);
    if(!uvm_config_db#(virtual axi_slave_if)::get(this, "", "axi_slave[0]", slave_cfg[0].axi)) begin
        `uvm_fatal("NOVIF", {"virtual interface handle must be set for: ", slave_cfg[0].get_name(), ".axi"})
    end
    
    //Assign the slave angent config handle inside the env_config:
    foreach(env_cfg.slave_cfg[num]) begin
        env_cfg.slave_cfg[num] = slave_cfg[num];
    end
    
    //set env config into config space:
    uvm_config_db#(axi_env_config)::set(this, "axi_env", "axi_env_config", env_cfg);
    //create the environment component's object
    axi_env = axi_environment::type_id::create("axi_env", this);

endfunction:build_phase

//----------------------------------------------------------------------------
//Method : start_of_simulation_phase
//Prints the topology of testbench and configuration parameter value of each
//sub-component
//----------------------------------------------------------------------------
function void axi_test_base::start_of_simulation_phase(uvm_phase phase);

    super.start_of_simulation_phase(phase);
    
    //prints Configuration parameter values.
    uvm_report_info("CFG_DETAILS", $sformatf("\n%s",env_cfg.convert2string()), UVM_NONE, `__FILE__, `__LINE__);
    foreach(master_cfg[num]) begin
        uvm_report_info("CFG_DETAILS", $sformatf("\n%s",master_cfg[num].convert2string()), UVM_NONE, `__FILE__, `__LINE__);
    end
    foreach(slave_cfg[num]) begin
        uvm_report_info("CFG_DETAILS", $sformatf("\n%s",slave_cfg[num].convert2string()), UVM_NONE, `__FILE__, `__LINE__);
    end
    
    //prints the testbench topology.
    uvm_top.print_topology();

    uvm_pkg::factory.print(2);

endfunction:start_of_simulation_phase

//----------------------------------------------------------------------------
//Method : axi_environment_config
//enables the configutation of env config object
//----------------------------------------------------------------------------
function void axi_test_base::axi_environment_config(bit [7: 0] num_of_master, num_of_slave, axi_env_config cfg);

    cfg.num_of_master = num_of_master;
    cfg.num_of_slave = num_of_slave;
    cfg.has_scoreboard = 1'b1;
    cfg.has_coverage = 1'b1;

    cfg.master_cfg = new[num_of_master];
    cfg.slave_cfg = new[num_of_slave];

endfunction:axi_environment_config


//----------------------------------------------------------------------------
//Method : axi_master_config
//Configure the master agent config object
//----------------------------------------------------------------------------
function void axi_test_base::axi_master_config(bit [7: 0] port_id,data_size=4, master_agent_config cfg);

    cfg.port_id = port_id;
    cfg.data_bus_bytes = data_size;
    cfg.is_active = UVM_ACTIVE;

endfunction:axi_master_config


//----------------------------------------------------------------------------
//Method : axi_slave_config
//Configure the axi slave agent config object
//----------------------------------------------------------------------------
function void axi_test_base::axi_slave_config(bit [7: 0] port_id,data_size=4, bit [8: 0] burst_length=256, string supported_burst="FIXED, INCR, WRAP", slave_agent_config cfg, int unsigned lower_addr, upper_addr);

    cfg.port_id = port_id;
    cfg.lower_addr = lower_addr;
    cfg.upper_addr = upper_addr;
    cfg.burst_length = burst_length;
    cfg.data_bus_bytes = data_size;
    case(supported_burst)
        "FIXED": {cfg.supported_burst_type[2],cfg.supported_burst_type[1],cfg.supported_burst_type[0]} = 3'b001;
        "INCR": {cfg.supported_burst_type[2],cfg.supported_burst_type[1],cfg.supported_burst_type[0]} = 3'b010;
        "FIXED, INCR": {cfg.supported_burst_type[2],cfg.supported_burst_type[1],cfg.supported_burst_type[0]} = 3'b011;
        "WRAP": {cfg.supported_burst_type[2],cfg.supported_burst_type[1],cfg.supported_burst_type[0]} = 3'b100;
        "FIXED, WRAP": {cfg.supported_burst_type[2],cfg.supported_burst_type[1],cfg.supported_burst_type[0]} = 3'b101;
        "INCR, WRAP": {cfg.supported_burst_type[2],cfg.supported_burst_type[1],cfg.supported_burst_type[0]} = 3'b110;
        "FIXED, INCR, WRAP": {cfg.supported_burst_type[2],cfg.supported_burst_type[1],cfg.supported_burst_type[0]} = 3'b111;
    endcase
    cfg.is_active = UVM_ACTIVE;

endfunction:axi_slave_config


//----------------------------------------------------------------------------
//Method : inti_vseq
//initilize the virtual_sequence. (i.e set to the sequencer handles)
//----------------------------------------------------------------------------
function void axi_test_base::init_vseq(axi_virtual_sequence_base vseq);

    vseq.master_seqr = new[env_cfg.num_of_master];
    vseq.slave_seqr = new[env_cfg.num_of_slave];
    //check first targeted master sequencer is null or not. if it is null
    //generate fatal to drove user attention
    foreach(axi_env.master_agt[num]) begin
        if(axi_env.master_agt[num].master_seqr == null) begin
            `uvm_fatal(get_full_name(), $sformatf("AXI master_agt[%0d] has null sequencer: this test case will fail, check config",num));
        end
        else begin
            vseq.master_seqr[num] = axi_env.master_agt[num].master_seqr;
        end
    end

    //check first targeted slave sequencer is null or not. if it is null
    //generate fatal to drove user attention
    foreach(axi_env.slave_agt[num]) begin
        if(axi_env.slave_agt[num].slave_seqr == null) begin
            `uvm_fatal(get_full_name(), $sformatf("AXI slave_agt[%0d] has null sequencer: this test case will fail, check config",num));
        end
        else begin
            vseq.slave_seqr[num]  = axi_env.slave_agt[num].slave_seqr;
        end
    end

endfunction
