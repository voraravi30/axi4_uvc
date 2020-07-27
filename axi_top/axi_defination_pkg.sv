//---------------------------------------------------------------------
//Package: axi_defination_pkg
//Defines all required constants, type defination and useful sub-routine
//---------------------------------------------------------------------
package axi_defination_pkg;

    // AXI transaction address type
    typedef bit [31: 0] axi_addr_t;

    //AXI transaction data type
    typedef bit [31: 0] axi_data_t;

    //AXI transaction data type
    typedef bit [3: 0] axi_wstrb_t;

    //AXI transaction id type for master
    typedef bit [3: 0] axi_mid_t;

    //AXI transaction id type for slave
    typedef bit [3: 0] axi_sid_t;
    
    // AXI transaction burst type
    typedef bit [1: 0] axi_burst_t;
    
    // AXI transaction length type.
    typedef bit [7: 0] axi_length_t;
    
    // AXI transaction size type.
    typedef bit [2: 0] axi_size_t;
    
    // AXI transaction response type.
    typedef bit [1: 0] axi_resp_t;

    //AXI transaction lock type.
    typedef bit axi_lock_type_t;
    
    // AXI transaction memory type.
    typedef bit [3: 0] axi_memory_type_t;
    
    // AXI transaction protection type.
    typedef bit [2: 0] axi_prot_type_t;
    
    // AXI transaction region type.
    typedef bit [3: 0] axi_region_identifier_t;

    //AXI transaction Quality of service type
    typedef bit [3: 0] axi_qos_t;

    //enum: access_type_e
    //
    //represents type of transfer such as read and write transfer.
    //
    typedef enum bit
    {
        AXI_READ = 1'b0,
        AXI_WRITE = 1'b1
    } access_type_e;

    //Enum: axi_burst_e
    //
    //tells which type of transfer is initiated
    //
    //FIXED - fixed burst transfer
    //INCR  - incremental burst transfer
    //WRAP  - wrapping burst transfer
    typedef enum axi_burst_t
    {
        FIXED = 2'b00,
        INCR = 2'b01,
        WRAP = 2'b10
    } axi_burst_e;


    //Enum: axi_size_e
    //
    //represents the size of transfer in each burst transfer.
    typedef enum axi_size_t
    {
        AxSIZE_1_BYTE = 3'b000,
        AxSIZE_2_BYTE = 3'b001,
        AxSIZE_4_BYTE = 3'b010,
        AxSIZE_8_BYTE = 3'b011,
        AxSIZE_16_BYTE = 3'b100,
        AxSIZE_32_BYTE = 3'b101,
        AxSIZE_64_BYTE = 3'b110,
        AxSIZE_128_BYTE = 3'b111
    } axi_size_e;


    //Enum: tr_state_e
    //
    //indicate the state of AXI transaction
    //AXI_CREATED: transaction is created
    //AXI_STOPPED: transaction is ignored due to reset condition
    //AXI_FINISHED: transaction is consumed by the driver
    typedef enum bit [1: 0]
    {
        AXI_CREATED,
        AXI_STOPPED,
        AXI_FINISHED
    } tr_state_e;


    //Enum: axi_resp_e
    //
    //represents the slave response to tranfer
    //
    typedef enum axi_resp_t
    {
        OKAY_RESP,
        EXOKAY_RESP,
        SLVERR_RESP,
        DECERR_RESP
    } axi_resp_e;


    //Enum: channel_name_e
    //
    //resprents the five channels of axi 
    //
    typedef enum bit[2: 0]
    {
        WRITE_ADDR_CH,
        WRITE_DATA_CH,
        WRITE_RESPONSE_CH,
        READ_ADDR_CH,
        READ_DATA_CH
    } channel_name_e;

    //Enum: axi_lock_type_e
    //Lock type. Provides additional information about the atomic characteristics of the transfer.
    //
    typedef enum axi_lock_type_t
    {
        NORMAL_ACCESS = 1'b0,
        EXCLUSIVE_ACCESS = 1'b1
    } axi_lock_type_e;

    //Enum: axi_memory_type_e
    //Memory type. This signal indicates how transactions are required to progress through a system.
    //
    typedef enum axi_memory_type_t
    {
        DEVICE_NONBUFFERABLE,
        DEVICE_BUFFERABLE,
        NORMAL_NONCACHEABLE_NONBUFFERABLE,
        NORMAL_NONCACHEABLE_BUFFERABLE,
        WRITE_THROUGH_NOALLOCATE,
        WRITE_THROUGH_READ_ALLOCATE,
        WRITE_THROUGH_WRITE_ALLOCATE,
        WRITE_THROUGH_READ_AND_WRITE_ALLOCATE,
        WRITE_BACK_NOALLOCATE,
        WRITE_BACK_READ_ALLOCATE,
        WRITE_BACK_WRITE_ALLOCATE,
        WRITE_BACK_READ_AND_WRITE_ALLOCATE
    } axi_memory_type_e;

    //Enum: axi_bufferable_bit_e
    typedef enum bit
    {
        NON_BUFFERABLE = 1'b0,
        BUFFERABLE = 1'b1
    } axi_bufferable_bit_e;

    //Enum: axi_cacheable_bit_e
    typedef enum bit
    {
        NON_CACHEABLE = 1'b0,
        CACHEABLE = 1'b1
    } axi_cacheable_bit_e;

    //Enum: axi_read_allocate_bit_e
    typedef enum bit
    {
        NO_READ_ALLOCATE = 1'b0,
        READ_ALLOCATE = 1'b1
    } axi_read_allocate_bit_e;

    //Enum: axi_write_allocate_bit_e
    typedef enum bit
    {
        NO_WRITE_ALLOCATE = 1'b0,
        WRITE_ALLOCATE = 1'b1
    } axi_write_allocate_bit_e;

    //Enum: prot_type_e
    //Protection type. This signal indicates the privilege and security level of the transaction, 
    //and whether the transaction is a data access or an instruction access. 
    typedef enum axi_prot_type_t
    {
        DATA_SECURE_UNPRIVILEGED_ACCESS,
        DATA_SECURE_PRIVILEGED_ACCESS,
        DATA_NONSECURE_UNPRIVILEGED_ACCESS,
        DATA_NONSECURE_PRIVILEGED_ACCESS,
        INSTRUCTION_SECURE_UNPRIVILEGED_ACCESS,
        INSTRUCTION_SECURE_PRIVILEGED_ACCESS,
        INSTRUCTION_NONSECURE_UNPRIVILEGED_ACCESS,
        INSTRUCTION_NONSECURE_PRIVILEGED_ACCESS
    } axi_prot_type_e;

    //Enum: axi_privileged_access_e
    typedef enum bit
    {
        UNPRIVILEGED_ACCESS,
        PRIVILEGED_ACCESS
    } axi_privileged_access_e;

    //Enum: axi_secure_access_e
    typedef enum bit
    {
        SECURE_ACCESS,
        UNSECURE_ACCESS
    } axi_secure_access_e;

    //Enum: axi_data_instruction_access_e
    typedef enum bit
    {
        DATA_ACCESS,
        INSTRUCTION_ACCESS
    } axi_data_instruction_access_e;

endpackage:axi_defination_pkg
