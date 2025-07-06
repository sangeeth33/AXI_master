class base_test extends uvm_test;

    `uvm_component_utils(base_test)

    axi_env env;  // Environment Instance

    function new(string name = "base_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        env = axi_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_sequence seq;
        seq = axi_sequence::type_id::create("seq");

        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass