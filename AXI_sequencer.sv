class axi_sequencer extends uvm_sequencer #(axi_seq_item);

    `uvm_object_utils(axi_sequencer)

    function new(string name = "axi_sequencer");
        super.new(name);
    endfunction

endclass