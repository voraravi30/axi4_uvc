//------------------------------------------------------------------------
//Class: axi_master_wrap_write_seq
//Sequence API that used to initiate wrap type write transfer
//------------------------------------------------------------------------
class axi_master_wrap_write_seq extends axi_master_write_seq;

    //UVM factory registration macro
    `uvm_object_utils(axi_master_wrap_write_seq)

    //--------------------------------------------------------------------
    //Constraints:
    //--------------------------------------------------------------------
    constraint wrap_type_c {burst_type == WRAP;}

    //--------------------------------------------------------------------
    //Methods:
    //--------------------------------------------------------------------
    //Class Constructor Method:
    extern function new(string name = "wrap_write_seq");

endclass:axi_master_wrap_write_seq


//------------------------------------------------------------------------
//Implementation:
//------------------------------------------------------------------------


//------------------------------------------------------------------------
//Class constructor method: new
//------------------------------------------------------------------------
function axi_master_wrap_write_seq::new(string name = "wrap_write_seq");

    super.new(name);

endfunction:new
