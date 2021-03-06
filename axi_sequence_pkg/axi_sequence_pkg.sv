//--------------------------------------------------------------------
//Pacakge: axi_sequence_pkg
//include the test level sequences that represent test specific scenarios
//--------------------------------------------------------------------
package axi_sequence_pkg;

    //import the uvm base class library and utilities
    import uvm_pkg::*;
    //import master agent package
    import axi_master_agent_pkg::*;
    //import slave agent package
    import axi_slave_agent_pkg::*;
    //axi enumaration type and other defination
    import axi_defination_pkg::*;

    //include uvm macro
    `include "uvm_macros.svh"

    //axi specific macros and parameter such as what is address and data bus size
    `include "axi_macros.svh"
    `include "axi_params.svh"

    //inlclude the sequences that represent test level scenarios
    `include "axi_virtual_sequence_base.svh"    //virtual sequence base class... from the all test specific sequences are derived

    //random write sequence
    `include "axi_rand_write_vseq.svh"
    //random read sequence
    `include "axi_rand_read_vseq.svh"

    `include "axi_fixed_write_vseq.svh"
    `include "axi_incr_write_vseq.svh"
    `include "axi_wrap_write_vseq.svh"

    `include "axi_fixed_read_vseq.svh"
    `include "axi_incr_read_vseq.svh"
    `include "axi_wrap_read_vseq.svh"

    `include "axi_fixed_write_to_read_vseq.svh"
    `include "axi_incr_write_to_read_vseq.svh"
    `include "axi_wrap_write_to_read_vseq.svh"

    `include "axi_aligned_fixed_write_vseq.svh"
    `include "axi_aligned_incr_write_vseq.svh"
    `include "axi_aligned_wrap_write_vseq.svh"

    `include "axi_aligned_fixed_read_vseq.svh"
    `include "axi_aligned_incr_read_vseq.svh"
    `include "axi_aligned_wrap_read_vseq.svh"

    `include "axi_unaligned_fixed_write_vseq.svh"
    `include "axi_unaligned_incr_write_vseq.svh"
    `include "axi_unaligned_wrap_write_vseq.svh"

    `include "axi_unaligned_fixed_read_vseq.svh"
    `include "axi_unaligned_incr_read_vseq.svh"
    `include "axi_unaligned_wrap_read_vseq.svh"

    `include "axi_fixed_narrow_write_to_read_vseq.svh"
    `include "axi_incr_narrow_write_to_read_vseq.svh"
    `include "axi_wrap_narrow_write_to_read_vseq.svh"

    `include "axi_rand_outstand_write_vseq.svh"
    `include "axi_rand_outstand_read_vseq.svh"

    `include "axi_fixed_simultaneous_write_read_vseq.svh"
    `include "axi_incr_simultaneous_write_read_vseq.svh"
    `include "axi_wrap_simultaneous_write_read_vseq.svh"

endpackage
