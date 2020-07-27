//-------------------------------------------------------------------
//Class: slave_agent_config
//Provide the configuration object for AXI Slave Agent
//-------------------------------------------------------------------
class slave_agent_config extends uvm_object;

    //UVM factory_registration macro
    `uvm_object_utils(slave_agent_config)

    //-------------------------------------------------------------------
    //Data Members
    //-------------------------------------------------------------------
    //slave port id
    bit [7: 0] port_id;

    //is_active variable to control agent's behavior(i.e ACTIVE or PASSIVE Agent)
    uvm_active_passive_enum is_active;

    //knob to control checks(default is enable)
    bit enable_checks = 1'b1;

    //handle of axi slave interface
    virtual axi_slave_if axi;

    //supported width of data bus(in a byte)
    //default is 4 bytes
    int data_bus_bytes = 4;

    //Supported burst type...1st index is for FIXED, 2nd index if for INCR,
    //3rd for WRAP support...if particular index bit is zero, that burst_type
    //is not supported...default is all supported
    bit supported_burst_type[bit [1: 0]] = '{0:1'b1, 1:1'b1, 2:1'b1};

    //how much length of burst is supported by slave
    //default is upto 255
    bit [8: 0] burst_length = 9'h100;

    //specify address range
    int unsigned lower_addr;
    int unsigned upper_addr;

    //Class Constructor Method:
    extern function new(string name = "slave_cfg");

    //Convenience Methods:
    extern function string convert2string();
    extern task wait_for_reset_end();
    extern task clock_delay(int clk=1);

endclass:slave_agent_config

//-------------------------------------------------------------------
//Implementation
//-------------------------------------------------------------------


//-------------------------------------------------------------------
//Class Constructor Method: new
//-------------------------------------------------------------------
function slave_agent_config::new(string name = "slave_cfg");

    super.new(name);

endfunction:new

//-------------------------------------------------------------------
//Method : convert2string
//return the string format of each paramter value for debugging perpose
//-------------------------------------------------------------------
function string slave_agent_config::convert2string();

    string vif_value;
    string supported_burst;
    string check_enable;

    check_enable = (enable_checks == 1'b1) ? "YES" : "NO";
    case({this.supported_burst_type[2],this.supported_burst_type[1],this.supported_burst_type[0]})
        3'b000: supported_burst = "NO_BURST_SUPPORT(please check burst type configuration)";
        3'b001: supported_burst = "FIXED";
        3'b010: supported_burst = "INCR";
        3'b011: supported_burst = "FIXED, INCR";
        3'b100: supported_burst = "WRAP";
        3'b101: supported_burst = "FIXED, WRAP";
        3'b110: supported_burst = "INCR, WRAP";
        3'b111: supported_burst = "FIXED, INCR, WRAP";
    endcase
    vif_value = (axi != null) ? "SET" : "NULL";
    
    return $sformatf("------------------------------------------------------------\nAXI Slave[%0d] Configuration Details:\nAddress range:0x%0h - 0x%0h\nAXI Slave Mode: %0s\nData Bus Size: %0d byte wide\nSupported burst type: %0s\nSupported burst length upto: %0d\nHas checks: %0s\nVirtual interface: %0s\n------------------------------------------------------------\n", this.port_id, this.lower_addr, this.upper_addr, this.is_active.name(), this.data_bus_bytes, supported_burst, burst_length, check_enable, vif_value);

endfunction

//-------------------------------------------------------------------
//Method: wait_for_reset_end
//call to this method return afeter reset de-asserted
//-------------------------------------------------------------------
task slave_agent_config::wait_for_reset_end();
    
    wait(axi.ARESETn === `HIGH);

endtask:wait_for_reset_end


//-------------------------------------------------------------------
//Method: clock_delay
//provide clock delay of times values passed by argument
//-------------------------------------------------------------------
task slave_agent_config::clock_delay(int clk=1);

    repeat(clk) begin
        @(posedge axi.ACLK);
    end

endtask:clock_delay
