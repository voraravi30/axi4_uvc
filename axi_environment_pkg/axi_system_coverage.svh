//-------------------------------------------------------------------
//Class: axi_system_coverage
//coverage component has coverage collector component for each masters in
//a system.
//-------------------------------------------------------------------
class axi_system_coverage extends uvm_component;

    //UVM factory registration
    `uvm_component_utils(axi_system_coverage)

    //---------------------------------------------------------------
    //Data members:
    //---------------------------------------------------------------
    //coverage instance per axi master in a system
    axi_coverage axi_cov[];

    //export for connection to master agent analysis port
    uvm_analysis_export  #(master_seq_item)  cover_export[];

    //axi environment configuration object handle
    axi_env_config cfg;
  
    //Class Constructor Method:
    extern function new(string name, uvm_component parent);
    
    //UVM Standard Phase Methods:
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern function void report_phase(uvm_phase phase);

endclass:axi_system_coverage


//-------------------------------------------------------------------
//IMPLEMENTATION
//-------------------------------------------------------------------

//-------------------------------------------------------------------
//Class Constructor Method: new
//-------------------------------------------------------------------
function axi_system_coverage::new(string name, uvm_component parent);

    super.new(name, parent);

endfunction:new

//-------------------------------------------------------------------
//Method: buid_phase
//create coverage instance for each axi master in a system and analyis export
//-------------------------------------------------------------------
function void axi_system_coverage::build_phase(uvm_phase phase);

    string name;

    super.build_phase(phase);

    //Get the AXI Environment Configuration from Configuration space.
    if(!uvm_config_db #(axi_env_config)::get(this, "", "axi_env_config", cfg)) begin
        `config_retrival_fatal(cfg)
    end

    //create analysis export for input stimuls transaction
    cover_export  = new[cfg.num_of_master];
    for(int num=0; num<cfg.num_of_master; num++) begin
        $sformat(name, "cover_export[%0d]", num);
        cover_export[num] = new(name, this);
    end
    
    //create coverage instance for each axi master in a system
    axi_cov = new[cfg.num_of_master];
    for(int num=0; num<cfg.num_of_master; num++) begin
        $sformat(name, "axi_cov[%0d]", num);
        uvm_config_db #(master_agent_config)::set(this, name, "master_agent_config", cfg.master_cfg[num]);
        axi_cov[num] = axi_coverage::type_id::create(name, this);
    end

endfunction:build_phase

//-------------------------------------------------------------------
//Method: connect_phase
//-------------------------------------------------------------------
function void axi_system_coverage::connect_phase(uvm_phase phase);

    //connect each cover_export to corresponding cover_imp of coverage
    //collector component
    foreach(cover_export[num]) begin
        cover_export[num].connect(axi_cov[num].analysis_export);
    end

endfunction:connect_phase

//-------------------------------------------------------------------
//Method: report phase
//-------------------------------------------------------------------
function void axi_system_coverage::report_phase(uvm_phase phase);

    string s;

    //print the percentage of coverage collected
    s = "\n\t\t-------------------------------------------------\n\t\tcoverage report information:\n";
    foreach(axi_cov[num]) begin
      //  s = {s, $sformatf("\n\t\t\tAXI MASTER [%0d] Coverage: %0f", num, axi_cov[num].get_inst_coverage())};
    end
    s = {s, "\n\t\t-------------------------------------------------"};

    uvm_report_info("COVER_REPORT", s, UVM_NONE);

endfunction:report_phase
