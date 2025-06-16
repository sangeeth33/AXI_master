//////////////////////////
// interface //
/////////////////////////

interface axi_if(input logic clk, input logic rst_n);

    // Write Address Channel Signals
    logic [31:0] awaddr;
    logic [7:0] awlen;
    logic awvalid;
    logic awready;

    // Write Data Channel Signals
    logic [31:0] wdata;
    logic [3:0] wstrb;
    logic wvalid;
    logic wready;

    // Write Response Channel
    logic [1:0] bresp;
    logic bvalid;
    logic bready;

    // Read Address Channel Signals
    logic [31:0] araddr;
    logic [7:0] arlen;
    logic arvalid;
    logic arready;

    // Read Data Channel Signals
    logic [31:0] rdata;
    logic rvalid;
    logic rready;

    // Clocking block for synchronized transactions
    clocking axi_cb @(posedge clk);
        input awready, wready, bvalid, rvalid, arready;
        output awaddr, awlen, awvalid, wdata, wstrb, wvalid, bready, araddr, arlen, arvalid, rready;
    endclocking

    modport tb (clocking axi_cb, input rst_n);
    modport dut (input awaddr, awlen, awvalid, wdata, wstrb, wvalid, bready, araddr, arlen, arvalid, rready);

endinterface


//sequence item

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

/////////////////////////////
// sequence ///
//////////////////////////////


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


////////////////////////////////////////
//  sequencer  //
/////////////////////////////////////////

class axi_sequencer extends uvm_sequencer #(axi_seq_item);

    `uvm_object_utils(axi_sequencer)

    function new(string name = "axi_sequencer");
        super.new(name);
    endfunction

endclass

////////////////////////////////////////
// driver //
////////////////////////////////////////


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

//////////////////////////////////
// monitor //
/////////////////////////////////

/*class axi_monitor extends uvm_monitor;

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

endclass*/


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

/////////////////////////////
// scoreboard //
//////////////////////////////


/*class axi_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp #(axi_seq_item, axi_scoreboard) sb_imp;

    `uvm_component_utils(axi_scoreboard)

    function new(string name = "axi_scoreboard", uvm_component parent);
        super.new(name, parent);
        sb_imp = new("sb_imp", this);
    endfunction

    virtual function void write(axi_seq_item tr);
        if (tr.wdata != expected_data(tr.awaddr))
            `uvm_error("AXI_SCOREBOARD", $sformatf("Data Mismatch: %h vs Expected %h", tr.wdata, expected_data(tr.awaddr)));
    endfunction

    function bit [31:0] expected_data(input bit [31:0] addr);
        return addr + 32'hA5A5A5A5;  // Example expected data function
    endfunction

endclass*/

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

//////////////////////////
//  agent //
/////////////////////////

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

///////////////////////////
// env //
///////////////////////////

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

////////////////////
// base_test //
///////////////////

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

//////////////////////
// tb_top //
/////////////////////

module tb_top;

    // DUT Signals
    reg clk;
    reg rst_n;
    axi_if axi_vif(clk, rst_n);  // **AXI Virtual Interface**

    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // **Clock Generation**
    end

    initial begin
	rst_n = 0;
       #20 rst_n = 1;  // **Reset Assertion**
	   
	   ///test_1//
		/*rst_n = 0;  // **Apply Initial Reset**
        #20 rst_n = 1;  // **Deassert Reset After 20 Time Units**

        // **Additional Reset Pulse to Test Recovery**
        #100 rst_n = 0;
        #20 rst_n = 1;*/
		
		///test_2_single write
		
		run_test("single_write_test"); // run single write test scenario
		
		//test_3// single read
		
		run_test("single_read_test");  // Run single read test scenario
		
		// test_4 burst write
		
		run_test("burst_write_test");  // Run burst write test scenario
		// test_5 burst read
		
		run_test("burst_read_test");  // Run burst read test scenario
		
		// test_6 /
		run_test("back_to_back_test");  // Run back-to-back write/read test scenario

		
		

        // #200 $stop;  // **Stop Simulation After 200 Time Units**
    end

    // Instantiate DUT
    axi_master dut (
        .clk(clk),
        .rst_n(rst_n),
        .awaddr(axi_vif.awaddr),
        .awlen(axi_vif.awlen),
        .awvalid(axi_vif.awvalid),
        .wdata(axi_vif.wdata),
        .wstrb(axi_vif.wstrb),
        .wvalid(axi_vif.wvalid)
    );

    initial begin
        run_test("base_test");  // **Run UVM Test**
    end

endmodule

//////////////////////////////////
//test case 2//////////////
///////////to do single write///
/// create sequence for single write, edit seq_item and sequence accordingly and extend base test for single write
/////////////////////////////


//////single write seq item/////


class axi_single_write_seq_item extends axi_seq_item;

    `uvm_object_utils(axi_single_write_seq_item)

    function new(string name = "axi_single_write_seq_item");
        super.new(name);
    endfunction

    // Constraint to enforce a single write transaction
    constraint single_write {
        awvalid == 1'b1;
        wvalid == 1'b1;
        awlen == 1;  // Ensure only 1 write cycle
    }

