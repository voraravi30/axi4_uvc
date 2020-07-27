//--------------------------------------------------------------------
//Class: axi_master_checks
//performs checking of initiated AXI transaction
//--------------------------------------------------------------------
class axi_master_checks extends uvm_subscriber#(master_seq_item);

    //UVM factory registration macro
    `uvm_component_utils(axi_master_checks)

    //----------------------------------------------------------------
    //Data Members:
    //----------------------------------------------------------------
    master_agent_config cfg;

    //----------------------------------------------------------------
    //Methods:
    //----------------------------------------------------------------
    //Class Constructor Method
    extern function new(string name, uvm_component parent);

    //UVM Standard phase method
    extern function void build_phase(uvm_phase phase);

    //write method
    extern function void write(master_seq_item t);

    //perform checking
    extern function void perform_checking(master_seq_item check_tr);
    extern function void burst_length_check(master_seq_item check_tr);
    extern function void burst_size_check(master_seq_item check_tr);
    extern function void alignment_check(master_seq_item check_tr);

endclass:axi_master_checks


//--------------------------------------------------------------------
//Implementation:
//--------------------------------------------------------------------


//--------------------------------------------------------------------
//Class Constructor Method: new
//--------------------------------------------------------------------
function axi_master_checks::new(string name, uvm_component parent);

    super.new(name, parent);

endfunction


//--------------------------------------------------------------------
//Method: build_phase
//retrive the configuration object
//--------------------------------------------------------------------
function void axi_master_checks::build_phase(uvm_phase phase);
    
    super.build_phase(phase);
    
    //Get the Configuration object from config space.
    if(!uvm_config_db #(master_agent_config)::get(this, "", "master_agent_config", cfg)) begin
        `config_retrival_fatal(cfg);
    end

endfunction:build_phase


//--------------------------------------------------------------------
//Method: write
//--------------------------------------------------------------------
function void axi_master_checks::write(master_seq_item t);

    master_seq_item check_tr;
    if(!$cast(check_tr, t.clone())) begin
        `object_casting_fatal(write)
    end

    perform_checking(check_tr);

endfunction


//--------------------------------------------------------------------
//Method: perform_checking
//enable other checking sub-routines
//--------------------------------------------------------------------
function void axi_master_checks::perform_checking(master_seq_item check_tr);

    if(check_tr.addr_valid && check_tr.burst_type == 2'b11) begin
        `uvm_error("MASTER.CHECKS", "awburst value must not be 2'b11")
    end
    burst_length_check(check_tr);
    burst_size_check(check_tr);
    alignment_check(check_tr);

endfunction:perform_checking


//--------------------------------------------------------------------
//Method: burst_length_check
//checks validness of burst length
//--------------------------------------------------------------------
function void axi_master_checks::burst_length_check(master_seq_item check_tr);

    //transaction burst length check
    if(check_tr.addr_valid) begin

        case(check_tr.burst_type)
            FIXED: begin
                if(!(check_tr.burst_length inside {[0:15]})) begin
                    `uvm_error("MASTER.CHECKS", "for FIXED burst transfer, burst length must be from 1 to 16")
                end
            end
            INCR: begin
                if(check_tr.lock_type && !(check_tr.burst_length inside {[0:15]})) begin
                    `uvm_error("MASTER.CHECKS", "for exclusive access, INCR burst length must be from 1 to 16")
                end
            end
            WRAP: begin
                if(!(check_tr.burst_length inside {1, 3, 7, 15})) begin
                    `uvm_error("MASTER.CHECKS", "for WRAP burst_transfer, burst length must be 2, 4, 8 or 16")
                end
            end
        endcase

    end

endfunction:burst_length_check


//--------------------------------------------------------------------
//Method: burst_size_check
//checks validness of burst size value
//--------------------------------------------------------------------
function void axi_master_checks::burst_size_check(master_seq_item check_tr);

    //transaction burst size check
    if(check_tr.addr_valid) begin
        if((2**check_tr.burst_size) > cfg.data_bus_bytes) begin
            `uvm_error("MASTER.CHECKS", "size of any transfer must not exceed the data bus size of agent")
        end
    end

endfunction:burst_size_check


//--------------------------------------------------------------------
//Method: alignment_check
//check validness of start address for alignment
//--------------------------------------------------------------------
function void axi_master_checks::alignment_check(master_seq_item check_tr);

    bit [`ADDR_BUS_WIDTH-1: 0] aligned_addr;

    //transaction address alignment check
    if(check_tr.addr_valid) begin
        if(check_tr.lock_type) begin
            aligned_addr = ((check_tr.start_addr/((2**check_tr.burst_size)*(check_tr.burst_length+1)))*((2**check_tr.burst_size)*(check_tr.burst_length+1)));
            if(check_tr.start_addr != aligned_addr) begin
                `uvm_error("MASTER.CHECKS", "for exclusive access, start address must be aligned to number of bytes in a transaction")
            end
        end
        else begin
            aligned_addr = ((check_tr.start_addr/(2**check_tr.burst_size)) * (2**check_tr.burst_size));
            if(check_tr.start_addr != aligned_addr && check_tr.burst_type == WRAP) begin
                `uvm_error("MASTER.CHECKS", "for WRAP burst, start address must be aligned to number of bytes in each transfer")
            end
        end
    end

endfunction:alignment_check
