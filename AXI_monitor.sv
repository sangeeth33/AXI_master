class axi_monitor extends uvm_monitor;

    virtual axi_if vif;  // Virtual Interface
    uvm_analysis_port #(axi_seq_item) mon_ap;

    `uvm_component_utils(axi_monitor)

    function new(string name = "axi_monitor", uvm_component parent);
        super.new(name, parent);
        mon_ap = new("mon_ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal("AXI_MONITOR", "Virtual Interface Not Set!");
    endfunction

    // ** Reset Verification **
    always @(negedge rst_n) begin
        `uvm_info("AXI_MONITOR", "Reset Asserted: Checking Default Values...", UVM_LOW);

        if (vif.awaddr !== 0 || vif.awlen !== 0 || vif.wvalid !== 0) begin
            `uvm_error("AXI_MONITOR", "Reset failure: Signals not cleared!");
        end
    end

    // ** Reset Release Verification (Detect Glitches) **
    always @(posedge rst_n) begin
        `uvm_info("AXI_MONITOR", "Reset Released: Verifying Signal Stability...", UVM_LOW);

        repeat(5) begin  // Observe next few cycles after reset
            #10;
            if (vif.awvalid !== 0 || vif.wvalid !== 0) begin
                `uvm_warning("AXI_MONITOR", "Possible Reset Glitch Detected!");
            end
        end
    end

    virtual task run_phase(uvm_phase phase);
        axi_seq_item tr;
        tr = axi_seq_item::type_id::create("tr");

        forever begin
            tr.awaddr = vif.awaddr;
            tr.awlen = vif.awlen;
            tr.wdata = vif.wdata;
            tr.wstrb = vif.wstrb;
            tr.awvalid = vif.awvalid;
            tr.wvalid = vif.wvalid;

            mon_ap.write(tr);
        end
    endtask

endclass