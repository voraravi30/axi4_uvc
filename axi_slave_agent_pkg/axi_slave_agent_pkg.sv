//---------------------------------------------------------------------
//Package: axi_slave_agent_pkg
//encapsulate the component and object class required to build slave agent
//functionality
//---------------------------------------------------------------------
package axi_slave_agent_pkg;

    //import the uvm base class library and utilities
    import uvm_pkg::*;

    //axi enumaration type and other defination
    import axi_defination_pkg::*;

    //include the uvm defined macro file
    `include "uvm_macros.svh"

    //axi specific macros and parameter such as what is address and data bus size
    `include "axi_macros.svh"
    `include "axi_params.svh"

    //include component and object class required for slave behavior
    `include "slave_seq_item.svh"    //slave data item object class
    `include "slave_agent_config.svh"    //slave agent configuration object class

    `include "axi_storage_component.svh"    //memory component
    `include "axi_slave_driver.svh"    //slave driver component class
    `include "axi_slave_sequencer.svh"    //slave sequencer component class
    `include "axi_slave_monitor.svh"    //slave monitor component class

    `include "axi_slave_agent.svh"    //slave agent component class

    //slave sequence API
    `include "axi_slave_base_seq.svh"
    `include "axi_slave_write_seq.svh"
    `include "axi_slave_read_seq.svh"
    `include "axi_slave_main_seq.svh"

endpackage:axi_slave_agent_pkg
