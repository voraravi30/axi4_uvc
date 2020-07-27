//---------------------------------------------------------------------------
//Class: axi_fixed_simultaneous_write_read_test
//---------------------------------------------------------------------------
class axi_fixed_simultaneous_write_read_test extends axi_test_base;

    //UVM factory registration
    `uvm_component_utils(axi_fixed_simultaneous_write_read_test)

    //----------------------------------------------------------------------
    //Method prototype:
    //----------------------------------------------------------------------
    //Class Constructor method
    extern function new(string name = "simultaneous_write_read_test", uvm_component parent = null);

    //UVM Standard phase methods:
    extern function void build_phase(uvm_phase phase);
    extern function void start_of_simulation_phase(uvm_phase phase);
    extern task main_phase(uvm_phase phase);

endclass:axi_fixed_simultaneous_write_read_test



//---------------------------------------------------------------------
//Implementation
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//Class Constructor Method: new
//---------------------------------------------------------------------
function axi_fixed_simultaneous_write_read_test::new(string name = "simultaneous_write_read_test",uvm_component parent = null);

    super.new(name,parent);

endfunction:new


//----------------------------------------------------------------------------
//Method : build_phase
//instantiate the configuration objects, set the configuration parameter of
//it, set it into it's configutation table and instantiate axi_env component
//class object
//----------------------------------------------------------------------------
function void axi_fixed_simultaneous_write_read_test::build_phase(uvm_phase phase);

    //call test_base class method
    super.build_phase(phase);

endfunction:build_phase


//----------------------------------------------------------------------------
//Method : start_of_simulation_phase
//Prints the topology of testbench and configuration parameter value of each
//sub-component
//----------------------------------------------------------------------------
function void axi_fixed_simultaneous_write_read_test::start_of_simulation_phase(uvm_phase phase);

    //call test_base class method
    super.start_of_simulation_phase(phase);

endfunction:start_of_simulation_phase


//----------------------------------------------------------------------------
//Method: main_phase
//----------------------------------------------------------------------------
task axi_fixed_simultaneous_write_read_test::main_phase(uvm_phase phase);

    axi_fixed_simultaneous_write_read_vseq simultaneous_write_read_vseq;

    //create the write_vseq
    simultaneous_write_read_vseq = axi_fixed_simultaneous_write_read_vseq::type_id::create("simultaneous_write_read_vseq");

    //initialize write_vseq to set the sequencer handle
    init_vseq(simultaneous_write_read_vseq);

    //raise objection
    phase.raise_objection(this, $sformatf("objection raised before starting %0s sequence", simultaneous_write_read_vseq.get_name()));

    //execute sequence on null
    simultaneous_write_read_vseq.start(null);

    //drop objection
    phase.drop_objection(this, $sformatf("objection dropped after completing %0s sequence", simultaneous_write_read_vseq.get_name()));

endtask:main_phase
