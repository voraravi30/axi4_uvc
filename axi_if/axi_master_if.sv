interface axi_master_if(input logic ACLK, logic ARESETn);

    import axi_defination_pkg::*;

    //---------------------------------------------------------
    //AW channel signals
    //---------------------------------------------------------
    logic AWVALID;
    logic AWREADY;
    axi_mid_t AWID;
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
    axi_mid_t BID;
    axi_resp_t BRESP;
  
    //---------------------------------------------------------
    //AR channel signals
    //---------------------------------------------------------
    logic ARVALID;
    logic ARREADY;
    axi_mid_t ARID;
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
    axi_mid_t RID;
    axi_data_t RDATA;
    axi_resp_t  RRESP;
    logic RLAST;

    //---------------------------------------------------------
    //clocking block for master driver
    //---------------------------------------------------------
    clocking mdrv_cb @(posedge ACLK);
        default input #1 output #1;
        output AWVALID;
        input  AWREADY;
        output AWID;
        output AWADDR;
        output AWLEN;
        output AWSIZE;
        output AWBURST;
        output AWLOCK;
        output AWPROT;
        output AWCACHE; 
        output AWREGION;
        output AWQOS;

        output WVALID;
        output WSTRB; 
        output WDATA;
        output WLAST;
        input  WREADY;
        
        output BREADY;
        input  BID;
        input  BRESP;
        input  BVALID;

        output ARVALID;
        input  ARREADY;
        output ARID;
        output ARADDR;
        output ARLEN;
        output ARSIZE;
        output ARBURST;
        output ARLOCK;
        output ARPROT;
        output ARCACHE; 
        output ARREGION;
        output ARQOS;
        
        input  RID;
        input  RVALID;
        input  RDATA;
        input  RRESP;
        input  RLAST;
        output RREADY;
    endclocking:mdrv_cb

    //---------------------------------------------------------
    //clocking block for master monitor 
    //---------------------------------------------------------
    clocking mmon_cb @(posedge ACLK);
        default input #1 output #1;
        input AWVALID;
        input  AWREADY;
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
        input WREADY;
        
        input BREADY;
        input BID;
        input BRESP;
        input BVALID;

        input ARVALID;
        input ARREADY;
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

        
        input RID;
        input RVALID;
        input RDATA;
        input RRESP;
        input RREADY;
        input RLAST;
    endclocking:mmon_cb

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
    //modport for master driver
    //---------------------------------------------------------
    modport mdrv_mp(clocking mdrv_cb,input ACLK, ARESETn);

    //---------------------------------------------------------
    //modport for master monitor
    //---------------------------------------------------------
    modport mmon_mp(clocking mmon_cb,input ACLK, ARESETn);

    //---------------------------------------------------------
    //modport for master dut
    //---------------------------------------------------------
    modport master(
        input ACLK,
        input ARESETn,
        output AWVALID,
        input  AWREADY,
        output AWID,
        output AWADDR,
        output AWLEN,
        output AWSIZE,
        output AWBURST,
        output AWLOCK,
        output AWPROT,
        output AWCACHE,
        output AWREGION,

        output WVALID,
        output WSTRB,
        output WDATA,
        output WLAST,
        input  WREADY,
        
        output BREADY,
        input  BID,
        input  BRESP,
        input  BVALID,

        output ARVALID,
        input  ARREADY,
        output ARID,
        output ARADDR,
        output ARLEN,
        output ARSIZE,
        output ARBURST,
        output ARLOCK,
        output ARPROT,
        output ARCACHE,
        output ARREGION,

        input  RID,
        input  RVALID,
        input  RDATA,
        input  RRESP,
        input  RLAST,
        output RREADY );

    //User defined signal... not used
    //logic AWUSER;
    //logic WUSER;
    //logic BUSER;
    //logic ARUSER;
    //logic RUSER;

endinterface:axi_master_if
