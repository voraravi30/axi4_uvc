//---------------------------------------------------------------------------
//Class: axi_storage_component
//represent ram based storage element and defines useful API
//---------------------------------------------------------------------------
class axi_storage_component extends uvm_component;

    //UVM factory registration
    `uvm_component_utils(axi_storage_component)

    //-----------------------------------------------------------------------
    //Data Members:
    //-----------------------------------------------------------------------
    //8-bit wide Memory 
    bit [7:0] mem [int unsigned];

    //-----------------------------------------------------------------------
    //Methods:
    //-----------------------------------------------------------------------
    //Class Constructor method:
    extern function new(string name, uvm_component parent);

    //write API
    extern virtual function void write(bit [`ADDR_BUS_WIDTH-1:0] addr, bit [7:0] data);

    //read API
    extern virtual function bit [7:0] read(bit [`ADDR_BUS_WIDTH-1:0] addr);

    //reset_memory API
    extern virtual function void reset_memory();

endclass:axi_storage_component


//---------------------------------------------------------------------------
//Implementation:
//---------------------------------------------------------------------------


//---------------------------------------------------------------------------
//Class Constructor Method: new
//---------------------------------------------------------------------------
function axi_storage_component::new(string name, uvm_component parent);

    super.new(name,parent);

endfunction:new


//---------------------------------------------------------------------------
//Method: write
//---------------------------------------------------------------------------
function void axi_storage_component::write(bit [`ADDR_BUS_WIDTH-1:0] addr, bit [7:0] data);

    this.mem[addr] = data;

endfunction:write


//---------------------------------------------------------------------------
//Method: read
//---------------------------------------------------------------------------
function bit [7:0] axi_storage_component::read(bit [`ADDR_BUS_WIDTH-1:0] addr);

    return this.mem[addr];

endfunction

//---------------------------------------------------------------------------
//Method: reset_memory
//---------------------------------------------------------------------------
function void axi_storage_component::reset_memory();

    foreach(mem[index]) begin

        this.mem[index] = 8'h00;
    
    end

endfunction:reset_memory
