//--------------------------------------------------------------------
//--------------------------------------------------------------------
`define HIGH 1'b1
`define LOW 1'b0


//--------------------------------------------------------------------
//macro used to give fatal report, when object casting error occurs
//--------------------------------------------------------------------
`define object_casting_fatal(BY_METHOD) \
    `uvm_fatal("CASTING_ERROR", {"casting fails at: ", get_full_name(), `" in BY_METHOD  method call`"})

//--------------------------------------------------------------------
//macro used to give fatal report, when virtual interface is null
//--------------------------------------------------------------------
`define vif_null_fatal(VIF_NAME) \
    `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), `".VIF_NAME`"})

//--------------------------------------------------------------------
//macro used to give fatal report, when retriavl of configuration object from 
//resource database fails using method of uvm_config_db or uvm_resource_db
//--------------------------------------------------------------------
`define config_retrival_fatal(CONFIG_OBJECT_NAME) \
    `uvm_fatal("NOCFG", {"configuration object must be set for: ", get_full_name(), `".CONFIG_OBJECT_NAME`"})
