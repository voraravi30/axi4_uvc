//------------------------------------------------------------------------
//Class: axi_slave_base_seq
//All slave sequence derived from this base sequence 
//------------------------------------------------------------------------
class axi_slave_base_seq extends uvm_sequence #(slave_seq_item);

    //UVM factory registration
    `uvm_object_utils(axi_slave_base_seq)

    //--------------------------------------------------------------------
    //Data Members:
    //--------------------------------------------------------------------
    //declare p_sequencer of axi_slave_sequencer type
    `uvm_declare_p_sequencer(axi_slave_sequencer);

    bit wrapped;
    int lower_byte_lane;
    int upper_byte_lane;

    //slave configuration handle
    slave_agent_config cfg;

    //--------------------------------------------------------------------
    //Methods:
    //--------------------------------------------------------------------
    //Class Constructor Method:
    extern function new(string name = "slave_base_seq");

    //calculate next transfer address
    extern virtual function axi_addr_t address_n(int nth_transfer, data_bus_bytes, axi_addr_t start_addr, axi_length_t length, axi_size_e burst_size, axi_burst_e burst_type, ref bit wrapped, output int lower_byte_lane, upper_byte_lane);

    //calculate valid byte lane
    extern function void find_valid_byte_lane(int data_bus_bytes, axi_wstrb_t wstrb, output int lower_byte_lane, upper_byte_lane);

endclass:axi_slave_base_seq


//--------------------------------------------------------------------
//Implementation:
//--------------------------------------------------------------------


//--------------------------------------------------------------------
//Class Constructor Method: new
//--------------------------------------------------------------------
function axi_slave_base_seq::new(string name = "slave_base_seq");

    super.new(name);

endfunction:new



//----------------------------------------------------------------------------
//Method: address_n
//----------------------------------------------------------------------------
function axi_addr_t axi_slave_base_seq::address_n(int nth_transfer, data_bus_bytes, axi_addr_t start_addr, axi_length_t length, axi_size_e burst_size, axi_burst_e burst_type, ref bit wrapped, output int lower_byte_lane, upper_byte_lane);

    bit [8: 0] burst_length = length + 1'b1;
    bit [7: 0] number_bytes = 2**burst_size;
    axi_addr_t aligned_addr = (((start_addr/number_bytes))*(number_bytes));
    axi_addr_t lower_wrap_boundary = ((start_addr/(number_bytes*burst_length))*(number_bytes*burst_length));
    axi_addr_t upper_wrap_boundary = (lower_wrap_boundary + (number_bytes*burst_length));

    //address_n calculation
    case(burst_type)
        2'b00: address_n = start_addr;    //fixed burst type

        2'b01: begin    //incr burst type
            if(nth_transfer == 0)begin
                address_n = start_addr;
            end
            else begin
                address_n = aligned_addr + (nth_transfer*number_bytes);
            end
        end
        
        2'b10: begin    //wrap burst type
            
            if(nth_transfer == 0) begin
                address_n = start_addr;
            end
            else begin

                if(!wrapped) begin
                    address_n = aligned_addr + (nth_transfer*number_bytes);
                    if(address_n >= upper_wrap_boundary) begin
                        wrapped = 1'b1;
                        address_n = lower_wrap_boundary;
                    end
                end
                else begin
                    address_n = start_addr + (nth_transfer*number_bytes) - (number_bytes * burst_length);
                    if(address_n >= upper_wrap_boundary) begin
                        address_n = lower_wrap_boundary;
                    end
                end
            end
        end

        default: begin
            `uvm_error("BURST_TYPE_ERROR", {"unsupported burst type encounterd by: ", get_full_name(), "in address_n() method"})
        end
    endcase

        if(nth_transfer == length) begin
            wrapped = 0;
        end

        //strobe calculation
        case(burst_type)
            2'b00: begin
                lower_byte_lane =  address_n - (address_n/data_bus_bytes)*data_bus_bytes;
                upper_byte_lane = aligned_addr + (number_bytes - 1) - ((start_addr/data_bus_bytes)*data_bus_bytes);
            end

            2'b01, 2'b10: begin
                if(nth_transfer == 0) begin
                    lower_byte_lane =  address_n - (address_n/data_bus_bytes)*data_bus_bytes;
                    upper_byte_lane = aligned_addr + (number_bytes - 1) - ((start_addr/data_bus_bytes)*data_bus_bytes);
                end
                else begin
                    lower_byte_lane =  address_n - (address_n/data_bus_bytes)*data_bus_bytes;
                    upper_byte_lane = lower_byte_lane + number_bytes -1;
                end
            end
        endcase

endfunction:address_n


//----------------------------------------------------------------
//Method: find_valid_byte_lane
//----------------------------------------------------------------
function void axi_slave_base_seq::find_valid_byte_lane(int data_bus_bytes, axi_wstrb_t wstrb, output int lower_byte_lane, upper_byte_lane);

    //lower valid lane
    for(int lane=0; lane<data_bus_bytes;lane++) begin
        if(wstrb[lane] == 1'b1) begin
            lower_byte_lane = lane;
            break;
        end
    end
    //upper valid lane
    for(int lane=lower_byte_lane; lane<data_bus_bytes;lane++) begin
        if(wstrb[lane] == 1'b0) begin
            upper_byte_lane = lane - 1;
            return;
        end
    end

    upper_byte_lane = data_bus_bytes - 1;

endfunction:find_valid_byte_lane
