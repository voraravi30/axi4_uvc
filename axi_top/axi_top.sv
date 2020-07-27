module axi_top;
    
    //include the axi parameter file
    `include "axi_params.svh"

    //include axi macros file
    `include "axi_macros.svh"

    //include the axi interface files
    `include "axi_master_if.sv"
    `include "axi_slave_if.sv"

    //import uvm package
    import uvm_pkg::*;

    //import axi test package
    import axi_test_pkg::*;

    //axi clock and reset
    logic ACLK;
    logic ARESETn;

    //instantiate axi interface
    axi_master_if axi_master_0(ACLK, ARESETn);
    axi_slave_if axi_slave_0(ACLK, ARESETn);

    //initial block:
    //virtual interface wrapping and run_test()
    initial begin
        uvm_config_db #(virtual axi_master_if)::set(uvm_root::get(), "uvm_test_top", "axi_master[0]", axi_master_0);
        uvm_config_db #(virtual axi_slave_if)::set(uvm_root::get(), "uvm_test_top", "axi_slave[0]", axi_slave_0);
        uvm_pkg::run_test();
    end

    //ACLK initial block:
    initial begin
        
        ACLK = 1'b0;
        forever begin
            #5 ACLK = ~ACLK;
        end

    end

    //ARESETn initial block:
    initial begin

        ARESETn = 1'b0;
        repeat(3) begin
            @(negedge ACLK);
        end
        ARESETn = 1'b1;

    end

    assign axi_slave_0.AWVALID = axi_master_0.AWVALID;
    assign axi_master_0.AWREADY = axi_slave_0.AWREADY;
    assign axi_slave_0.AWID = axi_master_0.AWID;
    assign axi_slave_0.AWADDR = axi_master_0.AWADDR;
    assign axi_slave_0.AWLEN = axi_master_0.AWLEN;
    assign axi_slave_0.AWSIZE = axi_master_0.AWSIZE;
    assign axi_slave_0.AWBURST = axi_master_0.AWBURST;
    assign axi_slave_0.AWLOCK = axi_master_0.AWLOCK;
    assign axi_slave_0.AWCACHE = axi_master_0.AWCACHE; 
    assign axi_slave_0.AWPROT = axi_master_0.AWPROT;
    assign axi_slave_0.AWQOS = axi_master_0.AWQOS;
    assign axi_slave_0.AWREGION = axi_master_0.AWREGION;

    assign axi_slave_0.WVALID = axi_master_0.WVALID;
    assign axi_master_0.WREADY = axi_slave_0.WREADY;
    assign axi_slave_0.WDATA = axi_master_0.WDATA;
    assign axi_slave_0.WSTRB = axi_master_0.WSTRB;
    assign axi_slave_0.WLAST = axi_master_0.WLAST;

    assign axi_master_0.BVALID=axi_slave_0.BVALID;
    assign axi_slave_0.BREADY = axi_master_0.BREADY;
    assign axi_master_0.BID = axi_slave_0.BID;
    assign axi_master_0.BRESP = axi_slave_0.BRESP;


    assign axi_slave_0.ARVALID = axi_master_0.ARVALID;
    assign axi_master_0.ARREADY = axi_slave_0.ARREADY;
    assign axi_slave_0.ARID = axi_master_0.ARID;
    assign axi_slave_0.ARADDR = axi_master_0.ARADDR;
    assign axi_slave_0.ARLEN = axi_master_0.ARLEN;
    assign axi_slave_0.ARSIZE = axi_master_0.ARSIZE;
    assign axi_slave_0.ARBURST = axi_master_0.ARBURST;
    assign axi_slave_0.ARLOCK = axi_master_0.ARLOCK;
    assign axi_slave_0.ARCACHE = axi_master_0.ARCACHE;
    assign axi_slave_0.ARPROT = axi_master_0.ARPROT;
    assign axi_slave_0.ARQOS = axi_master_0.ARQOS;
    assign axi_slave_0.ARREGION = axi_master_0.ARREGION;

    assign axi_master_0.RVALID = axi_slave_0.RVALID;
    assign axi_slave_0.RREADY = axi_master_0.RREADY;
    assign axi_master_0.RID = axi_slave_0.RID;
    assign axi_master_0.RDATA = axi_slave_0.RDATA;
    assign axi_master_0.RRESP = axi_slave_0.RRESP;
    assign axi_master_0.RLAST = axi_slave_0.RLAST;

endmodule:axi_top
