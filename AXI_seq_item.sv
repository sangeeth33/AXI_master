class axi_seq_item extends uvm_sequence_item;

    // Transaction Parameters
    rand bit [31:0] awaddr;
    rand bit [7:0] awlen;
    rand bit [31:0] wdata;
    rand bit [3:0] wstrb;
    rand bit awvalid;
    rand bit wvalid;

    // Constraints for AXI Validity
    constraint valid_trans {
        awvalid == 1'b1;
        wvalid == 1'b1;
    }

    `uvm_object_utils(axi_seq_item)  // UVM Factory Registration

    function new(string name = "axi_seq_item");
        super.new(name);
    endfunction

endclass