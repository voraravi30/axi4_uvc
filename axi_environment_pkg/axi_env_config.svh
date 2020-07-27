//-------------------------------------------------------------------
//Class: axi_env_config
//Provide the configuration object for AXI Environment.
//-------------------------------------------------------------------
class axi_env_config extends uvm_object;
  
    //UVM factory registration macro
    `uvm_object_utils(axi_env_config)

    //-------------------------------------------------------------------
    //Data Members
    //-------------------------------------------------------------------
    //handles of master and slave agents configuration object
    master_agent_config master_cfg[];
    slave_agent_config  slave_cfg[];

    //number of AXI Master and AXI Slave in a system
    int num_of_master = 1;
    int num_of_slave = 1;

    //control bits to instantiate Master Agent and Slave Agent in Environment.
    bit has_master_agent = 1'b1;    //default configuration instantiate the Master and Slave Agent
    bit has_slave_agent  = 1'b1;

    //control bit for scoreboard and coverage to be build or not
    bit has_scoreboard = 1'b1;    //Default configuration instantiate the scoreboard and coverage component.
    bit has_coverage   = 1'b1;

    //Class Constructor Method:
    extern function new(string name = "env_cfg");

    //Convenience Method:
    extern function string convert2string();

endclass:axi_env_config;

//-------------------------------------------------------------------
//Implementation
//-------------------------------------------------------------------


//-------------------------------------------------------------------
//Class Constructor Method: new
//-------------------------------------------------------------------
function axi_env_config::new(string name = "env_cfg");

    super.new(name);

endfunction:new
//-------------------------------------------------------------------
//Method : convert2string
//return the string format of each paramter value for debugging perpose
//-------------------------------------------------------------------
function string axi_env_config::convert2string();

    string has_scb;
    string has_cov;
    has_scb = (has_scoreboard == 1'b1) ? "YES" : "No";
    has_cov = (has_coverage == 1'b1) ? "YES" : "No";

    return $sformatf("------------------------------------------------------------\nAXI Environment Configuration Details:\nNumber of Master in System: %0d\nNumber of Slave in System: %0d\nScoreboard Component:   %0s\nCoverage Component:     %0s\n------------------------------------------------------------\n", num_of_master, num_of_slave, has_scb, has_cov);

endfunction:convert2string
