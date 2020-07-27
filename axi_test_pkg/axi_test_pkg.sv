//--------------------------------------------------------------------
//Package: axi_test_pkg
//encapsulate all the test specific files
//--------------------------------------------------------------------
package axi_test_pkg;

    //import uvm base class library and utility package
    import uvm_pkg::*;

    //import axi_environment_pkg
    import axi_environment_pkg::*;
    
    //import axi_slave_agent_pkg
    import axi_slave_agent_pkg::*;

    //import axi_master_agent_pkg
    import axi_master_agent_pkg::*;

    //import sequences package
    import axi_sequence_pkg::*;

    //axi enumaration type and other defination
    import axi_defination_pkg::*;

    //include uvm macros
    `include "uvm_macros.svh"
  
    //include axi parameters
    `include "axi_params.svh"

    //include test base class and other test
    `include "axi_test_base.svh"

    `include "axi_rand_write_test.svh"
    `include "axi_rand_read_test.svh"

    `include "axi_fixed_write_test.svh"
    `include "axi_incr_write_test.svh"
    `include "axi_wrap_write_test.svh"

    `include "axi_fixed_read_test.svh"
    `include "axi_incr_read_test.svh"
    `include "axi_wrap_read_test.svh"

    `include "axi_fixed_write_to_read_test.svh"
    `include "axi_incr_write_to_read_test.svh"
    `include "axi_wrap_write_to_read_test.svh"

    `include "axi_aligned_fixed_write_test.svh"
    `include "axi_aligned_incr_write_test.svh"
    `include "axi_aligned_wrap_write_test.svh"

    `include "axi_aligned_fixed_read_test.svh"
    `include "axi_aligned_incr_read_test.svh"
    `include "axi_aligned_wrap_read_test.svh"

    `include "axi_unaligned_fixed_write_test.svh"
    `include "axi_unaligned_incr_write_test.svh"
    `include "axi_unaligned_wrap_write_test.svh"

    `include "axi_unaligned_fixed_read_test.svh"
    `include "axi_unaligned_incr_read_test.svh"
    `include "axi_unaligned_wrap_read_test.svh"

    `include "axi_fixed_narrow_write_to_read_test.svh"
    `include "axi_incr_narrow_write_to_read_test.svh"
    `include "axi_wrap_narrow_write_to_read_test.svh"

    `include "axi_rand_outstand_write_test.svh"
    `include "axi_rand_outstand_read_test.svh"

    `include "axi_fixed_simultaneous_write_read_test.svh"
    `include "axi_incr_simultaneous_write_read_test.svh"
    `include "axi_wrap_simultaneous_write_read_test.svh"

endpackage:axi_test_pkg
