module FIFO_syn #(parameter WIDTH=8, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk1,
	flag_clk1_to_fifo
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
output  flag_fifo_to_clk2;
input flag_clk2_to_fifo;

output flag_fifo_to_clk1;
input flag_clk1_to_fifo;

wire [WIDTH-1:0] rdata_syn;

// Remember:
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;
//=======================================================
// Parameter
//=======================================================

//=======================================================
// Register
//=======================================================
wire [$clog2(WORDS):0] wptr_ns;
wire [$clog2(WORDS):0] rptr_ns;

wire [$clog2(WORDS):0] wptr_syn;
wire [$clog2(WORDS):0] rptr_syn;

wire [$clog2(WORDS):0] wptr_syn_bin_ns;
wire [$clog2(WORDS):0] rptr_syn_bin_ns;

reg [$clog2(WORDS):0] wptr_syn_bin;
reg [$clog2(WORDS):0] rptr_syn_bin;

wire [5:0] addr_w;
wire [5:0] addr_r;

wire empty;
wire full;

assign empty = rptr == wptr_syn;
assign full  = wptr_ns == {~rptr_syn[6], ~rptr_syn[5], rptr_syn[4:0]};
//====================================================
// POINTER
//====================================================
NDFF_BUS_syn  #(.WIDTH(7))  Wptr(.D(wptr), .Q(wptr_syn), .clk(rclk), .rst_n(rst_n));
NDFF_BUS_syn  #(.WIDTH(7))  Rptr(.D(rptr), .Q(rptr_syn), .clk(wclk), .rst_n(rst_n));
//====================================================
// READ CONTROL
//====================================================
assign rptr_syn_bin_ns = rptr_syn_bin + (rinc && ~empty);

always @(posedge rclk or negedge rst_n) begin
    if(~rst_n)begin
        rptr_syn_bin <= 0;
        rptr         <= 0;
    end
    else begin
        rptr_syn_bin <= rptr_syn_bin_ns;
        rptr         <= rptr_ns;
    end
end
//====================================================
// WRITE CONTROL
//====================================================
assign wptr_syn_bin_ns = wptr_syn_bin + (winc && ~wfull);

assign rptr_ns = (rptr_syn_bin_ns >> 1) ^ rptr_syn_bin_ns;
assign wptr_ns = (wptr_syn_bin_ns >> 1) ^ wptr_syn_bin_ns;


always @(posedge wclk or negedge rst_n) begin
    if(~rst_n)begin
        wptr_syn_bin <= 0;
        wptr         <= 0;
    end
    else begin
        wptr_syn_bin <= wptr_syn_bin_ns;
        wptr         <= wptr_ns;
    end
end
//====================================================
// FIFO MEMORY
//====================================================
assign addr_w = wptr_syn_bin[5:0] ;
assign addr_r = rptr_syn_bin[5:0] ;
DUAL_64X8X1BM1 u_dual_sram(
    .A0(addr_w[0]),
    .A1(addr_w[1]),
    .A2(addr_w[2]),
    .A3(addr_w[3]),
    .A4(addr_w[4]),
    .A5(addr_w[5]),
    .B0(addr_r[0]),
    .B1(addr_r[1]),
    .B2(addr_r[2]),
    .B3(addr_r[3]),
    .B4(addr_r[4]),
    .B5(addr_r[5]),
    // .DOA0(),
    // .DOA1(),
    // .DOA2(),
    // .DOA3(),
    // .DOA4(),
    // .DOA5(),
    // .DOA6(),
    // .DOA7(),

    .DOB0(rdata_syn[0]),
    .DOB1(rdata_syn[1]),
    .DOB2(rdata_syn[2]),
    .DOB3(rdata_syn[3]),
    .DOB4(rdata_syn[4]),
    .DOB5(rdata_syn[5]),
    .DOB6(rdata_syn[6]),
    .DOB7(rdata_syn[7]),

    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),

    .DIB0(1'b0),
    .DIB1(1'b0),
    .DIB2(1'b0),
    .DIB3(1'b0),
    .DIB4(1'b0),
    .DIB5(1'b0),
    .DIB6(1'b0),
    .DIB7(1'b0),

    .WEAN(~winc),
    // .WEAN(wfull),
    .WEBN(1'b1),
    .CKA(wclk),
    .CKB(rclk),
    .CSA(1'b1),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1)
);
//====================================================
// OUTPUT
//====================================================
always @(posedge wclk or negedge rst_n) begin
    if(~rst_n)begin
        wfull <= 1'b0;
    end
    else begin
        wfull <= full;
    end
end
always @(*) begin
    if (!rst_n)
        rempty = 'b1;
    else
        rempty = empty;

end
// always @(posedge rclk or negedge rst_n) begin
//     if(~rst_n)
//         rempty <= 1'b1;
//     else
//         rempty <= empty;
// end
always @(posedge rclk or negedge rst_n) begin
    if(~rst_n)
        rdata <= 0;
    else
        rdata <= rdata_syn;
end
assign flag_fifo_to_clk2 = full;

endmodule
