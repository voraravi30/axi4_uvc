//------------------------------------------------------------------------
//Class: axi_master_read_seq
//Sequence API that used to initiate various types of read transfer
//------------------------------------------------------------------------
`ifndef AXI_MASTER_READ_SEQ
`define AXI_MASTER_READ_SEQ
class axi_master_read_seq extends axi_master_base_seq;

    //UVM factory registration macro
    `uvm_object_utils(axi_master_read_seq)

    //--------------------------------------------------------------------
    //Data Members:
    //--------------------------------------------------------------------
    bit [7: 0] read_data_q[$];
    axi_sid_t read_id_q[$];
    axi_resp_e read_response_q[$];
    protected int m_count = 0;    //To ensure that the sequence does not complete too early 

    //--------------------------------------------------------------------
    //Constraints:
    //--------------------------------------------------------------------
    //constraint the transfer type to write
    constraint read_tr {access_type == AXI_READ;}

    //--------------------------------------------------------------------
    //Method prototypes:
    //--------------------------------------------------------------------
    //Class Constructor method:
    extern function new(string name = "read_seq");

    //body method:
    extern task body();

    //response_handler method 
    extern function void response_handler(uvm_sequence_item response);

endclass:axi_master_read_seq



//------------------------------------------------------------------------
//Implementation
//------------------------------------------------------------------------
//
//
//------------------------------------------------------------------------
//Class constructor method
//------------------------------------------------------------------------
function axi_master_read_seq::new(string name = "read_seq");

    super.new(name);

endfunction:new

task axi_master_read_seq::body();

    m_count = 0;

    use_response_handler(1);    //response sent from driver will be handled using seprate thread response_handler method

    if(!uvm_config_db#(master_agent_config)::get(null, get_full_name(), "master_agent_config", cfg)) begin
        `uvm_fatal("NOCFG", {"configuration object must be set for: ", get_full_name(), ".cfg"})
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
                           }) begin
        `uvm_fatal("RANDOMIZATION_FAILS",{"randomization fails in: ", get_full_name()})
    end
    finish_item(req);

    //Do not end the sequence until the last req item is complete
    wait(m_count == 1);

endtask:body
//------------------------------------------------------------------------
//Method: response_handler
//------------------------------------------------------------------------
function void axi_master_read_seq::response_handler(uvm_sequence_item response);
    master_seq_item req;
    if(!$cast(req, response)) begin
        `object_casting_fatal(response_handler)
    end
    
    //read response is captured in local variables of this sequence
    foreach(req.read_data_q[index]) begin
        this.read_data_q.push_back(req.read_data_q[index]);
    end
    foreach(req.read_id_q[index]) begin
        this.read_id_q.push_back(req.read_id_q[index]);
        this.read_response_q.push_back(req.read_response_q[index]);
    end

    `uvm_info("MASTER.READ_SEQ", $sformatf("\n------------------------------------------------------\nGET RESPONSE FOR: m_sequence_id: 0x%0x\nthat has start_addr: 0x%0x and trans_id: 0x%0x\nRESPONSE is:\ntransfer_state: %0s\n------------------------------------------------------\n", req.get_sequence_id(), req.start_addr, req.trans_id, req.get_tr_state()), UVM_LOW)

    if(req.get_tr_state() == AXI_FINISHED) begin
        foreach(req.read_id_q[index]) begin
            if(req.trans_id != this.read_id_q[index]) begin
                `uvm_error("UNMATCHED_READ_ID", $sformatf("unmatched read_id: 0x%0h for 0x%0h nth read response with read_addr_id: 0x%0h", req.read_id_q[index], index+1, req.trans_id))
            end
        end
    end

    if(read_data_q.size() != req.burst_length+1) begin
        `uvm_error("READ_DATA_SIZE_ERR", $sformatf("expected read_data_q size is: 0x%0h, actual received is: 0x%0h",  req.burst_length+1, read_data_q.size()))
    end

    if((req.burst_length+1) != read_id_q.size()) begin
        `uvm_error("READ_LENGTH_ERR", $sformatf("expected read_id_q size is: 0x%0h, actual received is: 0x%0h", (req.burst_length+1), read_id_q.size()))
    end
    m_count++;

endfunction:response_handler
`endif
