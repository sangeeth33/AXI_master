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