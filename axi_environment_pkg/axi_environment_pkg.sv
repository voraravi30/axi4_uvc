//---------------------------------------------------------------------
//Package: axi_environment_pkg
//Contains all the inter-related class that used to encapsulate in axi env
//---------------------------------------------------------------------
package axi_environment_pkg;

    //import the uvm base class library and utilities
    import uvm_pkg::*;

    //import master and slave agent packages
    import axi_master_agent_pkg::*;
    import axi_slave_agent_pkg::*;

    //axi enumaration type and other defination
    import axi_defination_pkg::*;
    
    //include uvm macro file
    `include "uvm_macros.svh"

    //include environment specific files
    `include "axi_macros.svh"
    `include "axi_params.svh"    //axi specific parameter such as what is address and data bus size

    `include "axi_env_config.svh"    //environment configuration object class

    `include "axi_master_txn_buffer.svh"    //component class to temperory store initiated txn
    `include "axi_scoreboard.svh"    //scoreboard component class
    `include "axi_coverage.svh"    //coverage collector coomponent class
    `include "axi_system_coverage.svh"    //wrapper component for coverage
    
    `include "axi_environment.svh"    //axi environment component class

endpackage:axi_environment_pkg
