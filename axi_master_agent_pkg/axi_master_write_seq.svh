//------------------------------------------------------------------------
//Class: axi_master_write_seq
//Sequence API that used to initiate various types of write transfer
//------------------------------------------------------------------------
`ifndef AXI_MASTER_WRITE_SEQ
`define AXI_MASTER_WRITE_SEQ
class axi_master_write_seq extends axi_master_base_seq;

    //UVM factory registration macro
    `uvm_object_utils(axi_master_write_seq)

    //--------------------------------------------------------------------
    //Data Members:
    //--------------------------------------------------------------------
    rand axi_data_t data_q[$];
    axi_resp_e write_response;
    axi_mid_t write_response_id;
    protected int m_count=0;   //To ensure that the sequence does not complete too early 

    //--------------------------------------------------------------------
    //Constraints:
    //--------------------------------------------------------------------
    //constraint data size
    constraint data_q_size_con {data_q.size() == burst_length + 1'b1;}

    //constraint the transfer type to write
    constraint write_tr {access_type == AXI_WRITE;}
    //--------------------------------------------------------------------
    //Method prototypes:
    //--------------------------------------------------------------------
    //Class Constructor method:
    extern function new(string name = "write_seq");

    //body method:
    extern task body();

    //response_handler method 
    extern function void response_handler(uvm_sequence_item response);

endclass:axi_master_write_seq


//------------------------------------------------------------------------
//Implementation
//------------------------------------------------------------------------
//
//
//------------------------------------------------------------------------
//Class constructor method: new
//------------------------------------------------------------------------
function axi_master_write_seq::new(string name = "write_seq");

    super.new(name);

endfunction:new


//------------------------------------------------------------------------
//Method: body
//------------------------------------------------------------------------
task axi_master_write_seq::body();

    m_count = 0;

    use_response_handler(1);    //response sent from driver will be handled using seprate thread response_handler method
    
    if(!uvm_config_db#(master_agent_config)::get(null, get_full_name(), "master_agent_config", cfg)) begin
        `uvm_fatal("NOCFG", {"configuration handle must be set for: ", get_full_name(), ".cfg"})
    end
    
    //wait until reset end
    cfg.wait_for_reset_end();

    //create request object
    req = master_seq_item::type_id::create("req");

    //execute req item on m_sequencer
    start_item(req);
    if(!req.randomize() with { access_type == local::access_type;
                               start_addr == local::start_addr;
                               trans_id == local::trans_id;
                               burst_type == local::burst_type;
                               burst_size == local::burst_size;
                               burst_length == local::burst_length;
                               lock_type == local::lock_type;
                               prot_type == {local::data_instruction_access_bit, local::secure_access_bit, local::privileged_access_bit};
                               memory_type == {local::write_allocate_bit,local::read_allocate_bit,local::cacheable_bit,local::bufferable_bit};
                               foreach(data_q[index]) { write_data_q[index] == local::data_q[index];}
                           }) begin
        `uvm_fatal("RANDOMIZATION_FAILS", {"randomization fails in: ", get_full_name()})
    end
    finish_item(req);

    //Do not end the sequence until the last req item is complete
    wait(m_count == 1);

endtask:body


//------------------------------------------------------------------------
//Method: response_handler
//------------------------------------------------------------------------
function void axi_master_write_seq::response_handler(uvm_sequence_item response);
    
    master_seq_item req;
    
    if(!$cast(req, response)) begin
        `object_casting_fatal(response_handler)
    end

    write_response = req.write_response;
    write_response_id = req.write_response_id;

    `uvm_info("MASTER.WRITE_SEQ", $sformatf("\n------------------------------------------------------\nGET RESPONSE FOR: m_sequence_id: 0x%0x\nthat has start_addr: 0x%0x and trans_id: 0x%0x\nRESPONSE is:\ntransfer_state: %0s\nwrite_response_id 0x%0x\nwrite_response: %0s\n------------------------------------------------------\n", req.get_sequence_id(), req.start_addr, req.trans_id, req.get_tr_state(), req.write_response_id, req.write_response.name()), UVM_LOW)

    if(req.trans_id != write_response_id && req.get_tr_state() == AXI_FINISHED) begin
        `uvm_error("UNMATCHED_WRITE_RESPONSE_ID", $sformatf("unmatched write_response_id: 0x%0h with write_addr_id: 0x%0h", req.write_response_id, req.trans_id))
    end

    m_count++;

endfunction:response_handler
`endif
