module axi_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst_n,

    // Dynamic Inputs for Write Transactions
    input wire [ADDR_WIDTH-1:0] input_awaddr,  // Write address
    input wire input_awvalid,                  // Write address valid
    input wire [7:0] input_awlen,              // Write burst length
    input wire [DATA_WIDTH-1:0] input_wdata,   // Write data input
    input wire [DATA_WIDTH/8-1:0] input_wstrb, // Write strobe
    input wire input_wvalid,                   // Write data valid
    input wire input_bready,                   // Write response ready

    // Dynamic Inputs for Read Transactions
    input wire [ADDR_WIDTH-1:0] input_araddr,  // Read address
    input wire input_arvalid,                  // Read address valid
    input wire [7:0] input_arlen,              // Read burst length
    input wire input_rready,                   // Read data ready

    // Write Address Channel
    output reg [ADDR_WIDTH-1:0] awaddr,
    output reg [7:0] awlen,
    output reg awvalid,
    input wire awready,
    output reg htrans_w_t htrans_w,

    // Write Data Channel
    output reg [DATA_WIDTH-1:0] wdata,
    output reg [DATA_WIDTH/8-1:0] wstrb,  // Write strobe
    output reg wvalid,
    input wire wready,

    // Write Response Channel
    input wire [1:0] bresp,
    input wire bvalid,
    output reg bready,

    // Read Address Channel
    output reg [ADDR_WIDTH-1:0] araddr,
    output reg [7:0] arlen,
    output reg arvalid,
    input wire arready,
    output reg htrans_r_t htrans_r,

    // Read Data Channel
    input wire [DATA_WIDTH-1:0] rdata,
    input wire rvalid,
    output reg rready
);

// HTRANS Enum Declaration
typedef enum reg [1:0] {
    IDLE     = 2'b00,  // No transfer
    NON_SEQ  = 2'b10,  // First transaction (start of burst)
    SEQ      = 2'b11   // Subsequent transactions
} htrans_w_t, htrans_r_t;

// Write Transaction State Machine
typedef enum reg [1:0] {IDLE_W, WRITE_ADDR, WRITE_DATA, WRITE_RESP} write_state_t;
write_state_t write_state;
int w_count;

// Read Transaction State Machine
typedef enum reg [1:0] {IDLE_R, READ_ADDR, READ_DATA} read_state_t;
read_state_t read_state;
int r_count;

// ** Dynamic Burst Length Adjustment **
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        awlen <= input_awlen;
    end else if (input_awvalid) begin
        // Limit burst size dynamically for better memory efficiency
        awlen <= (input_awlen > 8) ? 8 : input_awlen;
    end
end

// ** Improved Write Transaction Process **
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        awvalid  <= 1'b0;
        wvalid   <= 1'b0;
        bready   <= 1'b0;
        htrans_w <= IDLE;
        w_count  <= 0;
        write_state <= IDLE_W;
    end else begin
        case (write_state)
            IDLE_W: begin
                awvalid <= input_awvalid;
                awaddr  <= input_awaddr;
                awlen   <= input_awlen;
                htrans_w <= NON_SEQ;
                write_state <= WRITE_ADDR;
            end

            WRITE_ADDR: begin
                if (awready) begin
                    awvalid <= 1'b0;
                    htrans_w <= SEQ;
                    write_state <= WRITE_DATA;
                end
            end

            WRITE_DATA: begin
                if (wready && input_wvalid) begin
                    wdata  <= input_wdata;
                    wstrb  <= input_wstrb;
                    wvalid <= input_wvalid;
                    w_count <= w_count + 1;
                    if (w_count >= awlen) begin
                        write_state <= WRITE_RESP;
                    end
                end
            end

            WRITE_RESP: begin
                if (bvalid) begin
                    // ** Error handling: Check for AXI response errors **
                    if (bresp != 2'b00) begin
                        $display("AXI ERROR: Write Response Failed! BRESP = %b", bresp);
                        bready <= 1'b0; // Prevent response acknowledgment
                    end else begin
                        bready <= input_bready;
                    end

                    // Transaction wrap-up
                    if (w_count < awlen) begin  
                        htrans_w <= SEQ;
                        write_state <= WRITE_ADDR;
                    end else begin
                        htrans_w <= IDLE;
                        write_state <= IDLE_W;
                    end
                end
            end
        endcase
    end
end

// ** Improved Read Transaction Process **
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        arvalid  <= 1'b0;
        rready   <= 1'b0;
        htrans_r <= IDLE;
        r_count  <= 0;
        read_state <= IDLE_R;
    end else begin
        case (read_state)
            IDLE_R: begin
                arvalid <= input_arvalid;
                araddr  <= input_araddr;
                arlen   <= input_arlen;
                htrans_r <= NON_SEQ;
                read_state <= READ_ADDR;
            end

            READ_ADDR: begin
                if (arready) begin
                    arvalid <= 1'b0;
                    htrans_r <= SEQ;
                    read_state <= READ_DATA;
                end
            end

            READ_DATA: begin
                if (rvalid && input_rready) begin
                    rready   <= input_rready;

                    // ** Enhanced Debugging: Structured output with timestamp **
                    $display("[%0t] READ DATA: Address = %h, Data = %h", $time, araddr, rdata);
                    if (rdata == 32'hDEADBEEF) begin
                        $display("⚠ WARNING: Unexpected value detected!");
                    end

                    r_count <= r_count + 1;
                    if (r_count >= arlen) begin
                        htrans_r <= IDLE;
                        read_state <= IDLE_R;
                    end
                end
            end
        endcase
    end
end

endmodule
