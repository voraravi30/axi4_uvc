//-------------------------------------------------------------------
//Class : master_agent_config
//Provide the configuration object for  AXI Master Agent
//-------------------------------------------------------------------
class master_agent_config extends uvm_object;

    //UVM factory registration macro
    `uvm_object_utils(master_agent_config)

    //-------------------------------------------------------------------
    //Data Members
    //-------------------------------------------------------------------
    //master port id
    bit [7: 0] port_id;

    //is_active variable to control agent's behavior(i.e ACTIVE or PASSIVE Agent)
    uvm_active_passive_enum is_active;

    //knob to control master checks(default is enable)
    bit has_master_checks = 1'b1;

    //handle of axi master interface
    virtual axi_master_if axi;

    //supported width of data bus(in a byte)
    //default is 4 bytes
    int data_bus_bytes = 4;

    //Class Constructor method
    extern function new(string name = "master_cfg");

    //Convenience Methods:
    extern function string convert2string();
    extern task wait_for_reset_end();

endclass:master_agent_config

//-------------------------------------------------------------------
//Implementation
//-------------------------------------------------------------------


//-------------------------------------------------------------------
//Class Constructor Method: new
//-------------------------------------------------------------------
function master_agent_config::new(string name = "master_cfg");

    super.new(name);

endfunction:new

//-------------------------------------------------------------------
//Method : convert2string
//return the string format of each paramter value for debugging perpose
//-------------------------------------------------------------------
function string master_agent_config::convert2string();

    string vif_value;
    string has_checks;
    vif_value = (axi != null) ? "SET" : "NULL";
    has_checks = (has_master_checks == 1'b1) ? "YES" : "NO";
    
    return $sformatf("------------------------------------------------------------\nAXI Master[%0d] Configuration Details: \nAXI Master Mode: %0s\nData Bus Size: %0d byte wide\nVirtual interface is: %0s\nHas Master Checks: %0s\n-------------------------------------------------------------\n", this.port_id, this.is_active.name(), this.data_bus_bytes, vif_value, has_checks);

endfunction

//-------------------------------------------------------------------
//Method : wait_for_reset_end
//wait for the reset to de-assert
//-------------------------------------------------------------------
task master_agent_config::wait_for_reset_end();
    
    wait(axi.ARESETn === `HIGH);    //reset is active-low

endtask:wait_for_reset_end