endclass

////////////////////
// single write sequence
////////////////////


class axi_single_write_sequence extends axi_sequence;

    `uvm_object_utils(axi_single_write_sequence)

    function new(string name = "axi_single_write_sequence");
        super.new(name);
    endfunction

    virtual task body();
        axi_single_write_seq_item req;
        req = axi_single_write_seq_item::type_id::create("req");

        start_item(req);
        assert(req.randomize());
        finish_item(req);
    endtask

endclass


//////////////////////////////////////////
//////extend base test to single write
////////////////////////////////////////


class single_write_test extends base_test;

    `uvm_component_utils(single_write_test)

    function new(string name = "single_write_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_single_write_sequence seq;
        seq = axi_single_write_sequence::type_id::create("seq");

        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass
///////// add "run_test("single_write_test"); " in tb_top // Run single write test scenario



////////////////////////////////////////
//test case 3//////////////
///////////to do single read///
/// create sequence for single read, edit seq_item and sequence accordingly and extend base test for single read
/////////////////////////////

//////single write se item/////

class axi_single_read_seq_item extends axi_seq_item;

    `uvm_object_utils(axi_single_read_seq_item)

    function new(string name = "axi_single_read_seq_item");
        super.new(name);
    endfunction

    // Constraint to enforce a single read transaction
    constraint single_read {
        arvalid == 1'b1;
        arlen == 1;  // Ensure only 1 read cycle
    }

endclass


////////////////////
// single write sequence
////////////////////

class axi_single_read_sequence extends axi_sequence;

    `uvm_object_utils(axi_single_read_sequence)

    function new(string name = "axi_single_read_sequence");
        super.new(name);
    endfunction

    virtual task body();
        axi_single_read_seq_item req;
        req = axi_single_read_seq_item::type_id::create("req");

        start_item(req);
        assert(req.randomize());
        finish_item(req);
    endtask

endclass

//////////////////////////////////////////
//////extend base test to single read
////////////////////////////////////////

class single_read_test extends base_test;

    `uvm_component_utils(single_read_test)

    function new(string name = "single_read_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_single_read_sequence seq;
        seq = axi_single_read_sequence::type_id::create("seq");

        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass

///////// add "run_test("single_read_test");"  // Run single read test scenario

//////////////////////////////////////////
/////////////////test_4 burst write/////
/////////////////////////////////////////

///////////////////
//burst write seq item
///////////////////

class axi_burst_write_seq_item extends axi_seq_item;

    `uvm_object_utils(axi_burst_write_seq_item)

    function new(string name = "axi_burst_write_seq_item");
        super.new(name);
    endfunction

    // Constraint for a burst write transaction
    constraint burst_write {
        awvalid == 1'b1;
        wvalid == 1'b1;
        awlen inside {4, 8, 16};  // Allow multiple data beats in the burst
    }

endclass


////////////////////////////////
//////// burst write sequence///
////////////////////////////////

class axi_burst_write_sequence extends axi_sequence;

    `uvm_object_utils(axi_burst_write_sequence)

    function new(string name = "axi_burst_write_sequence");
        super.new(name);
    endfunction

    virtual task body();
        axi_burst_write_seq_item req;
        req = axi_burst_write_seq_item::type_id::create("req");

        start_item(req);
        assert(req.randomize());
        finish_item(req);
    endtask

endclass

///////////////////////////////
////base test extends to burst write
//////////////////////////////

class burst_write_test extends base_test;

    `uvm_component_utils(burst_write_test)

    function new(string name = "burst_write_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_burst_write_sequence seq;
        seq = axi_burst_write_sequence::type_id::create("seq");

        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass

/////////////////////////////////
///// run_test("burst_write_test");  // Run burst write test scenario
//////////////////////////////////

 
////////////*****************************************//////////////////
////////////////////////////////////////
//test case 5//////////////
//////////
/// create sequence for burst read, edit seq_item and sequence accordingly and extend base test for burst read
/////////////////////////////

///////////seq_item////////////

class axi_burst_read_seq_item extends axi_seq_item;

    `uvm_object_utils(axi_burst_read_seq_item)

    function new(string name = "axi_burst_read_seq_item");
        super.new(name);
    endfunction

    // Constraint for a burst read transaction
    constraint burst_read {
        arvalid == 1'b1;
        arlen inside {4, 8, 16};  // Allow multiple data beats in the burst
    }

endclass


//////////sequence//////

class axi_burst_read_sequence extends axi_sequence;

    `uvm_object_utils(axi_burst_read_sequence)

    function new(string name = "axi_burst_read_sequence");
        super.new(name);
    endfunction

    virtual task body();
        axi_burst_read_seq_item req;
        req = axi_burst_read_seq_item::type_id::create("req");

        start_item(req);
        assert(req.randomize());
        finish_item(req);
    endtask

endclass


/////////base_test--- to burst read/////

class burst_read_test extends base_test;

    `uvm_component_utils(burst_read_test)

    function new(string name = "burst_read_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_burst_read_sequence seq;
        seq = axi_burst_read_sequence::type_id::create("seq");

        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass

////run_test("burst_read_test");  // Run burst read test scenario

//////////////////////////////////////////////////////////////
///- Back-to-Back Writes/Reads: Simulate continuous transaction flow without idle cycles.
// seq_item
/////////////////////


class axi_back_to_back_seq_item extends axi_seq_item;

    `uvm_object_utils(axi_back_to_back_seq_item)

    function new(string name = "axi_back_to_back_seq_item");
        super.new(name);
    endfunction

    // Constraint for back-to-back write and read transactions
    constraint back_to_back {
        awvalid == 1'b1;
        wvalid == 1'b1;
        arvalid == 1'b1;
        awlen == 10;  // Ensure 10 write transactions
        arlen == 10;  // Ensure 10 read transactions
    }

endclass

/////////////////////
//sequence///////////
////////////////////

class axi_back_to_back_sequence extends axi_sequence;

    `uvm_object_utils(axi_back_to_back_sequence)

    function new(string name = "axi_back_to_back_sequence");
        super.new(name);
    endfunction

    virtual task body();
        axi_back_to_back_seq_item req;
        req = axi_back_to_back_seq_item::type_id::create("req");

        repeat(10) begin
            start_item(req);
            assert(req.randomize());
            finish_item(req);
        end
    endtask

endclass


/////////////////
//base_test extends to back to back read and writes
/////////////


class back_to_back_test extends base_test;

    `uvm_component_utils(back_to_back_test)

    function new(string name = "back_to_back_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_back_to_back_sequence seq;
        seq = axi_back_to_back_sequence::type_id::create("seq");

        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass

////////////////////////////////
//run_test("back_to_back_test");  // Run back-to-back write/read test scena
//////////////////////////
