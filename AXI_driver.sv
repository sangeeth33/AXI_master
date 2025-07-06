class axi_driver extends uvm_driver #(axi_seq_item);
    
    virtual axi_if vif;  // AXI Virtual Interface

    `uvm_component_utils(axi_driver)

    function new(string name = "axi_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal("AXI_DRIVER", "Virtual Interface Not Set!");
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_seq_item req;
        forever begin
            seq_item_port.get_next_item(req);

            vif.awaddr <= req.awaddr;
            vif.awlen <= req.awlen;
            vif.wdata <= req.wdata;
            vif.wstrb <= req.wstrb;
            vif.awvalid <= req.awvalid;
            vif.wvalid <= req.wvalid;

            seq_item_port.item_done();
        end
    endtask

endclass