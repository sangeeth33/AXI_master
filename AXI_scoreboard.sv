class axi_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp #(axi_seq_item, axi_scoreboard) sb_imp;
    bit reset_active;

    `uvm_component_utils(axi_scoreboard)

    function new(string name = "axi_scoreboard", uvm_component parent);
        super.new(name, parent);
        sb_imp = new("sb_imp", this);
    endfunction

    // ** Clear Transaction History During Reset **
    function void clear_transaction_history();
        transaction_queue.delete();
        reset_active = 1'b1;
    endfunction

    // ** Reset Assertion Handling **
    always @(negedge rst_n) begin
        `uvm_info("AXI_SCOREBOARD", "Reset Asserted: Clearing Transaction History...", UVM_LOW);
        clear_transaction_history();
    end

    // ** Reset Release Handling (Check if state returns to expected normal values) **
    always @(posedge rst_n) begin
        `uvm_info("AXI_SCOREBOARD", "Reset Released: Checking Recovery...", UVM_LOW);
        reset_active = 1'b0;
    end

    virtual function void write(axi_seq_item tr);
        if (!reset_active && tr.wdata != expected_data(tr.awaddr)) begin
            `uvm_error("AXI_SCOREBOARD", $sformatf("Post-reset mismatch: Addr %h, Data %h vs Expected %h", tr.awaddr, tr.wdata, expected_data(tr.awaddr)));
        end
    endfunction

    function bit [31:0] expected_data(input bit [31:0] addr);
        return addr + 32'hA5A5A5A5;  // Example expected data function
    endfunction