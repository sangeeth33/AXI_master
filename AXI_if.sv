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