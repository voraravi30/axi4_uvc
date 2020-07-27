//-------------------------------------------------------------------------------------
//Class: axi_environment
//axi_environment component encapsulates the AXI Agents, Scoreboard, Coverage Components
//-------------------------------------------------------------------------------------
class axi_environment extends uvm_env;

    //UVM factory registration macro
    `uvm_component_utils(axi_environment)

    //----------------------------------------------------------------------------------
    //Data Members:
    //----------------------------------------------------------------------------------
    //configuration handle
    axi_env_config   cfg;

    //----------------------------------------------------------------------------------
    //Component Members:
    //----------------------------------------------------------------------------------
    //axi master agent handles
    axi_master_agent master_agt[];

    //axi slave agent handles
    axi_slave_agent slave_agt[];

    //scoreboard and coverage component handle
    axi_scoreboard axi_scb;
    axi_system_coverage axi_sys_cov;

    //Class Constructor Method:
    extern function new(string name, uvm_component parent);

    //UVM Standard Phase Methods:
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);

endclass:axi_environment

//----------------------------------------------------------------------------------
//Implementation
//----------------------------------------------------------------------------------


//----------------------------------------------------------------------------------
//Class Constructor Method: new
//----------------------------------------------------------------------------------
function axi_environment::new(string name, uvm_component parent);

    super.new(name, parent);

endfunction:new

//----------------------------------------------------------------------------------
//Method: build_phase
//Get the AXI_environment Configuration and it's configuration for it's
//Sub-Component and Create Sub-Component.
//----------------------------------------------------------------------------------
function void axi_environment::build_phase(uvm_phase phase);

    string name;

    super.build_phase(phase);

    //Get the AXI Environment Configuration from Configuration space.
    if(!uvm_config_db #(axi_env_config)::get(this, "", "axi_env_config", cfg)) begin
        `config_retrival_fatal(cfg)
    end

    if(cfg.num_of_master==0) begin
        `uvm_fatal("NO_MASTER", {"num_of_master filed of: ", cfg.get_full_name() ," must be non-zero"})
    end
    if(cfg.num_of_slave==0) begin
        `uvm_fatal("NO_SLAVE", {"num_of_slave filed of: ", cfg.get_full_name() ," must be non-zero"})
    end

    //creates numbers of axi master that specified by env_config
    master_agt = new[cfg.num_of_master];
    for(int num=0; num<cfg.num_of_master; num++) begin
        $sformat(name, "master_agt[%0d]", num);
        uvm_config_db #(master_agent_config)::set(this, {name, "*"}, "master_agent_config", cfg.master_cfg[num]);
        master_agt[num] = axi_master_agent::type_id::create(name, this);
    end

    //creates numbers of axi slave that specified by env_config
    slave_agt = new[cfg.num_of_slave];
    for(int num=0; num<cfg.num_of_slave; num++) begin
        $sformat(name, "slave_agt[%0d]", num);
        uvm_config_db #(slave_agent_config)::set(this, {name, "*"}, "slave_agent_config", cfg.slave_cfg[num]);
        slave_agt[num] = axi_slave_agent::type_id::create(name, this);
    end

    //test corresponding configuration field to conditionaly build the
    //Scoreboard and Coverage Component.
    if(cfg.has_scoreboard == 1'b1) begin
        uvm_config_db #(axi_env_config)::set(this, "axi_scb", "axi_env_config", cfg);
        axi_scb = axi_scoreboard::type_id::create("axi_scb", this); 
    end
    if(cfg.has_coverage == 1'b1) begin
        uvm_config_db #(axi_env_config)::set(this, "axi_sys_cov", "axi_env_config", cfg);
        axi_sys_cov = axi_system_coverage::type_id::create("axi_sys_cov", this);
    end

endfunction:build_phase


//----------------------------------------------------------------------------------
//Method: connect_phase
//Connect the TLM port to corresponding TLM exports.
//----------------------------------------------------------------------------------
function void axi_environment::connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    if(cfg.has_scoreboard == 1'b1) begin
        foreach(master_agt[index]) begin
            master_agt[index].ap.connect(axi_scb.input_export[index]);
        end
    end
    
    if(cfg.has_coverage == 1'b1) begin
        foreach(master_agt[index]) begin
            master_agt[index].ap.connect(axi_sys_cov.cover_export[index]);
        end
    end

endfunction:connect_phase
