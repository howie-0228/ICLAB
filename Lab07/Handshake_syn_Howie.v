module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
output reg flag_handshake_to_clk1;
input flag_clk1_to_handshake;

output flag_handshake_to_clk2;
input flag_clk2_to_handshake;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;

//=======================================================
// Parameter
//=======================================================
parameter IDLE = 0, TRAN = 1, WAIT = 2;
//=======================================================
// Register
//=======================================================
reg [1:0] cs_src, ns_src;
reg [1:0] cs_dst, ns_dst;
reg [WIDTH-1:0] src_data, dst_data;

always @(*) begin
    // flag_handshake_to_clk1 = cs_src == 2 && dvalid;
    // flag_handshake_to_clk1 = sidle && d_valid;
    flag_handshake_to_clk1 = sreq && sack;
end
//=======================================================
// NDFF Synchonizer
//=======================================================
NDFF_syn  reg_sync(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn  ack_sync(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));
//=======================================================
// FSM_src
//=======================================================
always @(posedge sclk or negedge rst_n) begin
    if(~rst_n)
        cs_src <= IDLE;
    else
        cs_src <= ns_src;
end
always @(*) begin
    case (cs_src)
        IDLE:ns_src =  sready && ~sreq ? TRAN : IDLE;
        TRAN:ns_src =  sack   &&  sreq ? WAIT : TRAN;
        WAIT:ns_src =  ~sack  && ~sreq ? IDLE : WAIT;
        default: ns_src = IDLE;
    endcase
end
//=======================================================
// Src Ctrl
//=======================================================
always @(posedge sclk or negedge rst_n)begin
    if(~rst_n)
        sreq <= 1'b0;
    else if (ns_src == TRAN)
        sreq <= 1'b1;
    else if (ns_src == WAIT)
        sreq <= 1'b0;
    else
        sreq <= sreq;
end
//=======================================================
// Src data
//=======================================================
always @(posedge sclk or negedge rst_n) begin
    if(~rst_n)
        src_data <= 0;
    else if(cs_src == IDLE)
        src_data <= din;
    else
        src_data <= src_data;
end
//=======================================================
// FSM_dst
//=======================================================
always @(posedge dclk or negedge rst_n) begin
    if(~rst_n)
        cs_dst <= IDLE;
    else
        cs_dst <= ns_dst;
end
always @(*) begin
    case (cs_dst)
        IDLE: ns_dst = ~dbusy &&  dreq ? TRAN : IDLE;
        TRAN: ns_dst =  dack  && ~dreq ? WAIT : TRAN;
        WAIT: ns_dst = IDLE;
        default: ns_dst = IDLE;
    endcase
end
//=======================================================
// Dst Ctrl
//=======================================================
always @(posedge dclk or negedge rst_n)begin
    if(~rst_n)
        dack <= 1'b0;
    else if (ns_dst == TRAN)
        dack <= 1'b1;
    else if (ns_dst == WAIT)
        dack <= 1'b0;
    else
        dack <= dack;
end
//=======================================================
// Dst data
//=======================================================
always @(posedge dclk or negedge rst_n) begin
    if(~rst_n)
        dst_data <= 0;
    else if(ns_dst == WAIT)
        dst_data <= src_data;
    else
        dst_data <= dst_data;
end
//=======================================================
// Output
//=======================================================
assign sidle = cs_src == IDLE;
always @(posedge dclk or negedge rst_n) begin
    if(~rst_n)begin
        dvalid <= 1'b0;
        dout   <= 0;
    end
    else if(cs_dst == WAIT)begin
        dvalid <= 1'b1;
        dout   <= dst_data;
    end
    else begin
        dvalid <= 1'b0;
        dout   <= 0;
    end
end
endmodule