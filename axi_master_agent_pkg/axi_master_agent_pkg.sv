//---------------------------------------------------------------------
//Package: axi_master_agent_pkg
//encapsulate component and class required to build the master agent
//functionality
//---------------------------------------------------------------------
package axi_master_agent_pkg;

    //import uvm base class library and utilites
    import uvm_pkg::*;

    //axi enumaration type and other defination
    import axi_defination_pkg::*;

    //include the uvm macros file
    `include "uvm_macros.svh"

    //axi specific macros and parameter such as what is address and data bus size
    `include "axi_macros.svh"
    `include "axi_params.svh"

    //include axi master agent package specific file
    `include "master_seq_item.svh"    //axi master transaction
    `include "master_agent_config.svh"    //axi master agent configuration object
    
    `include "axi_master_driver.svh"    //axi master driver component
    `include "axi_master_sequencer.svh"    //axi master sequencer component
    `include "axi_master_monitor.svh"    //axi master monitor component
    `include "axi_master_checks.svh"    //axi master checks component
    
    `include "axi_master_agent.svh"    //axi master agent component

    //master agent sequence API
    `include "axi_master_base_seq.svh"
    `include "axi_master_write_seq.svh"
    `include "axi_master_read_seq.svh"
    `include "axi_master_fixed_write_seq.svh"
    `include "axi_master_incr_write_seq.svh"
    `include "axi_master_wrap_write_seq.svh"
    `include "axi_master_fixed_read_seq.svh"
    `include "axi_master_incr_read_seq.svh"
    `include "axi_master_wrap_read_seq.svh"
    `include "axi_master_outstand_write_seq.svh"
    `include "axi_master_outstand_read_seq.svh"

endpackage:axi_master_agent_pkg
