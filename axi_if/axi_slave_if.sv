interface axi_slave_if(input logic ACLK, logic ARESETn);

    import axi_defination_pkg::*;

    //---------------------------------------------------------
    //AW channel signals
    //---------------------------------------------------------
    logic AWVALID;
    logic AWREADY;
    axi_sid_t AWID;
    axi_addr_t AWADDR;
    axi_length_t AWLEN;
    axi_size_t AWSIZE;
    axi_burst_t AWBURST;
    axi_lock_type_t AWLOCK;
    axi_memory_type_t AWCACHE; 
    axi_prot_type_t AWPROT;
    axi_qos_t AWQOS;
    axi_region_identifier_t AWREGION;

    //---------------------------------------------------------
    //W channel signals
    //---------------------------------------------------------
    logic WVALID;
    logic WREADY;
    axi_data_t WDATA;
    axi_wstrb_t WSTRB;
    logic WLAST;

    //---------------------------------------------------------
    //B channel signals
    //---------------------------------------------------------
    logic BVALID;
    logic BREADY;
    axi_sid_t BID;
    axi_resp_t BRESP;
  
    //---------------------------------------------------------
    //AR channel signals
    //---------------------------------------------------------
    logic ARVALID;
    logic ARREADY;
    axi_sid_t ARID;
    axi_addr_t ARADDR;
    axi_length_t ARLEN;
    axi_size_t ARSIZE;
    axi_burst_t ARBURST;
    axi_lock_type_t ARLOCK;
    axi_memory_type_t ARCACHE;
    axi_prot_type_t ARPROT;
    axi_qos_t ARQOS;
    axi_region_identifier_t ARREGION;

    //---------------------------------------------------------
    //R channel signals
    //---------------------------------------------------------
    logic RVALID;
    logic RREADY;
    axi_sid_t RID;
    axi_data_t RDATA;
    axi_resp_t  RRESP;
    logic RLAST;

    //---------------------------------------------------------
    //clocking block for slave driver
    //---------------------------------------------------------
    clocking sdrv_cb @(posedge ACLK);
        default input #1 output #1;
        input AWVALID;
        output  AWREADY;
        input AWID;
        input AWADDR;
        input AWLEN;
        input AWSIZE;
        input AWBURST;
        input AWLOCK;
        input AWPROT;
        input AWCACHE; 
        input AWREGION;
        input AWQOS;

        input WVALID;
        input WSTRB; 
        input WDATA;
        input WLAST;
        output WREADY;
        
        input BREADY;
        output BID;
        output BRESP;
        output BVALID;

        input ARVALID;
        output ARREADY;
        input ARID;
        input ARADDR;
        input ARLEN;
        input ARSIZE;
        input ARBURST;
        input ARLOCK;
        input ARPROT;
        input ARCACHE; 
        input ARREGION;
        input ARQOS;
        
        input RREADY;
        output RID;
        output RVALID;
        output RDATA;
        output RRESP;
        output RLAST;
    endclocking:sdrv_cb

    //---------------------------------------------------------
    //clocking block for slave monitor
    //---------------------------------------------------------
    clocking smon_cb @(posedge ACLK);
        default input #1 output #1;
        input AWVALID;
        input AWREADY;
        input AWID;
        input AWADDR;
        input AWLEN;
        input AWSIZE;
        input AWBURST;
        input AWLOCK;
        input AWCACHE;
        input AWREGION;
        input AWPROT;
        input AWQOS;

        input WVALID;
        input WREADY;
        input WSTRB; 
        input WDATA;
        input WLAST;
        
        input BVALID;
        input BREADY;
        input BID;
        input BRESP;

        input ARVALID;
        input ARREADY;
        input ARID;
        input ARADDR;
        input ARLEN;
        input ARSIZE;
        input ARBURST;
        input ARLOCK;
        input ARCACHE;
        input ARREGION;
        input ARPROT;
        input ARQOS;
        
        input RVALID;
        input RREADY;
        input RID;
        input RDATA;
        input RRESP;
        input RLAST;
    endclocking:smon_cb

    //---------------------------------------------------------
    //modport for slave driver
    //---------------------------------------------------------
    modport sdrv_mp(clocking sdrv_cb,input ACLK, ARESETn);

    //---------------------------------------------------------
    //modport for slave monitor
    //---------------------------------------------------------
    modport smon_mp(clocking smon_cb,input ACLK, ARESETn);

    //---------------------------------------------------------
    //modport for slave dut
    //---------------------------------------------------------
    modport slave(
        input ACLK,
        input ARESETn,
        input AWVALID,
        output  AWREADY,
        input AWID,
        input AWADDR,
        input AWLEN,
        input AWSIZE,
        input AWBURST,
        input AWLOCK,
        input AWPROT,
        input AWCACHE,
        input AWREGION,

        input WVALID,
        input WSTRB,
        input WDATA,
        input WLAST,
        output WREADY,
        
        input BREADY,
        output BID,
        output BRESP,
        output BVALID,

        input ARVALID,
        output ARREADY,
        input ARID,
        input ARADDR,
        input ARLEN,
        input ARSIZE,
        input ARBURST,
        input ARLOCK,
        input ARPROT,
        input ARCACHE,
        input ARREGION,
        
        input RREADY,
        output RID,
        output RVALID,
        output RDATA,
        output RRESP,
        output RLAST ); 

    //User defined signal... not used
    //logic AWUSER;
    //logic WUSER;
    //logic BUSER;
    //logic ARUSER;
    //logic RUSER;

endinterface:axi_slave_if
