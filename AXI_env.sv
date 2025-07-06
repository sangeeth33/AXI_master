class axi_env extends uvm_env;

    axi_agent agent;
    axi_scoreboard scoreboard;

    `uvm_component_utils(axi_env)

    function new(string name = "axi_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        agent = axi_agent::type_id::create("agent", this);
        scoreboard = axi_scoreboard::type_id::create("scoreboard", this);
    endfunction

endclass