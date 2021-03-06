//---------------------------------------------------------------------------
//Class: axi_unaligned_wrap_write_test
//configure and build axi_env. And excute the axi_unaligned_wrap_write_vseq
//---------------------------------------------------------------------------
class axi_unaligned_wrap_write_test extends axi_test_base;

    //UVM factory registration
    `uvm_component_utils(axi_unaligned_wrap_write_test)

    //----------------------------------------------------------------------
    //Data Members:
    //----------------------------------------------------------------------
    //virtual sequence handle
    axi_unaligned_wrap_write_vseq unaligned_wrap_write_vseq;

    //----------------------------------------------------------------------
    //Method prototype:
    //----------------------------------------------------------------------
    //Class Constructor method
    extern function new(string name = "unaligned_wrap_write_test", uvm_component parent = null);

    //UVM Standard phase methods:
    extern function void build_phase(uvm_phase phase);
    extern function void start_of_simulation_phase(uvm_phase phase);
    extern task main_phase(uvm_phase phase);

endclass



//---------------------------------------------------------------------
//Implementation
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//Class Constructor Method: new
//---------------------------------------------------------------------
function axi_unaligned_wrap_write_test::new(string name = "unaligned_wrap_write_test",uvm_component parent = null);

    super.new(name,parent);

endfunction:new



//----------------------------------------------------------------------------
//Method : build_phase
//instantiate the configuration objects, set the configuration parameter of
//it, set it into it's configutation table and instantiate axi_env component
//class object
//----------------------------------------------------------------------------
function void axi_unaligned_wrap_write_test::build_phase(uvm_phase phase);

    //call test_base class method
    super.build_phase(phase);

endfunction:build_phase



//----------------------------------------------------------------------------
//Method : start_of_simulation_phase
//Prints the topology of testbench and configuration parameter value of each
//sub-component
//----------------------------------------------------------------------------
function void axi_unaligned_wrap_write_test::start_of_simulation_phase(uvm_phase phase);

    //call test_base class method
    super.start_of_simulation_phase(phase);

endfunction:start_of_simulation_phase



//----------------------------------------------------------------------------
//Method: main_phase
//----------------------------------------------------------------------------
task axi_unaligned_wrap_write_test::main_phase(uvm_phase phase);

    //create the read_vseq
    unaligned_wrap_write_vseq = axi_unaligned_wrap_write_vseq::type_id::create("unaligned_wrap_write_vseq");

    //initialize read_vseq to set the sequencer handle
    init_vseq(unaligned_wrap_write_vseq);

    //raise objection
    phase.raise_objection(this, "objection raised before starting axi_unaligned_wrap_write_vseq");

    //execute sequence on null
    unaligned_wrap_write_vseq.start(null);

    //drop objection
    phase.drop_objection(this, "objection dropped after completing axi_unaligned_wrap_write_vseq");

endtask:main_phase
