class axi_agent extends uvm_agent;

    axi_sequencer sequencer;
    axi_driver driver;
    axi_monitor monitor;

    `uvm_component_utils(axi_agent)

    function new(string name = "axi_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        sequencer = axi_sequencer::type_id::create("sequencer", this);
        driver = axi_driver::type_id::create("driver", this);
        monitor = axi_monitor::type_id::create("monitor", this);
    endfunction

endclass
