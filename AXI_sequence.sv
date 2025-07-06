class axi_sequence extends uvm_sequence #(axi_seq_item);

    `uvm_object_utils(axi_sequence)  

    function new(string name = "axi_sequence");
        super.new(name);
    endfunction

    virtual task body();
        axi_seq_item req;

        req = axi_seq_item::type_id::create("req");

        start_item(req);
        assert(req.randomize());
        finish_item(req);
    endtask

endclass