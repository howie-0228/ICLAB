module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_row,
    in_kernel,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_data,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
input clk;
input rst_n;
input in_valid;
input [17:0] in_row;
input [11:0] in_kernel;
input out_idle;
output reg handshake_sready;
output reg [29:0] handshake_din;
// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output flag_clk1_to_handshake;

input fifo_empty;
input [7:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [7:0] out_data;
// You can use the the custom flag ports for your design
output flag_clk1_to_fifo;
input flag_fifo_to_clk1;
//=======================================================
// Parameter and Integer
//=======================================================
integer i;
parameter IDLE = 0, STANDBY = 1, WAIT = 2, READY = 3;
//=======================================================
// Register
//=======================================================
reg [1:0] cs_in, ns_in;

reg [17:0] row[0:5];
reg [11:0] kernel[0:5];
reg [17:0] row_reg;
reg [11:0] kernel_reg;

reg [2:0] cnt;
reg [2:0] cnt_idle;
// reg [2:0] cnt_idle_ns;

wire stored_done;
assign stored_done = cnt_idle == 'd5 && out_idle;
// assign stored_done = ns_in == READY;
//=======================================================
// Domain 1 to Handshake
//=======================================================
//=======================================================
// FSM
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cs_in <= IDLE;
    else
        cs_in <= ns_in;
end
always @(*) begin
    ns_in = cs_in;
    case(cs_in)
        IDLE   :ns_in = in_valid ? STANDBY : IDLE;
        STANDBY:ns_in = in_valid ? STANDBY : READY;
        READY  :ns_in = out_idle ? WAIT : READY;
        WAIT   :ns_in = out_idle ? WAIT : (cnt_idle == 'd6 ? IDLE : READY);
        default:ns_in = IDLE;
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt <= 0;
    else if(stored_done)
        cnt <= 0;
    else if(in_valid)
        cnt <= cnt + 1;
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt_idle <= 0;
    else if(cs_in == IDLE || cs_in == STANDBY)
        cnt_idle <= 0;
    // else if((in_valid && out_idle) || (cnt_idle != 0 && out_idle))
    else if(out_idle && cs_in == READY)
        cnt_idle <= cnt_idle + 1;
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        for(i=0; i<6; i=i+1)begin
            row[i] <= 0;
        end
    end
    else if(in_valid)begin
        // if(cnt < 'd6)begin
            row[cnt] <= in_row;
        // end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        for(i=0; i<6; i=i+1)begin
            kernel[i] <= 0;
        end
    end
    else if(in_valid)begin
        // if(cnt < 'd6)begin
            kernel[cnt] <= in_kernel;
        // end
    end
end
// always @(posedge clk or negedge rst_n) begin
//     if(rst_n)begin
//         row_reg    <= 0;
//         kernel_reg <= 0;
//     end
//     else if(out_idle)begin
//         row_reg    <= row[cnt_idle];
//         kernel_reg <= kernel[cnt_idle];
//     end
// end
//=======================================================
// Output
//=======================================================
// always @(*) begin
//     // handshake_sready = out_idle ? 1 : 0;
//     if(cs_in == WAIT /*&& cnt_idle < 'd5*/)
//         handshake_sready = 1;
//     else
//         handshake_sready = 0;
// end
// always @(*) begin
//     if(cs_in == READY /*&& cnt_idle < 'd6*/)
//         handshake_din = {row[cnt_idle], kernel[cnt_idle]};
//     else
//         handshake_din = 0;
// end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        handshake_din <= 0;
        handshake_sready <= 0;
    end
    else if(cs_in == READY && out_idle)begin
        handshake_din <= {row[cnt_idle], kernel[cnt_idle]};
        handshake_sready <= 1;
    end
    else begin
        handshake_din <= 0;
        handshake_sready <= 0;
    end
end
//==================================================================================
//=======================================================
// FIFO to Domain 1
//=======================================================
reg [1:0] cnt_delay_3;
assign fifo_rinc =  !in_valid && ~fifo_empty;
// assign fifo_rinc =  0;
reg cs_out, ns_out;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cs_out <= 'd0;
    else
        cs_out <= ns_out;
end
always @(*) begin
    case(cs_out)
        'd0 :ns_out = cnt_delay_3 == 1 ? 'd1 : 'd0;
        'd1 :ns_out = cnt_delay_3 == 0 ? 'd0 : 'd1;
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        cnt_delay_3 <= 0;
    end
    else if(fifo_empty)begin
        cnt_delay_3 <= 0;
    end
    else if(!fifo_rinc)begin
        cnt_delay_3 <= 0;
    end
    else if(cnt_delay_3 == 'd2)begin
        cnt_delay_3 <= cnt_delay_3;
    end
    else if(fifo_rinc || cnt_delay_3 != 0)begin
        cnt_delay_3 <= cnt_delay_3 + 1;
    end
end
// reg [1:0] state_cnt_150, n_state_cnt_150
reg [7:0] cnt_150;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt_150 <= 0;
    else if(cnt == 'd5)
        cnt_150 <= 0;
    else if(cnt_150 == 'd150)
        cnt_150 <= cnt_150;
    else if(out_valid)
        cnt_150 <= cnt_150 + 1;
end
wire cnt_150_check;
assign cnt_150_check = cnt_150 == 'd150;
always @(*) begin
    if(cs_out == 'd1)begin
        // if(!check_first_img && ns_out == IDLE && fifo_empty)begin
        //     out_valid = 0;
        //     out_data = 0;
        // end
        // else begin
            out_valid = cnt_150_check ? 0 : 1;
            out_data = fifo_rdata;
        end
    // end
    else begin
        out_valid = 0;
        out_data = 0;
    end
end



endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_data,
    out_valid,
    out_data,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [29:0] in_data;
output reg out_valid;
output reg [7:0] out_data;
output reg busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;
//=======================================================
// Parameter and Integer
//=======================================================
parameter IDLE = 0, WAIT = 1, OUT = 2, CONV = 3;

integer i,j;
//=======================================================
// Register
//=======================================================
reg [1:0] cs, ns;

wire [2:0] k_00, k_01, k_10, k_11;
wire [2:0] m_00, m_01, m_02, m_03, m_04, m_05;

reg [11:0] Kernel[0:5];
reg [2:0] FM[0:5][0:5];

reg [2:0] cnt;
reg [2:0] cnt_5;
reg [7:0] cnt_conv;
reg [2:0] cnt_x;
reg [2:0] cnt_y;

reg  [2:0] mult_in1_1, mult_in1_2, mult_in1_3, mult_in1_4;
reg  [2:0] mult_in2_1, mult_in2_2, mult_in2_3, mult_in2_4;
wire [5:0] mult_out_1, mult_out_2, mult_out_3, mult_out_4;

wire [7:0] conv_out;
reg  [7:0] conv_out_reg;

wire out_done;
assign out_done = cnt_conv == 'd151;

wire is_first_img;
assign is_first_img = cnt_conv < 'd24;
//=======================================================
// FSM
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cs <= IDLE;
    else
        cs <= ns;
end
always @(*) begin
    case (cs)
        IDLE: ns = in_valid ? WAIT : IDLE;
        WAIT: ns = in_valid ? CONV : WAIT;
        CONV: ns = OUT;
        OUT : ns = out_done ? IDLE : OUT;
        default: ns = IDLE;
    endcase
end
//=======================================================
// Input REGISTER
//=======================================================
assign k_00 = in_data[2:0];
assign k_01 = in_data[5:3];
assign k_10 = in_data[8:6];
assign k_11 = in_data[11:9];
assign m_00 = in_data[14:12];
assign m_01 = in_data[17:15];
assign m_02 = in_data[20:18];
assign m_03 = in_data[23:21];
assign m_04 = in_data[26:24];
assign m_05 = in_data[29:27];
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        for(i=0; i<6; i=i+1)begin
            for(j=0; j<6; j=j+1)begin
                FM[i][j] <= 0;
            end
        end
    end
    // else if (out_done)begin
    //     for(i=0; i<6; i=i+1)begin
    //         for(j=0; j<6; j=j+1)begin
    //             FM[i][j] <= 0;
    //         end
    //     end
    // end
    else if(in_valid)begin
        if(cnt < 'd6)begin
            FM[cnt][0] <= m_00;
            FM[cnt][1] <= m_01;
            FM[cnt][2] <= m_02;
            FM[cnt][3] <= m_03;
            FM[cnt][4] <= m_04;
            FM[cnt][5] <= m_05;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        for(i=0; i<6; i=i+1)begin
            Kernel[i] <= 0;
        end
    end
    // else if(out_done)begin
    //     for(i=0; i<6; i=i+1)begin
    //         Kernel[i] <= 0;
    //     end
    // end
    else if(in_valid)begin
        if(cnt < 'd6)begin
            Kernel[cnt] <= {k_11, k_10, k_01, k_00};
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt <= 0;
    else if(out_done)
        cnt <= 0;
    else if (flag_fifo_to_clk2)
        cnt <= cnt;
    else if(in_valid)
        cnt <= cnt + 1;
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt_conv <= 0;
    else if(out_done)
        cnt_conv <= 0;
    else if(ns == OUT)begin
        if (flag_fifo_to_clk2)
            cnt_conv <= cnt_conv;
        else if(is_first_img)begin
            if(out_valid)
                cnt_conv <= cnt_conv + 1;
        end
        else if(~is_first_img)begin
            if(!flag_fifo_to_clk2)
                cnt_conv <= cnt_conv + 1;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt_5 <= 0;
    else if(cnt_5 == 6)
        cnt_5 <= 0;
    else if(in_valid || cnt_5 != 0)
        cnt_5 <= cnt_5 + 1;
end
//=======================================================
// Convolution
//=======================================================
always @(posedge clk ) begin
    if(cnt == 0)begin
        cnt_x <= 0;
        cnt_y <= 0;
    end
    else if(flag_fifo_to_clk2)begin
        cnt_x <= cnt_x;
        cnt_y <= cnt_y;
    end
    else if(ns == OUT)begin
        if(cnt_5 != 'd0 && cnt_5 != 'd6)begin
        // if(cnt_5 != 'd0)begin
            if(cnt_x == 'd4)begin
                cnt_x <= 0;
                if(cnt_y == 'd4)
                    cnt_y <= 0;
                else
                    cnt_y <= cnt_y + 1;
            end
            else
                cnt_x <= cnt_x + 1;
        end
        else if(!is_first_img)begin
            if(cnt_x == 'd4)begin
                cnt_x <= 0;
                if(cnt_y == 'd4)
                    cnt_y <= 0;
                else
                    cnt_y <= cnt_y + 1;
            end
            else
                cnt_x <= cnt_x + 1;
        end
    end
end
assign mult_out_1 = mult_in1_1 * mult_in2_1;
assign mult_out_2 = mult_in1_2 * mult_in2_2;
assign mult_out_3 = mult_in1_3 * mult_in2_3;
assign mult_out_4 = mult_in1_4 * mult_in2_4;

assign conv_out = mult_out_1 + mult_out_2 + mult_out_3 + mult_out_4;

always @(*) begin
    mult_in1_1 = FM[cnt_y    ][cnt_x    ];
    mult_in1_2 = FM[cnt_y    ][cnt_x + 1];
    mult_in1_3 = FM[cnt_y + 1][cnt_x    ];
    mult_in1_4 = FM[cnt_y + 1][cnt_x + 1];
end
always @(*) begin
    if(cnt_conv < 'd24 /*&& cnt_conv > 'd1*/)begin
        mult_in2_1 = Kernel[0][2:0];
        mult_in2_2 = Kernel[0][5:3];
        mult_in2_3 = Kernel[0][8:6];
        mult_in2_4 = Kernel[0][11:9];
    end
    else if(cnt_conv < 'd49 /*&& cnt_conv > 'd25*/)begin
        mult_in2_1 = Kernel[1][2:0];
        mult_in2_2 = Kernel[1][5:3];
        mult_in2_3 = Kernel[1][8:6];
        mult_in2_4 = Kernel[1][11:9];
    end
    else if(cnt_conv < 'd74 /*&& cnt_conv > 'd50*/)begin
        mult_in2_1 = Kernel[2][2:0];
        mult_in2_2 = Kernel[2][5:3];
        mult_in2_3 = Kernel[2][8:6];
        mult_in2_4 = Kernel[2][11:9];
    end
    else if(cnt_conv < 'd99 /*&& cnt_conv > 'd75*/)begin
        mult_in2_1 = Kernel[3][2:0];
        mult_in2_2 = Kernel[3][5:3];
        mult_in2_3 = Kernel[3][8:6];
        mult_in2_4 = Kernel[3][11:9];
    end
    else if(cnt_conv < 'd124 /*&& cnt_conv > 'd100*/)begin
        mult_in2_1 = Kernel[4][2:0];
        mult_in2_2 = Kernel[4][5:3];
        mult_in2_3 = Kernel[4][8:6];
        mult_in2_4 = Kernel[4][11:9];
    end
    else if(cnt_conv < 'd149 /*&& cnt_conv > 'd125*/)begin
        mult_in2_1 = Kernel[5][2:0];
        mult_in2_2 = Kernel[5][5:3];
        mult_in2_3 = Kernel[5][8:6];
        mult_in2_4 = Kernel[5][11:9];
    end
    else begin
        mult_in2_1 = 0;
        mult_in2_2 = 0;
        mult_in2_3 = 0;
        mult_in2_4 = 0;
    end
end
always @(posedge clk ) begin
    conv_out_reg <= conv_out;
end
//=======================================================
// Output
//=======================================================
always @(*) begin
    if(cs == OUT)
        out_data = out_valid ? conv_out_reg : 0;
    else
        out_data = 0;
end
// always @(posedge clk or negedge rst_n) begin
//     if(~rst_n)
//         out_valid <= 0;
//     else if(ns == OUT)begin
//         if(is_first_img)
//             out_valid <= cnt_5 != 0 ? 1 : 0;
//         else
//             // out_valid <= flag_fifo_to_clk2 ? 0 : 1;
//             out_valid <= (flag_fifo_to_clk2 || cnt_conv > 'd148) ? 0 : 1;
//     end
//     else
//         out_valid <= 0;
// end
always @(*) begin
    if(!rst_n)
        out_valid = 0;
    else if(cs == OUT)begin
        if(is_first_img)
            out_valid = (cnt_5 > 1'b1 && !fifo_full) ? 1 : 0;
        else
            out_valid = (fifo_full || cnt_conv > 'd149) ? 0 : 1;
    end
    else
        out_valid = 0;
end
always @(*) begin
    if(flag_fifo_to_clk2)
        busy = 0;
    else
        busy = 0;
end
endmodule