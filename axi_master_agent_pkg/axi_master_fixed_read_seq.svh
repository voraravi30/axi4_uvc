//------------------------------------------------------------------------
//Class: axi_master_fixed_read_seq
//Sequence API that used to initiate fixed type of read transfer
//------------------------------------------------------------------------
class axi_master_fixed_read_seq extends axi_master_read_seq;

    //UVM factory registration macro
    `uvm_object_utils(axi_master_fixed_read_seq)

    //--------------------------------------------------------------------
    //Constraints:
    //--------------------------------------------------------------------
    constraint fixed_type_c {burst_type == FIXED;}

    //--------------------------------------------------------------------
    //Methods:
    //--------------------------------------------------------------------
    //Class Constructor Method:
    extern function new(string name = "fixed_read_seq");

endclass:axi_master_fixed_read_seq


//------------------------------------------------------------------------
//Implementation:
//------------------------------------------------------------------------


//------------------------------------------------------------------------
//Class constructor method: new
//------------------------------------------------------------------------
function axi_master_fixed_read_seq::new(string name = "fixed_read_seq");

    super.new(name);

endfunction:new
