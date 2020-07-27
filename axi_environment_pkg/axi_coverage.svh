//-------------------------------------------------------------------
//Class: axi_coverage
//defines the covergroups
//-------------------------------------------------------------------
class axi_coverage extends uvm_subscriber#(master_seq_item);

    //UVM factory registration
    `uvm_component_utils(axi_coverage)

    //---------------------------------------------------------------
    //Data members:
    //---------------------------------------------------------------
    //master configuration object handle
    master_agent_config cfg;

    //axi master tranaction handle
    master_seq_item item;

    //Class Constructor Method:
    extern function new(string name, uvm_component parent);
    
    //UVM Standard Phase Methods:
    extern function void build_phase(uvm_phase phase);

    //write method
    extern function void write(master_seq_item t);

    //---------------------------------------------------------------
    //Covergroup:
    //---------------------------------------------------------------
    //write address channel coverage specification
    covergroup write_addr_ch_cov (ref master_seq_item item);

        option.per_instance = 1;
        option.comment = "write address channel coverage";

        //write address id coverpoint
        awid: coverpoint item.trans_id iff(item.access_type == AXI_WRITE)
        {
            //all possible values to be covered
            bins awid_bin[] = {[0: $]};
            //next transaction has same id of previous transaction
            bins awid_order_bin[] = ([0: $][*2]);
        }

        //write transaction length
        //for fixed burst
        awlen_fixed: coverpoint item.burst_length iff(item.burst_type == FIXED && item.access_type == AXI_WRITE)
        {
            bins awlen_fixed_bin[] = {[0: 15]};
        }
        //for incr burst
        awlen_incr: coverpoint item.burst_length iff(item.burst_type == INCR && item.access_type == AXI_WRITE)
        {
            bins awlen_incr_bin[] = {[0: $]};
        }
        //for wrap burst
        awlen_wrap: coverpoint item.burst_length iff(item.burst_type == WRAP && item.access_type == AXI_WRITE)
        {
            bins awlen_wrap_bin[] = {1, 3, 8, 15};
        }

        //write burst type
        awburst: coverpoint item.burst_type iff(item.access_type == AXI_WRITE)
        {
            bins fixed_bin = {FIXED};
            bins incr_bin = {INCR};
            bins wrap_bin = {WRAP};
            illegal_bins reserved_bin = {2'b11};
        }

        //write burst size
        awsize: coverpoint item.burst_size iff(item.access_type == AXI_WRITE)
        {
            bins awsize_bin[] = {[0: $clog2(`DATA_BUS_BYTES)]};
        }

        //write lock type
        awlock: coverpoint item.lock_type iff(item.access_type == AXI_WRITE)
        {
            bins normal_access_bin = {NORMAL_ACCESS};
            bins exclusive_access_bin = {EXCLUSIVE_ACCESS};
        }

        //cross between awburst and awsize
        awburstXawsize: cross awburst, awsize;

        //cross between awburst and awlock
        awburstXawlock: cross awburst, awlock iff(item.access_type == AXI_WRITE);

    endgroup

    //write data channel coverage specification
    covergroup write_data_ch_cov(ref master_seq_item item);

        option.per_instance = 1;
        option.comment = "write data channel coverage";

        //write last
        wlast: coverpoint item.write_last
        {
            bins wlast_bin[] = {[0: $]};
            bins wlast_trans_bin = (0 => 1);
        }

    endgroup

    //write response channel coverage specification
    covergroup write_resp_ch_cov(ref master_seq_item item);

        option.per_instance = 1;
        option.comment = "write response channel coverage";

        //write response id
        bid: coverpoint item.write_response_id
        {
            bins bid_bin[] = {[0: $]};
            bins bid_order_bin[] = ([0: $][*2]);
        }

        //write response
        bresp: coverpoint item.write_response
        {
            bins write_okay_bin = {OKAY_RESP};
            bins write_EXOKAY_bin = {EXOKAY_RESP};
            bins write_SLVERR_bin = {SLVERR_RESP};
            bins write_DECERR_bin = {DECERR_RESP};
        }

    endgroup

    //read address channel coverage specification
    covergroup read_addr_ch_cov(ref master_seq_item item);

        option.per_instance = 1;
        option.comment = "read address channel coverage";

        //write address id coverpoint
        arid: coverpoint item.trans_id iff(item.access_type == AXI_READ)
        {
            //all possible values to be covered
            bins arid_bin[] = {[0: $]};
            //next transaction has same id of previous transaction
            bins arid_order_bin[] = ([0: $][*2]);
        }

        //read transaction length
        //for read burst
        arlen_fixed: coverpoint item.burst_length iff(item.burst_type == FIXED && item.access_type == AXI_READ)
        {
            bins arlen_fixed_bin[] = {[0: 15]};
        }
        //for incr burst
        arlen_incr: coverpoint item.burst_length iff(item.burst_type == INCR && item.access_type == AXI_READ)
        {
            bins arlen_incr_bin[] = {[0: $]};
        }
        //for wrap burst
        arlen_wrap: coverpoint item.burst_length iff(item.burst_type == WRAP && item.access_type == AXI_READ)
        {
            bins arlen_wrap_bin[] = {1, 3, 8, 15};
        }

        //read burst type
        arburst: coverpoint item.burst_type iff(item.access_type == AXI_READ)
        {
            bins fixed_bin = {FIXED};
            bins incr_bin = {INCR};
            bins wrap_bin = {WRAP};
            illegal_bins reserved_bin = {2'b11};
        }

        //read burst size
        arsize: coverpoint item.burst_size iff(item.access_type == AXI_READ)
        {
            bins arsize_bin[] = {[0: $clog2(`DATA_BUS_BYTES)]};
        }

        //read lock type
        arlock: coverpoint item.lock_type iff(item.access_type == AXI_READ)
        {
            bins normal_access_bin = {NORMAL_ACCESS};
            bins exclusive_access_bin = {EXCLUSIVE_ACCESS};
        }

        //cross between arburst and arsize
        arburstXarsize: cross arburst, arsize iff(item.access_type == AXI_READ);

        //cross between arburst and arlock
        arburstXarlock: cross arburst, arlock iff(item.access_type == AXI_READ);

    endgroup

    //read data channel coverage specification
    covergroup read_data_ch_cov(ref master_seq_item item);

        option.per_instance = 1;
        option.comment = "read data channel coverage";

        //read last
        rlast: coverpoint item.read_last
        {
            bins rlast_bin[] = {[0: $]};
            bins rlast_trans_bin = (0 => 1);
        }

        //read id
        rid: coverpoint item.read_id_q[0]
        {
            bins rid_bin[] = {[0: $]};
            bins rid_order_bin[] = ([0: $][*2]);
        }

        //read response
        rresp: coverpoint item.read_response_q[0]
        {
            bins read_okay_bin = {OKAY_RESP};
            bins read_EXOKAY_bin = {EXOKAY_RESP};
            bins read_SLVERR_bin = {SLVERR_RESP};
            bins read_DECERR_bin = {DECERR_RESP};
        }
    endgroup

    //reset coverage specification
    covergroup reset_cov(ref master_seq_item item);
    endgroup

endclass:axi_coverage

//-------------------------------------------------------------------
//IMPLEMENTATION
//-------------------------------------------------------------------

//-------------------------------------------------------------------
//Class Constructor Method: new
//-------------------------------------------------------------------
function axi_coverage::new(string name, uvm_component parent);

    super.new(name, parent);
    
    //create covergroup instance
    write_addr_ch_cov = new(item);
    write_data_ch_cov = new(item);
    write_resp_ch_cov = new(item);
    read_addr_ch_cov = new(item);
    read_data_ch_cov = new(item);
    reset_cov = new(item);

endfunction:new


//-------------------------------------------------------------------
//Method: buid_phase
//create analyis export
//-------------------------------------------------------------------
function void axi_coverage::build_phase(uvm_phase phase);

    super.build_phase(phase);

    //get the configuration object from confgi space:
    if(!uvm_config_db #(master_agent_config)::get(this, "", "master_agent_config", cfg)) begin
        `config_retrival_fatal(cfg)
    end

endfunction:build_phase


//-------------------------------------------------------------------
//Method: write
//provide write method Implementation for analysis_imp
//-------------------------------------------------------------------
function void axi_coverage::write(master_seq_item t);

    if(!$cast(item, t.clone())) begin
        `object_casting_fatal(write)
    end

    if(!item.reset_detected) begin
        if(item.addr_valid && item.addr_ready && item.access_type == AXI_WRITE) begin
            write_addr_ch_cov.sample();
        end
        if(item.write_valid && item.write_ready) begin
            write_data_ch_cov.sample();
        end
        if(item.write_response_valid && item.write_response_ready) begin
            write_resp_ch_cov.sample();
        end
        if(item.addr_valid && item.addr_ready && item.access_type == AXI_READ) begin
            read_addr_ch_cov.sample();
        end
        if(item.read_valid && item.read_ready) begin
            read_data_ch_cov.sample();
        end
    end
    reset_cov.sample();

endfunction:write
