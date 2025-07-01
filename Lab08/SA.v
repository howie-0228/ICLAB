/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: SA.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Fall IC Lab / Exersise Lab08 / SA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on


module SA(
    //Input signals
    clk,
    rst_n,
    cg_en,
    in_valid,
    T,
    in_data,
    w_Q,
    w_K,
    w_V,

    //Output signals
    out_valid,
    out_data
    );

input clk;
input rst_n;
input in_valid;
input cg_en;
input [3:0] T;
input signed [7:0] in_data;
input signed [7:0] w_Q;
input signed [7:0] w_K;
input signed [7:0] w_V;

output reg out_valid;
output reg signed [63:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter IDLE = 0, READ_WEIGHT_Q = 1, READ_WEIGHT_K = 2, READ_WEIGHT_V = 3, MAT_MUL_1 = 4, CAL_V_LINEAR = 5, MAT_MUL_2 = 6, OUT = 7;  
genvar  k;
integer i, j;

//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [2:0] cs, ns;
wire read_weight_done;
reg cal_v_linear_done;
reg out_done;


reg [2:0] cnt_x;
reg [2:0] cnt_y;

reg signed [7:0] img_row1_buffer        [0:7];
reg signed [7:0] img_row2to4_buffer[0:2][0:7];
reg signed [7:0] img_row5to8_buffer[0:3][0:7];

reg signed [7:0] weight_buffer_Q_V [0:7][0:7];
reg signed [7:0] weight_buffer_K   [0:7][0:7];
reg [1:0] T_buffer;

reg signed [18:0] linear_Q_row1_reg         [0:7];
reg signed [18:0] linear_Q_row2to4_reg [0:2][0:7];
reg signed [18:0] linear_Q_row5to8_reg [0:3][0:7];

reg signed [18:0] linear_K_row1_reg         [0:7] ;
reg signed [18:0] linear_K_row2to4_reg [0:2][0:7] ;
reg signed [18:0] linear_K_row5to8_reg [0:3][0:7] ;

reg signed [18:0] linear_V_row1_reg         [0:7];
reg signed [18:0] linear_V_row2to4_reg [0:2][0:7];
reg signed [18:0] linear_V_row5to8_reg [0:3][0:7];

reg  signed [7:0]   mul_8x8_in1[0:7];
reg  signed [7:0]   mul_8x8_in2[0:7];
wire signed [15:0]  mul_8x8_out[0:7];

reg  signed [39:0]  mul_40x19_in1[0:7];
reg  signed [18:0]  mul_40x19_in2[0:7];
wire signed [58:0]  mul_40x19_out[0:7];

wire signed [18:0]  add_linear_out;
wire signed [61:0]  add_mat_out;

wire signed [39:0]  scale_out;
wire signed [39:0]  relu_out;

reg signed [39:0] S_row1_reg         [0:7];
reg signed [39:0] S_row2to4_reg [0:2][0:7];
reg signed [39:0] S_row5to8_reg [0:3][0:7];

reg signed [63:0] out_buffer;
// reg signed [63:0] out_row2to4_buffer [0:2][0:7];
// reg signed [63:0] out_row5to8_buffer [0:3][0:7];
//================================================//
//       GATED OR
//================================================//
    reg sleep_img[0:7];
    wire g_img_clk[0:7];

    generate
        for(k = 0; k < 8; k = k + 1)begin: GATED_OR_img
            GATED_OR GATED_OR_inst(
                // Input signals
                .CLOCK(clk),
                .SLEEP_CTRL(sleep_img[k]),
                .RST_N(rst_n),
                // Output signals
                .CLOCK_GATED(g_img_clk[k])
            );
        end
    endgenerate
    //sleep_img
    generate
        for(k = 0; k < 8; k = k + 1)begin
            always @(*) begin
                if(ns == IDLE || ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)
                    sleep_img[k] = 0;
                else
                    sleep_img[k] = cg_en;
            end
        end
    endgenerate
    reg sleep_weight_k[0:7];
    wire g_weight_k_clk[0:7];
    generate
        for(k = 0; k < 8; k = k + 1)begin: GATED_OR_wk
            GATED_OR GATED_OR_inst(
                // Input signals
                .CLOCK(clk),
                .SLEEP_CTRL(sleep_weight_k[k]),
                .RST_N(rst_n),
                // Output signals
                .CLOCK_GATED(g_weight_k_clk[k])
            );
        end
    endgenerate
    //sleep_weight_k
    generate
        for(k = 0; k < 8; k = k + 1)begin
            always @(*) begin
                if(cs == IDLE || cs == READ_WEIGHT_K)
                    sleep_weight_k[k] = 0;
                else
                    sleep_weight_k[k] = cg_en;
            end
        end
    endgenerate
    reg sleep_weight_qv [0:7];
    wire g_weight_qv_clk[0:7];
    generate
        for(k = 0; k < 8; k = k + 1)begin: GATED_OR_wqv
            GATED_OR GATED_OR_inst(
                // Input signals
                .CLOCK(clk),
                .SLEEP_CTRL(sleep_weight_qv[k]),
                .RST_N(rst_n),
                // Output signals
                .CLOCK_GATED(g_weight_qv_clk[k])
            );
        end
    endgenerate
    //sleep_weight_qv
    generate
        for(k = 0; k < 8; k = k + 1)begin
            always @(*) begin
                if(ns == IDLE || ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q || cs == READ_WEIGHT_V)
                    sleep_weight_qv[k] = 0;
                else
                    sleep_weight_qv[k] = cg_en;
            end
        end
    endgenerate
    reg sleep_linear_q[0:7];
    wire g_linear_q_clk[0:7];
    generate
        for(k = 0; k < 8; k = k + 1)begin: GATED_OR_lq
            GATED_OR GATED_OR_inst(
                // Input signals
                .CLOCK(clk),
                .SLEEP_CTRL(sleep_linear_q[k]),
                .RST_N(rst_n),
                // Output signals
                .CLOCK_GATED(g_linear_q_clk[k])
            );
        end
    endgenerate
    //sleep_linear_q
    generate
        for(k = 0; k < 8; k = k + 1)begin
            always @(*) begin
                if(cs == IDLE || ns == READ_WEIGHT_K || cs == READ_WEIGHT_K)
                    sleep_linear_q[k] = 0;
                else
                    sleep_linear_q[k] = cg_en;
            end
        end
    endgenerate
    reg sleep_linear_k[0:7];
    wire g_linear_k_clk[0:7];
    generate
        for(k = 0; k < 8; k = k + 1)begin: GATED_OR_lk
            GATED_OR GATED_OR_inst(
                // Input signals
                .CLOCK(clk),
                .SLEEP_CTRL(sleep_linear_k[k]),
                .RST_N(rst_n),
                // Output signals
                .CLOCK_GATED(g_linear_k_clk[k])
            );
        end
    endgenerate
    //sleep_linear_k
    generate
        for(k = 0; k < 8; k = k + 1)begin
            always @(*) begin
                if(cs == IDLE || ns == READ_WEIGHT_V || cs == READ_WEIGHT_V)
                    sleep_linear_k[k] = 0;
                else
                    sleep_linear_k[k] = cg_en;
            end
        end
    endgenerate
    reg sleep_linear_v[0:7];
    wire g_linear_v_clk[0:7];
    generate
        for(k = 0; k < 8; k = k + 1)begin: GATED_OR_lv
            GATED_OR GATED_OR_inst(
                // Input signals
                .CLOCK(clk),
                .SLEEP_CTRL(sleep_linear_v[k]),
                .RST_N(rst_n),
                // Output signals
                .CLOCK_GATED(g_linear_v_clk[k])
            );
        end
    endgenerate
    //sleep_linear_v
    always @(*) begin
        if(cs == IDLE || ns == CAL_V_LINEAR || cs == CAL_V_LINEAR )
            sleep_linear_v[0] = 0;
        else
            sleep_linear_v[0] = cg_en;
    end
    generate
        for(k = 1; k < 8; k = k + 1)begin
            always @(*) begin
                if(cs == IDLE || ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)
                    sleep_linear_v[k] = 0;
                else
                    sleep_linear_v[k] = cg_en;
            end
        end
    endgenerate
    reg sleep_S[0:7];
    wire g_S_clk[0:7];
    generate
        for(k = 0; k < 8; k = k + 1)begin: GATED_OR_S
            GATED_OR GATED_OR_inst(
                // Input signals
                .CLOCK(clk),
                .SLEEP_CTRL(sleep_S[k]),
                .RST_N(rst_n),
                // Output signals
                .CLOCK_GATED(g_S_clk[k])
            );
        end
    endgenerate
    always @(*) begin
                if(cs == IDLE || cs == CAL_V_LINEAR || ns == CAL_V_LINEAR)
                    sleep_S[0] = 0;
                else
                    sleep_S[0] = cg_en;
            end
    generate
        for(k = 1; k < 8; k = k + 1)begin
            always @(*) begin
                if(cs == IDLE || cs == CAL_V_LINEAR || ns == CAL_V_LINEAR || cs == MAT_MUL_2)
                    sleep_S[k] = 0;
                else
                    sleep_S[k] = cg_en;
            end
        end
    endgenerate
//==============================================//
//                    FSM                       //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cs <= IDLE;
    else
        cs <= ns;
end
always @(*) begin
    case (cs)
        IDLE          :ns = in_valid         ? READ_WEIGHT_Q : IDLE; 
        READ_WEIGHT_Q :ns = read_weight_done ? READ_WEIGHT_K : READ_WEIGHT_Q;
        READ_WEIGHT_K :ns = read_weight_done ? READ_WEIGHT_V : READ_WEIGHT_K;
        READ_WEIGHT_V :ns = read_weight_done ? CAL_V_LINEAR  : READ_WEIGHT_V;
        CAL_V_LINEAR  :ns = cal_v_linear_done? MAT_MUL_2     : CAL_V_LINEAR;
        MAT_MUL_2     :ns = OUT;
        OUT           :ns = out_done         ? IDLE          : OUT;
        default       :ns = IDLE;
    endcase
end
assign read_weight_done = (cnt_x == 7 && cnt_y == 7) ? 1 : 0;
always @(*) begin
    case (T_buffer)
        'd0    : cal_v_linear_done = cnt_y == 0 && cnt_x == 7; 
        'd1    : cal_v_linear_done = cnt_y == 3 && cnt_x == 7;
        'd2    : cal_v_linear_done = cnt_y == 7 && cnt_x == 7; 
        default: cal_v_linear_done = 0; 
    endcase
end
always @(*) begin
    case (T_buffer)
        'd0     :out_done = cnt_y == 1 && cnt_x == 0; //1
        'd1     :out_done = cnt_y == 4 && cnt_x == 0;
        'd2     :out_done = cnt_y == 0 && cnt_x == 0;
        default :out_done = 0;
    endcase
end
//==============================================//
// counter
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        cnt_x <= 0;
        cnt_y <= 0;
    end
    else if(ns == IDLE)begin
        cnt_x <= 0;
        cnt_y <= 0;
    end
    else if(ns == MAT_MUL_2)begin
        cnt_y <= 0;
        cnt_x <= 0;
    end
    else begin
        if(cnt_x == 7)begin
            cnt_x <= 0;
            if(cnt_y == 7)
                cnt_y <= 0;
            else
                cnt_y <= cnt_y + 1;
        end
        else
            cnt_x <= cnt_x + 1;
    end
end
//==============================================//
// Input Buffer
//==============================================//
always @(posedge clk ) begin
    if(cs == IDLE && ns == READ_WEIGHT_Q)begin
        case (T)
            1: T_buffer <= 0;
            4: T_buffer <= 1;
            8: T_buffer <= 2;
        endcase
    end
end
//Weight Q V buffer
    //row1
    always @(posedge g_weight_qv_clk[0]) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_Q_V[0][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd0,3'd0}: weight_buffer_Q_V[0][0] <= w_Q;
                {3'd0,3'd1}: weight_buffer_Q_V[0][1] <= w_Q;
                {3'd0,3'd2}: weight_buffer_Q_V[0][2] <= w_Q;
                {3'd0,3'd3}: weight_buffer_Q_V[0][3] <= w_Q;
                {3'd0,3'd4}: weight_buffer_Q_V[0][4] <= w_Q;
                {3'd0,3'd5}: weight_buffer_Q_V[0][5] <= w_Q;
                {3'd0,3'd6}: weight_buffer_Q_V[0][6] <= w_Q;
                {3'd0,3'd7}: weight_buffer_Q_V[0][7] <= w_Q;
            endcase
        end
        else if(cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd0,3'd0}: weight_buffer_Q_V[0][0] <= w_V;
                {3'd0,3'd1}: weight_buffer_Q_V[0][1] <= w_V;
                {3'd0,3'd2}: weight_buffer_Q_V[0][2] <= w_V;
                {3'd0,3'd3}: weight_buffer_Q_V[0][3] <= w_V;
                {3'd0,3'd4}: weight_buffer_Q_V[0][4] <= w_V;
                {3'd0,3'd5}: weight_buffer_Q_V[0][5] <= w_V;
                {3'd0,3'd6}: weight_buffer_Q_V[0][6] <= w_V;
                {3'd0,3'd7}: weight_buffer_Q_V[0][7] <= w_V;
            endcase 
        end
    end
    //row2
    always @(posedge g_weight_qv_clk[1]) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_Q_V[1][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd1,3'd0}: weight_buffer_Q_V[1][0] <= w_Q;
                {3'd1,3'd1}: weight_buffer_Q_V[1][1] <= w_Q;
                {3'd1,3'd2}: weight_buffer_Q_V[1][2] <= w_Q;
                {3'd1,3'd3}: weight_buffer_Q_V[1][3] <= w_Q;
                {3'd1,3'd4}: weight_buffer_Q_V[1][4] <= w_Q;
                {3'd1,3'd5}: weight_buffer_Q_V[1][5] <= w_Q;
                {3'd1,3'd6}: weight_buffer_Q_V[1][6] <= w_Q;
                {3'd1,3'd7}: weight_buffer_Q_V[1][7] <= w_Q;
            endcase
        end
        else if(cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd1,3'd0}: weight_buffer_Q_V[1][0] <= w_V;
                {3'd1,3'd1}: weight_buffer_Q_V[1][1] <= w_V;
                {3'd1,3'd2}: weight_buffer_Q_V[1][2] <= w_V;
                {3'd1,3'd3}: weight_buffer_Q_V[1][3] <= w_V;
                {3'd1,3'd4}: weight_buffer_Q_V[1][4] <= w_V;
                {3'd1,3'd5}: weight_buffer_Q_V[1][5] <= w_V;
                {3'd1,3'd6}: weight_buffer_Q_V[1][6] <= w_V;
                {3'd1,3'd7}: weight_buffer_Q_V[1][7] <= w_V;
            endcase 
        end
    end
    //row3
    always @(posedge g_weight_qv_clk[2]) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_Q_V[2][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd2,3'd0}: weight_buffer_Q_V[2][0] <= w_Q;
                {3'd2,3'd1}: weight_buffer_Q_V[2][1] <= w_Q;
                {3'd2,3'd2}: weight_buffer_Q_V[2][2] <= w_Q;
                {3'd2,3'd3}: weight_buffer_Q_V[2][3] <= w_Q;
                {3'd2,3'd4}: weight_buffer_Q_V[2][4] <= w_Q;
                {3'd2,3'd5}: weight_buffer_Q_V[2][5] <= w_Q;
                {3'd2,3'd6}: weight_buffer_Q_V[2][6] <= w_Q;
                {3'd2,3'd7}: weight_buffer_Q_V[2][7] <= w_Q;
            endcase
        end
        else if(cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd2,3'd0}: weight_buffer_Q_V[2][0] <= w_V;
                {3'd2,3'd1}: weight_buffer_Q_V[2][1] <= w_V;
                {3'd2,3'd2}: weight_buffer_Q_V[2][2] <= w_V;
                {3'd2,3'd3}: weight_buffer_Q_V[2][3] <= w_V;
                {3'd2,3'd4}: weight_buffer_Q_V[2][4] <= w_V;
                {3'd2,3'd5}: weight_buffer_Q_V[2][5] <= w_V;
                {3'd2,3'd6}: weight_buffer_Q_V[2][6] <= w_V;
                {3'd2,3'd7}: weight_buffer_Q_V[2][7] <= w_V;
            endcase 
        end
    end
    //row4
    always @(posedge g_weight_qv_clk[3]) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_Q_V[3][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd3,3'd0}: weight_buffer_Q_V[3][0] <= w_Q;
                {3'd3,3'd1}: weight_buffer_Q_V[3][1] <= w_Q;
                {3'd3,3'd2}: weight_buffer_Q_V[3][2] <= w_Q;
                {3'd3,3'd3}: weight_buffer_Q_V[3][3] <= w_Q;
                {3'd3,3'd4}: weight_buffer_Q_V[3][4] <= w_Q;
                {3'd3,3'd5}: weight_buffer_Q_V[3][5] <= w_Q;
                {3'd3,3'd6}: weight_buffer_Q_V[3][6] <= w_Q;
                {3'd3,3'd7}: weight_buffer_Q_V[3][7] <= w_Q;
            endcase
        end
        else if(cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd3,3'd0}: weight_buffer_Q_V[3][0] <= w_V;
                {3'd3,3'd1}: weight_buffer_Q_V[3][1] <= w_V;
                {3'd3,3'd2}: weight_buffer_Q_V[3][2] <= w_V;
                {3'd3,3'd3}: weight_buffer_Q_V[3][3] <= w_V;
                {3'd3,3'd4}: weight_buffer_Q_V[3][4] <= w_V;
                {3'd3,3'd5}: weight_buffer_Q_V[3][5] <= w_V;
                {3'd3,3'd6}: weight_buffer_Q_V[3][6] <= w_V;
                {3'd3,3'd7}: weight_buffer_Q_V[3][7] <= w_V;
            endcase 
        end
    end
    //row5
    always @(posedge g_weight_qv_clk[4]) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_Q_V[4][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd4,3'd0}: weight_buffer_Q_V[4][0] <= w_Q;
                {3'd4,3'd1}: weight_buffer_Q_V[4][1] <= w_Q;
                {3'd4,3'd2}: weight_buffer_Q_V[4][2] <= w_Q;
                {3'd4,3'd3}: weight_buffer_Q_V[4][3] <= w_Q;
                {3'd4,3'd4}: weight_buffer_Q_V[4][4] <= w_Q;
                {3'd4,3'd5}: weight_buffer_Q_V[4][5] <= w_Q;
                {3'd4,3'd6}: weight_buffer_Q_V[4][6] <= w_Q;
                {3'd4,3'd7}: weight_buffer_Q_V[4][7] <= w_Q;
            endcase
        end
        else if(cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd4,3'd0}: weight_buffer_Q_V[4][0] <= w_V;
                {3'd4,3'd1}: weight_buffer_Q_V[4][1] <= w_V;
                {3'd4,3'd2}: weight_buffer_Q_V[4][2] <= w_V;
                {3'd4,3'd3}: weight_buffer_Q_V[4][3] <= w_V;
                {3'd4,3'd4}: weight_buffer_Q_V[4][4] <= w_V;
                {3'd4,3'd5}: weight_buffer_Q_V[4][5] <= w_V;
                {3'd4,3'd6}: weight_buffer_Q_V[4][6] <= w_V;
                {3'd4,3'd7}: weight_buffer_Q_V[4][7] <= w_V;
            endcase 
        end
    end
    //row6
    always @(posedge g_weight_qv_clk[5]) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_Q_V[5][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd5,3'd0}: weight_buffer_Q_V[5][0] <= w_Q;
                {3'd5,3'd1}: weight_buffer_Q_V[5][1] <= w_Q;
                {3'd5,3'd2}: weight_buffer_Q_V[5][2] <= w_Q;
                {3'd5,3'd3}: weight_buffer_Q_V[5][3] <= w_Q;
                {3'd5,3'd4}: weight_buffer_Q_V[5][4] <= w_Q;
                {3'd5,3'd5}: weight_buffer_Q_V[5][5] <= w_Q;
                {3'd5,3'd6}: weight_buffer_Q_V[5][6] <= w_Q;
                {3'd5,3'd7}: weight_buffer_Q_V[5][7] <= w_Q; 
            endcase
        end
        else if(cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd5,3'd0}: weight_buffer_Q_V[5][0] <= w_V;
                {3'd5,3'd1}: weight_buffer_Q_V[5][1] <= w_V;
                {3'd5,3'd2}: weight_buffer_Q_V[5][2] <= w_V;
                {3'd5,3'd3}: weight_buffer_Q_V[5][3] <= w_V;
                {3'd5,3'd4}: weight_buffer_Q_V[5][4] <= w_V;
                {3'd5,3'd5}: weight_buffer_Q_V[5][5] <= w_V;
                {3'd5,3'd6}: weight_buffer_Q_V[5][6] <= w_V;
                {3'd5,3'd7}: weight_buffer_Q_V[5][7] <= w_V;
            endcase 
        end
    end
    //row7
    always @(posedge g_weight_qv_clk[6]) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_Q_V[6][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd6,3'd0}: weight_buffer_Q_V[6][0] <= w_Q;
                {3'd6,3'd1}: weight_buffer_Q_V[6][1] <= w_Q;
                {3'd6,3'd2}: weight_buffer_Q_V[6][2] <= w_Q;
                {3'd6,3'd3}: weight_buffer_Q_V[6][3] <= w_Q;
                {3'd6,3'd4}: weight_buffer_Q_V[6][4] <= w_Q;
                {3'd6,3'd5}: weight_buffer_Q_V[6][5] <= w_Q;
                {3'd6,3'd6}: weight_buffer_Q_V[6][6] <= w_Q;
                {3'd6,3'd7}: weight_buffer_Q_V[6][7] <= w_Q; 
            endcase
        end
        else if(cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd6,3'd0}: weight_buffer_Q_V[6][0] <= w_V;
                {3'd6,3'd1}: weight_buffer_Q_V[6][1] <= w_V;
                {3'd6,3'd2}: weight_buffer_Q_V[6][2] <= w_V;
                {3'd6,3'd3}: weight_buffer_Q_V[6][3] <= w_V;
                {3'd6,3'd4}: weight_buffer_Q_V[6][4] <= w_V;
                {3'd6,3'd5}: weight_buffer_Q_V[6][5] <= w_V;
                {3'd6,3'd6}: weight_buffer_Q_V[6][6] <= w_V;
                {3'd6,3'd7}: weight_buffer_Q_V[6][7] <= w_V;
            endcase 
        end
    end
    //row8
    always @(posedge g_weight_qv_clk[7]) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_Q_V[7][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd7,3'd0}: weight_buffer_Q_V[7][0] <= w_Q;
                {3'd7,3'd1}: weight_buffer_Q_V[7][1] <= w_Q;
                {3'd7,3'd2}: weight_buffer_Q_V[7][2] <= w_Q;
                {3'd7,3'd3}: weight_buffer_Q_V[7][3] <= w_Q;
                {3'd7,3'd4}: weight_buffer_Q_V[7][4] <= w_Q;
                {3'd7,3'd5}: weight_buffer_Q_V[7][5] <= w_Q;
                {3'd7,3'd6}: weight_buffer_Q_V[7][6] <= w_Q;
                {3'd7,3'd7}: weight_buffer_Q_V[7][7] <= w_Q; 
            endcase
        end
        else if(cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd7,3'd0}: weight_buffer_Q_V[7][0] <= w_V;
                {3'd7,3'd1}: weight_buffer_Q_V[7][1] <= w_V;
                {3'd7,3'd2}: weight_buffer_Q_V[7][2] <= w_V;
                {3'd7,3'd3}: weight_buffer_Q_V[7][3] <= w_V;
                {3'd7,3'd4}: weight_buffer_Q_V[7][4] <= w_V;
                {3'd7,3'd5}: weight_buffer_Q_V[7][5] <= w_V;
                {3'd7,3'd6}: weight_buffer_Q_V[7][6] <= w_V;
                {3'd7,3'd7}: weight_buffer_Q_V[7][7] <= w_V; 
            endcase 
        end
    end
//Weight K buffer
    //row1
    always @(posedge g_weight_k_clk[0]) begin
        if(cs == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_K[0][j] <= 0;
                // end
            end
        end
        else if(cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd0,3'd0}: weight_buffer_K[0][0] <= w_K;
                {3'd0,3'd1}: weight_buffer_K[0][1] <= w_K;
                {3'd0,3'd2}: weight_buffer_K[0][2] <= w_K;
                {3'd0,3'd3}: weight_buffer_K[0][3] <= w_K;
                {3'd0,3'd4}: weight_buffer_K[0][4] <= w_K;
                {3'd0,3'd5}: weight_buffer_K[0][5] <= w_K;
                {3'd0,3'd6}: weight_buffer_K[0][6] <= w_K;
                {3'd0,3'd7}: weight_buffer_K[0][7] <= w_K;
            endcase
        end
    end
    //row2
    always @(posedge g_weight_k_clk[1]) begin
        if(cs == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_K[1][j] <= 0;
                // end
            end
        end
        else if(cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd1,3'd0}: weight_buffer_K[1][0] <= w_K;
                {3'd1,3'd1}: weight_buffer_K[1][1] <= w_K;
                {3'd1,3'd2}: weight_buffer_K[1][2] <= w_K;
                {3'd1,3'd3}: weight_buffer_K[1][3] <= w_K;
                {3'd1,3'd4}: weight_buffer_K[1][4] <= w_K;
                {3'd1,3'd5}: weight_buffer_K[1][5] <= w_K;
                {3'd1,3'd6}: weight_buffer_K[1][6] <= w_K;
                {3'd1,3'd7}: weight_buffer_K[1][7] <= w_K;
            endcase
        end
    end
    //row3
    always @(posedge g_weight_k_clk[2]) begin
        if(cs == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_K[2][j] <= 0;
                // end
            end
        end
        else if(cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd2,3'd0}: weight_buffer_K[2][0] <= w_K;
                {3'd2,3'd1}: weight_buffer_K[2][1] <= w_K;
                {3'd2,3'd2}: weight_buffer_K[2][2] <= w_K;
                {3'd2,3'd3}: weight_buffer_K[2][3] <= w_K;
                {3'd2,3'd4}: weight_buffer_K[2][4] <= w_K;
                {3'd2,3'd5}: weight_buffer_K[2][5] <= w_K;
                {3'd2,3'd6}: weight_buffer_K[2][6] <= w_K;
                {3'd2,3'd7}: weight_buffer_K[2][7] <= w_K;
            endcase
        end
    end
    //row4
    always @(posedge g_weight_k_clk[3]) begin
        if(cs == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_K[3][j] <= 0;
                // end
            end
        end
        else if(cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd3,3'd0}: weight_buffer_K[3][0] <= w_K;
                {3'd3,3'd1}: weight_buffer_K[3][1] <= w_K;
                {3'd3,3'd2}: weight_buffer_K[3][2] <= w_K;
                {3'd3,3'd3}: weight_buffer_K[3][3] <= w_K;
                {3'd3,3'd4}: weight_buffer_K[3][4] <= w_K;
                {3'd3,3'd5}: weight_buffer_K[3][5] <= w_K;
                {3'd3,3'd6}: weight_buffer_K[3][6] <= w_K;
                {3'd3,3'd7}: weight_buffer_K[3][7] <= w_K;
            endcase
        end
    end
    //row5
    always @(posedge g_weight_k_clk[4]) begin
        if(cs == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_K[4][j] <= 0;
                // end
            end
        end
        else if(cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd4,3'd0}: weight_buffer_K[4][0] <= w_K;
                {3'd4,3'd1}: weight_buffer_K[4][1] <= w_K;
                {3'd4,3'd2}: weight_buffer_K[4][2] <= w_K;
                {3'd4,3'd3}: weight_buffer_K[4][3] <= w_K;
                {3'd4,3'd4}: weight_buffer_K[4][4] <= w_K;
                {3'd4,3'd5}: weight_buffer_K[4][5] <= w_K;
                {3'd4,3'd6}: weight_buffer_K[4][6] <= w_K;
                {3'd4,3'd7}: weight_buffer_K[4][7] <= w_K;
            endcase
        end
    end
    //row6
    always @(posedge g_weight_k_clk[5]) begin
        if(cs == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_K[5][j] <= 0;
                // end
            end
        end
        else if(cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd5,3'd0}: weight_buffer_K[5][0] <= w_K;
                {3'd5,3'd1}: weight_buffer_K[5][1] <= w_K;
                {3'd5,3'd2}: weight_buffer_K[5][2] <= w_K;
                {3'd5,3'd3}: weight_buffer_K[5][3] <= w_K;
                {3'd5,3'd4}: weight_buffer_K[5][4] <= w_K;
                {3'd5,3'd5}: weight_buffer_K[5][5] <= w_K;
                {3'd5,3'd6}: weight_buffer_K[5][6] <= w_K;
                {3'd5,3'd7}: weight_buffer_K[5][7] <= w_K;
            endcase
        end
    end
    //row7
    always @(posedge g_weight_k_clk[6]) begin
        if(cs == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_K[6][j] <= 0;
                // end
            end
        end
        else if(cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd6,3'd0}: weight_buffer_K[6][0] <= w_K;
                {3'd6,3'd1}: weight_buffer_K[6][1] <= w_K;
                {3'd6,3'd2}: weight_buffer_K[6][2] <= w_K;
                {3'd6,3'd3}: weight_buffer_K[6][3] <= w_K;
                {3'd6,3'd4}: weight_buffer_K[6][4] <= w_K;
                {3'd6,3'd5}: weight_buffer_K[6][5] <= w_K;
                {3'd6,3'd6}: weight_buffer_K[6][6] <= w_K;
                {3'd6,3'd7}: weight_buffer_K[6][7] <= w_K;
            endcase
        end
    end
    //row8
    always @(posedge g_weight_k_clk[7]) begin
        if(cs == IDLE)begin
            // for(i = 0; i < 8; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    weight_buffer_K[7][j] <= 0;
                // end
            end
        end
        else if(cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd7,3'd0}: weight_buffer_K[7][0] <= w_K;
                {3'd7,3'd1}: weight_buffer_K[7][1] <= w_K;
                {3'd7,3'd2}: weight_buffer_K[7][2] <= w_K;
                {3'd7,3'd3}: weight_buffer_K[7][3] <= w_K;
                {3'd7,3'd4}: weight_buffer_K[7][4] <= w_K;
                {3'd7,3'd5}: weight_buffer_K[7][5] <= w_K;
                {3'd7,3'd6}: weight_buffer_K[7][6] <= w_K;
                {3'd7,3'd7}: weight_buffer_K[7][7] <= w_K; 
            endcase
        end
    end
//Img buffer
    //row1
    always @(posedge g_img_clk[0] ) begin
        if(ns == IDLE)begin
            for(i = 0; i < 8; i = i + 1)begin
                img_row1_buffer[i] <= 0;
            end
        end
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd0,3'd0}: img_row1_buffer[0] <= in_data;
                {3'd0,3'd1}: img_row1_buffer[1] <= in_data;
                {3'd0,3'd2}: img_row1_buffer[2] <= in_data;
                {3'd0,3'd3}: img_row1_buffer[3] <= in_data;
                {3'd0,3'd4}: img_row1_buffer[4] <= in_data;
                {3'd0,3'd5}: img_row1_buffer[5] <= in_data;
                {3'd0,3'd6}: img_row1_buffer[6] <= in_data;
                {3'd0,3'd7}: img_row1_buffer[7] <= in_data;
            endcase
        end
        // else if(cs == MAT_MUL_2 || cs == OUT)begin
        //     for(i = 0; i < 8; i = i + 1)begin
        //         img_row1_buffer[i] <= ~img_row1_buffer[i];
        //     end
        // end
    end
    //row2
    always @(posedge g_img_clk[1] ) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 3; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    img_row2to4_buffer[0][j] <= 0;
                end
            // end
        end
        // else if(T_buffer == 0)begin
        //     img_row2to4_buffer[0][0] <= ~img_row2to4_buffer[0][0];
        //     img_row2to4_buffer[0][1] <= ~img_row2to4_buffer[0][1];
        //     img_row2to4_buffer[0][2] <= ~img_row2to4_buffer[0][2];
        //     img_row2to4_buffer[0][3] <= ~img_row2to4_buffer[0][3];
        //     img_row2to4_buffer[0][4] <= ~img_row2to4_buffer[0][4];
        //     img_row2to4_buffer[0][5] <= ~img_row2to4_buffer[0][5];
        //     img_row2to4_buffer[0][6] <= ~img_row2to4_buffer[0][6];
        //     img_row2to4_buffer[0][7] <= ~img_row2to4_buffer[0][7];
        // end
        else if(ns == READ_WEIGHT_Q || cs ==READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd1,3'd0}: img_row2to4_buffer[0][0] <= in_data;
                {3'd1,3'd1}: img_row2to4_buffer[0][1] <= in_data;
                {3'd1,3'd2}: img_row2to4_buffer[0][2] <= in_data;
                {3'd1,3'd3}: img_row2to4_buffer[0][3] <= in_data;
                {3'd1,3'd4}: img_row2to4_buffer[0][4] <= in_data;
                {3'd1,3'd5}: img_row2to4_buffer[0][5] <= in_data;
                {3'd1,3'd6}: img_row2to4_buffer[0][6] <= in_data;
                {3'd1,3'd7}: img_row2to4_buffer[0][7] <= in_data;
            endcase
        end
        // else if(cs == MAT_MUL_2 || cs == OUT)begin
        //     for(j = 0; j < 8; j = j + 1)begin
        //         img_row2to4_buffer[0][j] <= ~img_row2to4_buffer[0][j];
        //     end
        // end
    end
    //row3
    always @(posedge g_img_clk[2] ) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 3; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    img_row2to4_buffer[1][j] <= 0;
                end
            // end
        end
        // else if(T_buffer == 0)begin
        //     img_row2to4_buffer[1][0] <= ~img_row2to4_buffer[1][0];
        //     img_row2to4_buffer[1][1] <= ~img_row2to4_buffer[1][1];
        //     img_row2to4_buffer[1][2] <= ~img_row2to4_buffer[1][2];
        //     img_row2to4_buffer[1][3] <= ~img_row2to4_buffer[1][3];
        //     img_row2to4_buffer[1][4] <= ~img_row2to4_buffer[1][4];
        //     img_row2to4_buffer[1][5] <= ~img_row2to4_buffer[1][5];
        //     img_row2to4_buffer[1][6] <= ~img_row2to4_buffer[1][6];
        //     img_row2to4_buffer[1][7] <= ~img_row2to4_buffer[1][7];
        // end
        else if(ns == READ_WEIGHT_Q || cs ==READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd2,3'd0}: img_row2to4_buffer[1][0] <= in_data;
                {3'd2,3'd1}: img_row2to4_buffer[1][1] <= in_data;
                {3'd2,3'd2}: img_row2to4_buffer[1][2] <= in_data;
                {3'd2,3'd3}: img_row2to4_buffer[1][3] <= in_data;
                {3'd2,3'd4}: img_row2to4_buffer[1][4] <= in_data;
                {3'd2,3'd5}: img_row2to4_buffer[1][5] <= in_data;
                {3'd2,3'd6}: img_row2to4_buffer[1][6] <= in_data;
                {3'd2,3'd7}: img_row2to4_buffer[1][7] <= in_data;
            endcase
        end
        // else if(cs == MAT_MUL_2 || cs == OUT)begin
        //     for(j = 0; j < 8; j = j + 1)begin
        //         img_row2to4_buffer[1][j] <= ~img_row2to4_buffer[1][j];
        //     end
        // end
    end
    //row4
    always @(posedge g_img_clk[3] ) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 3; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    img_row2to4_buffer[2][j] <= 0;
                end
            // end
        end
        // else if(T_buffer == 0)begin
        //     img_row2to4_buffer[2][0] <= ~img_row2to4_buffer[2][0];
        //     img_row2to4_buffer[2][1] <= ~img_row2to4_buffer[2][1];
        //     img_row2to4_buffer[2][2] <= ~img_row2to4_buffer[2][2];
        //     img_row2to4_buffer[2][3] <= ~img_row2to4_buffer[2][3];
        //     img_row2to4_buffer[2][4] <= ~img_row2to4_buffer[2][4];
        //     img_row2to4_buffer[2][5] <= ~img_row2to4_buffer[2][5];
        //     img_row2to4_buffer[2][6] <= ~img_row2to4_buffer[2][6];
        //     img_row2to4_buffer[2][7] <= ~img_row2to4_buffer[2][7];
        // end
        else if(ns == READ_WEIGHT_Q || cs ==READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd3,3'd0}: img_row2to4_buffer[2][0] <= in_data;
                {3'd3,3'd1}: img_row2to4_buffer[2][1] <= in_data;
                {3'd3,3'd2}: img_row2to4_buffer[2][2] <= in_data;
                {3'd3,3'd3}: img_row2to4_buffer[2][3] <= in_data;
                {3'd3,3'd4}: img_row2to4_buffer[2][4] <= in_data;
                {3'd3,3'd5}: img_row2to4_buffer[2][5] <= in_data;
                {3'd3,3'd6}: img_row2to4_buffer[2][6] <= in_data;
                {3'd3,3'd7}: img_row2to4_buffer[2][7] <= in_data;
            endcase
        end
        // else if(cs == MAT_MUL_2 || cs == OUT)begin
        //     for(j = 0; j < 8; j = j + 1)begin
        //         img_row2to4_buffer[2][j] <= ~img_row2to4_buffer[2][j];
        //     end
        // end
    end
    //row5
    always @(posedge g_img_clk[4] ) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 4; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    img_row5to8_buffer[0][j] <= 0;
                end
            // end
        end
        // else if(T_buffer != 2)begin
        //     img_row5to8_buffer[0][0] <= ~img_row5to8_buffer[0][0];
        //     img_row5to8_buffer[0][1] <= ~img_row5to8_buffer[0][1];
        //     img_row5to8_buffer[0][2] <= ~img_row5to8_buffer[0][2];
        //     img_row5to8_buffer[0][3] <= ~img_row5to8_buffer[0][3];
        //     img_row5to8_buffer[0][4] <= ~img_row5to8_buffer[0][4];
        //     img_row5to8_buffer[0][5] <= ~img_row5to8_buffer[0][5];
        //     img_row5to8_buffer[0][6] <= ~img_row5to8_buffer[0][6];
        //     img_row5to8_buffer[0][7] <= ~img_row5to8_buffer[0][7];
        // end
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd4,3'd0}: img_row5to8_buffer[0][0] <= in_data;
                {3'd4,3'd1}: img_row5to8_buffer[0][1] <= in_data;
                {3'd4,3'd2}: img_row5to8_buffer[0][2] <= in_data;
                {3'd4,3'd3}: img_row5to8_buffer[0][3] <= in_data;
                {3'd4,3'd4}: img_row5to8_buffer[0][4] <= in_data;
                {3'd4,3'd5}: img_row5to8_buffer[0][5] <= in_data;
                {3'd4,3'd6}: img_row5to8_buffer[0][6] <= in_data;
                {3'd4,3'd7}: img_row5to8_buffer[0][7] <= in_data;
            endcase
        end
        // else if(cs == MAT_MUL_2 || cs == OUT)begin
        //     for(j = 0; j < 8; j = j + 1)begin
        //         img_row5to8_buffer[0][j] <= ~img_row5to8_buffer[0][j];
        //     end
        // end
    end
    //row6
    always @(posedge g_img_clk[5] ) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 4; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    img_row5to8_buffer[1][j] <= 0;
                end
            // end
        end
        // else if(T_buffer != 2)begin
        //     img_row5to8_buffer[1][0] <= ~img_row5to8_buffer[1][0];
        //     img_row5to8_buffer[1][1] <= ~img_row5to8_buffer[1][1];
        //     img_row5to8_buffer[1][2] <= ~img_row5to8_buffer[1][2];
        //     img_row5to8_buffer[1][3] <= ~img_row5to8_buffer[1][3];
        //     img_row5to8_buffer[1][4] <= ~img_row5to8_buffer[1][4];
        //     img_row5to8_buffer[1][5] <= ~img_row5to8_buffer[1][5];
        //     img_row5to8_buffer[1][6] <= ~img_row5to8_buffer[1][6];
        //     img_row5to8_buffer[1][7] <= ~img_row5to8_buffer[1][7];
        // end
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd5,3'd0}: img_row5to8_buffer[1][0] <= in_data;
                {3'd5,3'd1}: img_row5to8_buffer[1][1] <= in_data;
                {3'd5,3'd2}: img_row5to8_buffer[1][2] <= in_data;
                {3'd5,3'd3}: img_row5to8_buffer[1][3] <= in_data;
                {3'd5,3'd4}: img_row5to8_buffer[1][4] <= in_data;
                {3'd5,3'd5}: img_row5to8_buffer[1][5] <= in_data;
                {3'd5,3'd6}: img_row5to8_buffer[1][6] <= in_data;
                {3'd5,3'd7}: img_row5to8_buffer[1][7] <= in_data;
            endcase
        end
        // else if(cs == MAT_MUL_2 || cs == OUT)begin
        //     for(j = 0; j < 8; j = j + 1)begin
        //         img_row5to8_buffer[1][j] <= ~img_row5to8_buffer[1][j];
        //     end
        // end
    end
    //row7
    always @(posedge g_img_clk[6] ) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 4; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    img_row5to8_buffer[2][j] <= 0;
                end
            // end
        end
        // else if(T_buffer != 2)begin
        //     img_row5to8_buffer[2][0] <= ~img_row5to8_buffer[2][0];
        //     img_row5to8_buffer[2][1] <= ~img_row5to8_buffer[2][1];
        //     img_row5to8_buffer[2][2] <= ~img_row5to8_buffer[2][2];
        //     img_row5to8_buffer[2][3] <= ~img_row5to8_buffer[2][3];
        //     img_row5to8_buffer[2][4] <= ~img_row5to8_buffer[2][4];
        //     img_row5to8_buffer[2][5] <= ~img_row5to8_buffer[2][5];
        //     img_row5to8_buffer[2][6] <= ~img_row5to8_buffer[2][6];
        //     img_row5to8_buffer[2][7] <= ~img_row5to8_buffer[2][7];
        // end
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd6,3'd0}: img_row5to8_buffer[2][0] <= in_data;
                {3'd6,3'd1}: img_row5to8_buffer[2][1] <= in_data;
                {3'd6,3'd2}: img_row5to8_buffer[2][2] <= in_data;
                {3'd6,3'd3}: img_row5to8_buffer[2][3] <= in_data;
                {3'd6,3'd4}: img_row5to8_buffer[2][4] <= in_data;
                {3'd6,3'd5}: img_row5to8_buffer[2][5] <= in_data;
                {3'd6,3'd6}: img_row5to8_buffer[2][6] <= in_data;
                {3'd6,3'd7}: img_row5to8_buffer[2][7] <= in_data;
            endcase
        end
        // else if(cs == MAT_MUL_2 || cs == OUT)begin
        //     for(j = 0; j < 8; j = j + 1)begin
        //         img_row5to8_buffer[2][j] <= ~img_row5to8_buffer[2][j];
        //     end
        // end
    end
    //row8
    always @(posedge g_img_clk[7] ) begin
        if(ns == IDLE)begin
            // for(i = 0; i < 4; i = i + 1)begin
                for(j = 0; j < 8; j = j + 1)begin
                    img_row5to8_buffer[3][j] <= 0;
                end
            // end
        end
        // else if(T_buffer != 2)begin
        //     img_row5to8_buffer[3][0] <= ~img_row5to8_buffer[3][0];
        //     img_row5to8_buffer[3][1] <= ~img_row5to8_buffer[3][1];
        //     img_row5to8_buffer[3][2] <= ~img_row5to8_buffer[3][2];
        //     img_row5to8_buffer[3][3] <= ~img_row5to8_buffer[3][3];
        //     img_row5to8_buffer[3][4] <= ~img_row5to8_buffer[3][4];
        //     img_row5to8_buffer[3][5] <= ~img_row5to8_buffer[3][5];
        //     img_row5to8_buffer[3][6] <= ~img_row5to8_buffer[3][6];
        //     img_row5to8_buffer[3][7] <= ~img_row5to8_buffer[3][7];
        // end
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            case ({cnt_y, cnt_x})
                {3'd7,3'd0}: img_row5to8_buffer[3][0] <= in_data;
                {3'd7,3'd1}: img_row5to8_buffer[3][1] <= in_data;
                {3'd7,3'd2}: img_row5to8_buffer[3][2] <= in_data;
                {3'd7,3'd3}: img_row5to8_buffer[3][3] <= in_data;
                {3'd7,3'd4}: img_row5to8_buffer[3][4] <= in_data;
                {3'd7,3'd5}: img_row5to8_buffer[3][5] <= in_data;
                {3'd7,3'd6}: img_row5to8_buffer[3][6] <= in_data;
                {3'd7,3'd7}: img_row5to8_buffer[3][7] <= in_data;
            endcase
        end
        // else if(cs == MAT_MUL_2 || cs == OUT)begin
        //     for(j = 0; j < 8; j = j + 1)begin
        //         img_row5to8_buffer[3][j] <= ~img_row5to8_buffer[3][j];
        //     end
        // end
    end
//==============================================//
// 8x8 Multiplier and Adder
//==============================================//
assign mul_8x8_out[0] = mul_8x8_in1[0] * mul_8x8_in2[0];
assign mul_8x8_out[1] = mul_8x8_in1[1] * mul_8x8_in2[1];
assign mul_8x8_out[2] = mul_8x8_in1[2] * mul_8x8_in2[2];
assign mul_8x8_out[3] = mul_8x8_in1[3] * mul_8x8_in2[3];
assign mul_8x8_out[4] = mul_8x8_in1[4] * mul_8x8_in2[4];
assign mul_8x8_out[5] = mul_8x8_in1[5] * mul_8x8_in2[5];
assign mul_8x8_out[6] = mul_8x8_in1[6] * mul_8x8_in2[6];
assign mul_8x8_out[7] = mul_8x8_in1[7] * mul_8x8_in2[7];
assign add_linear_out = mul_8x8_out[0] + mul_8x8_out[1] + mul_8x8_out[2] + mul_8x8_out[3] + mul_8x8_out[4] + mul_8x8_out[5] + mul_8x8_out[6] + mul_8x8_out[7];
always @(*) begin
    mul_8x8_in1[0] = 0;mul_8x8_in1[1] = 0;mul_8x8_in1[2] = 0;mul_8x8_in1[3] = 0;
    mul_8x8_in1[4] = 0;mul_8x8_in1[5] = 0;mul_8x8_in1[6] = 0;mul_8x8_in1[7] = 0;
    case (cs)
        READ_WEIGHT_K, READ_WEIGHT_V, CAL_V_LINEAR :begin
            case (cnt_y)
                0:begin
                    mul_8x8_in1[0] = img_row1_buffer[0];mul_8x8_in1[1] = img_row1_buffer[1];mul_8x8_in1[2] = img_row1_buffer[2];mul_8x8_in1[3] = img_row1_buffer[3];
                    mul_8x8_in1[4] = img_row1_buffer[4];mul_8x8_in1[5] = img_row1_buffer[5];mul_8x8_in1[6] = img_row1_buffer[6];mul_8x8_in1[7] = img_row1_buffer[7];
                end
                1:begin
                    mul_8x8_in1[0] = img_row2to4_buffer[0][0];mul_8x8_in1[1] = img_row2to4_buffer[0][1];mul_8x8_in1[2] = img_row2to4_buffer[0][2];mul_8x8_in1[3] = img_row2to4_buffer[0][3];
                    mul_8x8_in1[4] = img_row2to4_buffer[0][4];mul_8x8_in1[5] = img_row2to4_buffer[0][5];mul_8x8_in1[6] = img_row2to4_buffer[0][6];mul_8x8_in1[7] = img_row2to4_buffer[0][7];
                end  
                2:begin
                    mul_8x8_in1[0] = img_row2to4_buffer[1][0];mul_8x8_in1[1] = img_row2to4_buffer[1][1];mul_8x8_in1[2] = img_row2to4_buffer[1][2];mul_8x8_in1[3] = img_row2to4_buffer[1][3];
                    mul_8x8_in1[4] = img_row2to4_buffer[1][4];mul_8x8_in1[5] = img_row2to4_buffer[1][5];mul_8x8_in1[6] = img_row2to4_buffer[1][6];mul_8x8_in1[7] = img_row2to4_buffer[1][7];
                end
                3:begin
                    mul_8x8_in1[0] = img_row2to4_buffer[2][0];mul_8x8_in1[1] = img_row2to4_buffer[2][1];mul_8x8_in1[2] = img_row2to4_buffer[2][2];mul_8x8_in1[3] = img_row2to4_buffer[2][3];
                    mul_8x8_in1[4] = img_row2to4_buffer[2][4];mul_8x8_in1[5] = img_row2to4_buffer[2][5];mul_8x8_in1[6] = img_row2to4_buffer[2][6];mul_8x8_in1[7] = img_row2to4_buffer[2][7];
                end
                4:begin
                    mul_8x8_in1[0] = img_row5to8_buffer[0][0];mul_8x8_in1[1] = img_row5to8_buffer[0][1];mul_8x8_in1[2] = img_row5to8_buffer[0][2];mul_8x8_in1[3] = img_row5to8_buffer[0][3];
                    mul_8x8_in1[4] = img_row5to8_buffer[0][4];mul_8x8_in1[5] = img_row5to8_buffer[0][5];mul_8x8_in1[6] = img_row5to8_buffer[0][6];mul_8x8_in1[7] = img_row5to8_buffer[0][7];
                end
                5:begin
                    mul_8x8_in1[0] = img_row5to8_buffer[1][0];mul_8x8_in1[1] = img_row5to8_buffer[1][1];mul_8x8_in1[2] = img_row5to8_buffer[1][2];mul_8x8_in1[3] = img_row5to8_buffer[1][3];
                    mul_8x8_in1[4] = img_row5to8_buffer[1][4];mul_8x8_in1[5] = img_row5to8_buffer[1][5];mul_8x8_in1[6] = img_row5to8_buffer[1][6];mul_8x8_in1[7] = img_row5to8_buffer[1][7];
                end
                6:begin
                    mul_8x8_in1[0] = img_row5to8_buffer[2][0];mul_8x8_in1[1] = img_row5to8_buffer[2][1];mul_8x8_in1[2] = img_row5to8_buffer[2][2];mul_8x8_in1[3] = img_row5to8_buffer[2][3];
                    mul_8x8_in1[4] = img_row5to8_buffer[2][4];mul_8x8_in1[5] = img_row5to8_buffer[2][5];mul_8x8_in1[6] = img_row5to8_buffer[2][6];mul_8x8_in1[7] = img_row5to8_buffer[2][7];
                end
                7:begin
                    mul_8x8_in1[0] = img_row5to8_buffer[3][0];mul_8x8_in1[1] = img_row5to8_buffer[3][1];mul_8x8_in1[2] = img_row5to8_buffer[3][2];mul_8x8_in1[3] = img_row5to8_buffer[3][3];
                    mul_8x8_in1[4] = img_row5to8_buffer[3][4];mul_8x8_in1[5] = img_row5to8_buffer[3][5];mul_8x8_in1[6] = img_row5to8_buffer[3][6];mul_8x8_in1[7] = img_row5to8_buffer[3][7];
                end
            endcase
        end 
        
    endcase
end
always @(*) begin
    mul_8x8_in2[0] = 0;mul_8x8_in2[1] = 0;mul_8x8_in2[2] = 0;mul_8x8_in2[3] = 0;
    mul_8x8_in2[4] = 0;mul_8x8_in2[5] = 0;mul_8x8_in2[6] = 0;mul_8x8_in2[7] = 0;
    case (cs)
        READ_WEIGHT_K, CAL_V_LINEAR :begin
            case (cnt_x)
                0:begin
                    mul_8x8_in2[0] = weight_buffer_Q_V[0][0];mul_8x8_in2[1] = weight_buffer_Q_V[1][0];mul_8x8_in2[2] = weight_buffer_Q_V[2][0];mul_8x8_in2[3] = weight_buffer_Q_V[3][0];
                    mul_8x8_in2[4] = weight_buffer_Q_V[4][0];mul_8x8_in2[5] = weight_buffer_Q_V[5][0];mul_8x8_in2[6] = weight_buffer_Q_V[6][0];mul_8x8_in2[7] = weight_buffer_Q_V[7][0];
                end  
                1:begin
                    mul_8x8_in2[0] = weight_buffer_Q_V[0][1];mul_8x8_in2[1] = weight_buffer_Q_V[1][1];mul_8x8_in2[2] = weight_buffer_Q_V[2][1];mul_8x8_in2[3] = weight_buffer_Q_V[3][1];
                    mul_8x8_in2[4] = weight_buffer_Q_V[4][1];mul_8x8_in2[5] = weight_buffer_Q_V[5][1];mul_8x8_in2[6] = weight_buffer_Q_V[6][1];mul_8x8_in2[7] = weight_buffer_Q_V[7][1];
                end
                2:begin
                    mul_8x8_in2[0] = weight_buffer_Q_V[0][2];mul_8x8_in2[1] = weight_buffer_Q_V[1][2];mul_8x8_in2[2] = weight_buffer_Q_V[2][2];mul_8x8_in2[3] = weight_buffer_Q_V[3][2];
                    mul_8x8_in2[4] = weight_buffer_Q_V[4][2];mul_8x8_in2[5] = weight_buffer_Q_V[5][2];mul_8x8_in2[6] = weight_buffer_Q_V[6][2];mul_8x8_in2[7] = weight_buffer_Q_V[7][2];
                end
                3:begin
                    mul_8x8_in2[0] = weight_buffer_Q_V[0][3];mul_8x8_in2[1] = weight_buffer_Q_V[1][3];mul_8x8_in2[2] = weight_buffer_Q_V[2][3];mul_8x8_in2[3] = weight_buffer_Q_V[3][3];
                    mul_8x8_in2[4] = weight_buffer_Q_V[4][3];mul_8x8_in2[5] = weight_buffer_Q_V[5][3];mul_8x8_in2[6] = weight_buffer_Q_V[6][3];mul_8x8_in2[7] = weight_buffer_Q_V[7][3];
                end
                4:begin
                    mul_8x8_in2[0] = weight_buffer_Q_V[0][4];mul_8x8_in2[1] = weight_buffer_Q_V[1][4];mul_8x8_in2[2] = weight_buffer_Q_V[2][4];mul_8x8_in2[3] = weight_buffer_Q_V[3][4];
                    mul_8x8_in2[4] = weight_buffer_Q_V[4][4];mul_8x8_in2[5] = weight_buffer_Q_V[5][4];mul_8x8_in2[6] = weight_buffer_Q_V[6][4];mul_8x8_in2[7] = weight_buffer_Q_V[7][4];
                end
                5:begin
                    mul_8x8_in2[0] = weight_buffer_Q_V[0][5];mul_8x8_in2[1] = weight_buffer_Q_V[1][5];mul_8x8_in2[2] = weight_buffer_Q_V[2][5];mul_8x8_in2[3] = weight_buffer_Q_V[3][5];
                    mul_8x8_in2[4] = weight_buffer_Q_V[4][5];mul_8x8_in2[5] = weight_buffer_Q_V[5][5];mul_8x8_in2[6] = weight_buffer_Q_V[6][5];mul_8x8_in2[7] = weight_buffer_Q_V[7][5];
                end
                6:begin
                    mul_8x8_in2[0] = weight_buffer_Q_V[0][6];mul_8x8_in2[1] = weight_buffer_Q_V[1][6];mul_8x8_in2[2] = weight_buffer_Q_V[2][6];mul_8x8_in2[3] = weight_buffer_Q_V[3][6];
                    mul_8x8_in2[4] = weight_buffer_Q_V[4][6];mul_8x8_in2[5] = weight_buffer_Q_V[5][6];mul_8x8_in2[6] = weight_buffer_Q_V[6][6];mul_8x8_in2[7] = weight_buffer_Q_V[7][6];
                end
                7:begin
                    mul_8x8_in2[0] = weight_buffer_Q_V[0][7];mul_8x8_in2[1] = weight_buffer_Q_V[1][7];mul_8x8_in2[2] = weight_buffer_Q_V[2][7];mul_8x8_in2[3] = weight_buffer_Q_V[3][7];
                    mul_8x8_in2[4] = weight_buffer_Q_V[4][7];mul_8x8_in2[5] = weight_buffer_Q_V[5][7];mul_8x8_in2[6] = weight_buffer_Q_V[6][7];mul_8x8_in2[7] = weight_buffer_Q_V[7][7];
                end
            endcase
        end  
        READ_WEIGHT_V :begin
            case (cnt_x)
                0:begin
                    mul_8x8_in2[0] = weight_buffer_K[0][0];mul_8x8_in2[1] = weight_buffer_K[1][0];mul_8x8_in2[2] = weight_buffer_K[2][0];mul_8x8_in2[3] = weight_buffer_K[3][0];
                    mul_8x8_in2[4] = weight_buffer_K[4][0];mul_8x8_in2[5] = weight_buffer_K[5][0];mul_8x8_in2[6] = weight_buffer_K[6][0];mul_8x8_in2[7] = weight_buffer_K[7][0];
                end  
                1:begin
                    mul_8x8_in2[0] = weight_buffer_K[0][1];mul_8x8_in2[1] = weight_buffer_K[1][1];mul_8x8_in2[2] = weight_buffer_K[2][1];mul_8x8_in2[3] = weight_buffer_K[3][1];
                    mul_8x8_in2[4] = weight_buffer_K[4][1];mul_8x8_in2[5] = weight_buffer_K[5][1];mul_8x8_in2[6] = weight_buffer_K[6][1];mul_8x8_in2[7] = weight_buffer_K[7][1];
                end
                2:begin
                    mul_8x8_in2[0] = weight_buffer_K[0][2];mul_8x8_in2[1] = weight_buffer_K[1][2];mul_8x8_in2[2] = weight_buffer_K[2][2];mul_8x8_in2[3] = weight_buffer_K[3][2];
                    mul_8x8_in2[4] = weight_buffer_K[4][2];mul_8x8_in2[5] = weight_buffer_K[5][2];mul_8x8_in2[6] = weight_buffer_K[6][2];mul_8x8_in2[7] = weight_buffer_K[7][2];
                end
                3:begin
                    mul_8x8_in2[0] = weight_buffer_K[0][3];mul_8x8_in2[1] = weight_buffer_K[1][3];mul_8x8_in2[2] = weight_buffer_K[2][3];mul_8x8_in2[3] = weight_buffer_K[3][3];
                    mul_8x8_in2[4] = weight_buffer_K[4][3];mul_8x8_in2[5] = weight_buffer_K[5][3];mul_8x8_in2[6] = weight_buffer_K[6][3];mul_8x8_in2[7] = weight_buffer_K[7][3];
                end
                4:begin
                    mul_8x8_in2[0] = weight_buffer_K[0][4];mul_8x8_in2[1] = weight_buffer_K[1][4];mul_8x8_in2[2] = weight_buffer_K[2][4];mul_8x8_in2[3] = weight_buffer_K[3][4];
                    mul_8x8_in2[4] = weight_buffer_K[4][4];mul_8x8_in2[5] = weight_buffer_K[5][4];mul_8x8_in2[6] = weight_buffer_K[6][4];mul_8x8_in2[7] = weight_buffer_K[7][4];
                end
                5:begin
                    mul_8x8_in2[0] = weight_buffer_K[0][5];mul_8x8_in2[1] = weight_buffer_K[1][5];mul_8x8_in2[2] = weight_buffer_K[2][5];mul_8x8_in2[3] = weight_buffer_K[3][5];
                    mul_8x8_in2[4] = weight_buffer_K[4][5];mul_8x8_in2[5] = weight_buffer_K[5][5];mul_8x8_in2[6] = weight_buffer_K[6][5];mul_8x8_in2[7] = weight_buffer_K[7][5];
                end
                6:begin
                    mul_8x8_in2[0] = weight_buffer_K[0][6];mul_8x8_in2[1] = weight_buffer_K[1][6];mul_8x8_in2[2] = weight_buffer_K[2][6];mul_8x8_in2[3] = weight_buffer_K[3][6];
                    mul_8x8_in2[4] = weight_buffer_K[4][6];mul_8x8_in2[5] = weight_buffer_K[5][6];mul_8x8_in2[6] = weight_buffer_K[6][6];mul_8x8_in2[7] = weight_buffer_K[7][6];
                end
                7:begin
                    mul_8x8_in2[0] = weight_buffer_K[0][7];mul_8x8_in2[1] = weight_buffer_K[1][7];mul_8x8_in2[2] = weight_buffer_K[2][7];mul_8x8_in2[3] = weight_buffer_K[3][7];
                    mul_8x8_in2[4] = weight_buffer_K[4][7];mul_8x8_in2[5] = weight_buffer_K[5][7];mul_8x8_in2[6] = weight_buffer_K[6][7];mul_8x8_in2[7] = weight_buffer_K[7][7];
                end 
            endcase
        end
    endcase
end
//==============================================//
// 40x19 Multiplier and Adder
//==============================================//
    assign mul_40x19_out[0] = mul_40x19_in1[0] * mul_40x19_in2[0];
    assign mul_40x19_out[1] = mul_40x19_in1[1] * mul_40x19_in2[1];
    assign mul_40x19_out[2] = mul_40x19_in1[2] * mul_40x19_in2[2];
    assign mul_40x19_out[3] = mul_40x19_in1[3] * mul_40x19_in2[3];
    assign mul_40x19_out[4] = mul_40x19_in1[4] * mul_40x19_in2[4];
    assign mul_40x19_out[5] = mul_40x19_in1[5] * mul_40x19_in2[5];
    assign mul_40x19_out[6] = mul_40x19_in1[6] * mul_40x19_in2[6];
    assign mul_40x19_out[7] = mul_40x19_in1[7] * mul_40x19_in2[7];
    assign add_mat_out = mul_40x19_out[0] + mul_40x19_out[1] + mul_40x19_out[2] + mul_40x19_out[3] + mul_40x19_out[4] + mul_40x19_out[5] + mul_40x19_out[6] + mul_40x19_out[7];
    always @(*) begin
        mul_40x19_in1[0] = 0;mul_40x19_in1[1] = 0;mul_40x19_in1[2] = 0;mul_40x19_in1[3] = 0;
        mul_40x19_in1[4] = 0;mul_40x19_in1[5] = 0;mul_40x19_in1[6] = 0;mul_40x19_in1[7] = 0;
        case (cs)
            CAL_V_LINEAR :begin
                case (T_buffer)
                    'd0:begin
                        mul_40x19_in1[0] = linear_Q_row1_reg[0];mul_40x19_in1[1] = linear_Q_row1_reg[1];mul_40x19_in1[2] = linear_Q_row1_reg[2];mul_40x19_in1[3] = linear_Q_row1_reg[3];
                        mul_40x19_in1[4] = linear_Q_row1_reg[4];mul_40x19_in1[5] = linear_Q_row1_reg[5];mul_40x19_in1[6] = linear_Q_row1_reg[6];mul_40x19_in1[7] = linear_Q_row1_reg[7];
                    end
                    'd1:begin
                        case ({cnt_y, cnt_x})
                            {3'd0, 3'd0}, {3'd0, 3'd1}, {3'd0, 3'd2}, {3'd0, 3'd3}:begin
                                mul_40x19_in1[0] = linear_Q_row1_reg[0];mul_40x19_in1[1] = linear_Q_row1_reg[1];mul_40x19_in1[2] = linear_Q_row1_reg[2];mul_40x19_in1[3] = linear_Q_row1_reg[3];
                                mul_40x19_in1[4] = linear_Q_row1_reg[4];mul_40x19_in1[5] = linear_Q_row1_reg[5];mul_40x19_in1[6] = linear_Q_row1_reg[6];mul_40x19_in1[7] = linear_Q_row1_reg[7];
                            end 
                            {3'd0, 3'd4}, {3'd0, 3'd5}, {3'd0, 3'd6}, {3'd0, 3'd7}:begin
                                mul_40x19_in1[0] = linear_Q_row2to4_reg[0][0];mul_40x19_in1[1] = linear_Q_row2to4_reg[0][1];mul_40x19_in1[2] = linear_Q_row2to4_reg[0][2];mul_40x19_in1[3] = linear_Q_row2to4_reg[0][3];
                                mul_40x19_in1[4] = linear_Q_row2to4_reg[0][4];mul_40x19_in1[5] = linear_Q_row2to4_reg[0][5];mul_40x19_in1[6] = linear_Q_row2to4_reg[0][6];mul_40x19_in1[7] = linear_Q_row2to4_reg[0][7];
                            end
                            {3'd1, 3'd0}, {3'd1, 3'd1}, {3'd1, 3'd2}, {3'd1, 3'd3}:begin
                                mul_40x19_in1[0] = linear_Q_row2to4_reg[1][0];mul_40x19_in1[1] = linear_Q_row2to4_reg[1][1];mul_40x19_in1[2] = linear_Q_row2to4_reg[1][2];mul_40x19_in1[3] = linear_Q_row2to4_reg[1][3];
                                mul_40x19_in1[4] = linear_Q_row2to4_reg[1][4];mul_40x19_in1[5] = linear_Q_row2to4_reg[1][5];mul_40x19_in1[6] = linear_Q_row2to4_reg[1][6];mul_40x19_in1[7] = linear_Q_row2to4_reg[1][7];
                            end
                            {3'd1, 3'd4}, {3'd1, 3'd5}, {3'd1, 3'd6}, {3'd1, 3'd7}:begin
                                mul_40x19_in1[0] = linear_Q_row2to4_reg[2][0];mul_40x19_in1[1] = linear_Q_row2to4_reg[2][1];mul_40x19_in1[2] = linear_Q_row2to4_reg[2][2];mul_40x19_in1[3] = linear_Q_row2to4_reg[2][3];
                                mul_40x19_in1[4] = linear_Q_row2to4_reg[2][4];mul_40x19_in1[5] = linear_Q_row2to4_reg[2][5];mul_40x19_in1[6] = linear_Q_row2to4_reg[2][6];mul_40x19_in1[7] = linear_Q_row2to4_reg[2][7];
                            end
                        endcase
                    end
                    'd2:begin
                        case (cnt_y)
                            0:begin
                                mul_40x19_in1[0] = linear_Q_row1_reg[0];mul_40x19_in1[1] = linear_Q_row1_reg[1];mul_40x19_in1[2] = linear_Q_row1_reg[2];mul_40x19_in1[3] = linear_Q_row1_reg[3];
                                mul_40x19_in1[4] = linear_Q_row1_reg[4];mul_40x19_in1[5] = linear_Q_row1_reg[5];mul_40x19_in1[6] = linear_Q_row1_reg[6];mul_40x19_in1[7] = linear_Q_row1_reg[7];
                            end
                            1:begin
                                mul_40x19_in1[0] = linear_Q_row2to4_reg[0][0];mul_40x19_in1[1] = linear_Q_row2to4_reg[0][1];mul_40x19_in1[2] = linear_Q_row2to4_reg[0][2];mul_40x19_in1[3] = linear_Q_row2to4_reg[0][3];
                                mul_40x19_in1[4] = linear_Q_row2to4_reg[0][4];mul_40x19_in1[5] = linear_Q_row2to4_reg[0][5];mul_40x19_in1[6] = linear_Q_row2to4_reg[0][6];mul_40x19_in1[7] = linear_Q_row2to4_reg[0][7];
                            end  
                            2:begin
                                mul_40x19_in1[0] = linear_Q_row2to4_reg[1][0];mul_40x19_in1[1] = linear_Q_row2to4_reg[1][1];mul_40x19_in1[2] = linear_Q_row2to4_reg[1][2];mul_40x19_in1[3] = linear_Q_row2to4_reg[1][3];
                                mul_40x19_in1[4] = linear_Q_row2to4_reg[1][4];mul_40x19_in1[5] = linear_Q_row2to4_reg[1][5];mul_40x19_in1[6] = linear_Q_row2to4_reg[1][6];mul_40x19_in1[7] = linear_Q_row2to4_reg[1][7];
                            end
                            3:begin
                                mul_40x19_in1[0] = linear_Q_row2to4_reg[2][0];mul_40x19_in1[1] = linear_Q_row2to4_reg[2][1];mul_40x19_in1[2] = linear_Q_row2to4_reg[2][2];mul_40x19_in1[3] = linear_Q_row2to4_reg[2][3];
                                mul_40x19_in1[4] = linear_Q_row2to4_reg[2][4];mul_40x19_in1[5] = linear_Q_row2to4_reg[2][5];mul_40x19_in1[6] = linear_Q_row2to4_reg[2][6];mul_40x19_in1[7] = linear_Q_row2to4_reg[2][7];
                            end
                            4:begin
                                mul_40x19_in1[0] = linear_Q_row5to8_reg[0][0];mul_40x19_in1[1] = linear_Q_row5to8_reg[0][1];mul_40x19_in1[2] = linear_Q_row5to8_reg[0][2];mul_40x19_in1[3] = linear_Q_row5to8_reg[0][3];
                                mul_40x19_in1[4] = linear_Q_row5to8_reg[0][4];mul_40x19_in1[5] = linear_Q_row5to8_reg[0][5];mul_40x19_in1[6] = linear_Q_row5to8_reg[0][6];mul_40x19_in1[7] = linear_Q_row5to8_reg[0][7];
                            end
                            5:begin
                                mul_40x19_in1[0] = linear_Q_row5to8_reg[1][0];mul_40x19_in1[1] = linear_Q_row5to8_reg[1][1];mul_40x19_in1[2] = linear_Q_row5to8_reg[1][2];mul_40x19_in1[3] = linear_Q_row5to8_reg[1][3];
                                mul_40x19_in1[4] = linear_Q_row5to8_reg[1][4];mul_40x19_in1[5] = linear_Q_row5to8_reg[1][5];mul_40x19_in1[6] = linear_Q_row5to8_reg[1][6];mul_40x19_in1[7] = linear_Q_row5to8_reg[1][7];
                            end
                            6:begin
                                mul_40x19_in1[0] = linear_Q_row5to8_reg[2][0];mul_40x19_in1[1] = linear_Q_row5to8_reg[2][1];mul_40x19_in1[2] = linear_Q_row5to8_reg[2][2];mul_40x19_in1[3] = linear_Q_row5to8_reg[2][3];
                                mul_40x19_in1[4] = linear_Q_row5to8_reg[2][4];mul_40x19_in1[5] = linear_Q_row5to8_reg[2][5];mul_40x19_in1[6] = linear_Q_row5to8_reg[2][6];mul_40x19_in1[7] = linear_Q_row5to8_reg[2][7];
                            end
                            7:begin
                                mul_40x19_in1[0] = linear_Q_row5to8_reg[3][0];mul_40x19_in1[1] = linear_Q_row5to8_reg[3][1];mul_40x19_in1[2] = linear_Q_row5to8_reg[3][2];mul_40x19_in1[3] = linear_Q_row5to8_reg[3][3];
                                mul_40x19_in1[4] = linear_Q_row5to8_reg[3][4];mul_40x19_in1[5] = linear_Q_row5to8_reg[3][5];mul_40x19_in1[6] = linear_Q_row5to8_reg[3][6];mul_40x19_in1[7] = linear_Q_row5to8_reg[3][7];
                            end
                        endcase
                    end  
                endcase
                
            end 
            MAT_MUL_2,OUT :begin
                // case (T_buffer)
                //     'd0:begin
                //         mul_40x19_in1[0] = S_row1_reg[0];mul_40x19_in1[1] = S_row1_reg[0];mul_40x19_in1[2] = S_row1_reg[0];mul_40x19_in1[3] = S_row1_reg[0];
                //         mul_40x19_in1[4] = S_row1_reg[0];mul_40x19_in1[5] = S_row1_reg[0];mul_40x19_in1[6] = S_row1_reg[0];mul_40x19_in1[7] = S_row1_reg[0];
                //     end  
                //     'd1:begin
                //         case (cnt_y)
                //             0:begin
                //                 mul_40x19_in1[0] = S_row1_reg[0];mul_40x19_in1[1] = S_row1_reg[1];mul_40x19_in1[2] = S_row1_reg[2];mul_40x19_in1[3] = S_row1_reg[3];
                //                 mul_40x19_in1[4] = S_row1_reg[4];mul_40x19_in1[5] = S_row1_reg[5];mul_40x19_in1[6] = S_row1_reg[6];mul_40x19_in1[7] = S_row1_reg[7];
                //             end 
                //             1:begin
                //                 mul_40x19_in1[0] = S_row2to4_reg[0][0];mul_40x19_in1[1] = S_row2to4_reg[0][1];mul_40x19_in1[2] = S_row2to4_reg[0][2];mul_40x19_in1[3] = S_row2to4_reg[0][3];
                //                 mul_40x19_in1[4] = S_row2to4_reg[0][4];mul_40x19_in1[5] = S_row2to4_reg[0][5];mul_40x19_in1[6] = S_row2to4_reg[0][6];mul_40x19_in1[7] = S_row2to4_reg[0][7];
                //             end
                //             2:begin
                //                 mul_40x19_in1[0] = S_row2to4_reg[1][0];mul_40x19_in1[1] = S_row2to4_reg[1][1];mul_40x19_in1[2] = S_row2to4_reg[1][2];mul_40x19_in1[3] = S_row2to4_reg[1][3];
                //                 mul_40x19_in1[4] = S_row2to4_reg[1][4];mul_40x19_in1[5] = S_row2to4_reg[1][5];mul_40x19_in1[6] = S_row2to4_reg[1][6];mul_40x19_in1[7] = S_row2to4_reg[1][7];
                //             end
                //             3:begin
                //                 mul_40x19_in1[0] = S_row2to4_reg[2][0];mul_40x19_in1[1] = S_row2to4_reg[2][1];mul_40x19_in1[2] = S_row2to4_reg[2][2];mul_40x19_in1[3] = S_row2to4_reg[2][3];
                //                 mul_40x19_in1[4] = S_row2to4_reg[2][4];mul_40x19_in1[5] = S_row2to4_reg[2][5];mul_40x19_in1[6] = S_row2to4_reg[2][6];mul_40x19_in1[7] = S_row2to4_reg[2][7];
                //             end
                //         endcase
                //     end
                //     'd2:begin
                        case (cnt_y)
                            0:begin
                                mul_40x19_in1[0] = S_row1_reg[0];mul_40x19_in1[1] = S_row1_reg[1];mul_40x19_in1[2] = S_row1_reg[2];mul_40x19_in1[3] = S_row1_reg[3];
                                mul_40x19_in1[4] = S_row1_reg[4];mul_40x19_in1[5] = S_row1_reg[5];mul_40x19_in1[6] = S_row1_reg[6];mul_40x19_in1[7] = S_row1_reg[7];
                            end 
                            1:begin
                                mul_40x19_in1[0] = S_row2to4_reg[0][0];mul_40x19_in1[1] = S_row2to4_reg[0][1];mul_40x19_in1[2] = S_row2to4_reg[0][2];mul_40x19_in1[3] = S_row2to4_reg[0][3];
                                mul_40x19_in1[4] = S_row2to4_reg[0][4];mul_40x19_in1[5] = S_row2to4_reg[0][5];mul_40x19_in1[6] = S_row2to4_reg[0][6];mul_40x19_in1[7] = S_row2to4_reg[0][7];
                            end
                            2:begin
                                mul_40x19_in1[0] = S_row2to4_reg[1][0];mul_40x19_in1[1] = S_row2to4_reg[1][1];mul_40x19_in1[2] = S_row2to4_reg[1][2];mul_40x19_in1[3] = S_row2to4_reg[1][3];
                                mul_40x19_in1[4] = S_row2to4_reg[1][4];mul_40x19_in1[5] = S_row2to4_reg[1][5];mul_40x19_in1[6] = S_row2to4_reg[1][6];mul_40x19_in1[7] = S_row2to4_reg[1][7];
                            end
                            3:begin
                                mul_40x19_in1[0] = S_row2to4_reg[2][0];mul_40x19_in1[1] = S_row2to4_reg[2][1];mul_40x19_in1[2] = S_row2to4_reg[2][2];mul_40x19_in1[3] = S_row2to4_reg[2][3];
                                mul_40x19_in1[4] = S_row2to4_reg[2][4];mul_40x19_in1[5] = S_row2to4_reg[2][5];mul_40x19_in1[6] = S_row2to4_reg[2][6];mul_40x19_in1[7] = S_row2to4_reg[2][7];
                            end
                            4:begin
                                mul_40x19_in1[0] = S_row5to8_reg[0][0];mul_40x19_in1[1] = S_row5to8_reg[0][1];mul_40x19_in1[2] = S_row5to8_reg[0][2];mul_40x19_in1[3] = S_row5to8_reg[0][3];
                                mul_40x19_in1[4] = S_row5to8_reg[0][4];mul_40x19_in1[5] = S_row5to8_reg[0][5];mul_40x19_in1[6] = S_row5to8_reg[0][6];mul_40x19_in1[7] = S_row5to8_reg[0][7];
                            end
                            5:begin
                                mul_40x19_in1[0] = S_row5to8_reg[1][0];mul_40x19_in1[1] = S_row5to8_reg[1][1];mul_40x19_in1[2] = S_row5to8_reg[1][2];mul_40x19_in1[3] = S_row5to8_reg[1][3];
                                mul_40x19_in1[4] = S_row5to8_reg[1][4];mul_40x19_in1[5] = S_row5to8_reg[1][5];mul_40x19_in1[6] = S_row5to8_reg[1][6];mul_40x19_in1[7] = S_row5to8_reg[1][7];
                            end
                            6:begin
                                mul_40x19_in1[0] = S_row5to8_reg[2][0];mul_40x19_in1[1] = S_row5to8_reg[2][1];mul_40x19_in1[2] = S_row5to8_reg[2][2];mul_40x19_in1[3] = S_row5to8_reg[2][3];
                                mul_40x19_in1[4] = S_row5to8_reg[2][4];mul_40x19_in1[5] = S_row5to8_reg[2][5];mul_40x19_in1[6] = S_row5to8_reg[2][6];mul_40x19_in1[7] = S_row5to8_reg[2][7];
                            end
                            7:begin
                                mul_40x19_in1[0] = S_row5to8_reg[3][0];mul_40x19_in1[1] = S_row5to8_reg[3][1];mul_40x19_in1[2] = S_row5to8_reg[3][2];mul_40x19_in1[3] = S_row5to8_reg[3][3];
                                mul_40x19_in1[4] = S_row5to8_reg[3][4];mul_40x19_in1[5] = S_row5to8_reg[3][5];mul_40x19_in1[6] = S_row5to8_reg[3][6];mul_40x19_in1[7] = S_row5to8_reg[3][7];
                            end
                        endcase
                //     end
                // endcase
            end
        endcase
    end
    always @(*) begin
        mul_40x19_in2[0] = 0;mul_40x19_in2[1] = 0;mul_40x19_in2[2] = 0;mul_40x19_in2[3] = 0;
        mul_40x19_in2[4] = 0;mul_40x19_in2[5] = 0;mul_40x19_in2[6] = 0;mul_40x19_in2[7] = 0;
        case (cs)
            CAL_V_LINEAR :begin
                case (T_buffer)
                    'd0:begin
                        mul_40x19_in2[0] = linear_K_row1_reg[0];mul_40x19_in2[1] = linear_K_row1_reg[1];mul_40x19_in2[2] = linear_K_row1_reg[2];mul_40x19_in2[3] = linear_K_row1_reg[3];
                        mul_40x19_in2[4] = linear_K_row1_reg[4];mul_40x19_in2[5] = linear_K_row1_reg[5];mul_40x19_in2[6] = linear_K_row1_reg[6];mul_40x19_in2[7] = linear_K_row1_reg[7];
                    end
                    'd1:begin
                        case (cnt_x)
                            0,4:begin
                                mul_40x19_in2[0] = linear_K_row1_reg[0];mul_40x19_in2[1] = linear_K_row1_reg[1];mul_40x19_in2[2] = linear_K_row1_reg[2];mul_40x19_in2[3] = linear_K_row1_reg[3];
                                mul_40x19_in2[4] = linear_K_row1_reg[4];mul_40x19_in2[5] = linear_K_row1_reg[5];mul_40x19_in2[6] = linear_K_row1_reg[6];mul_40x19_in2[7] = linear_K_row1_reg[7];
                            end  
                            1,5:begin
                                mul_40x19_in2[0] = linear_K_row2to4_reg[0][0];mul_40x19_in2[1] = linear_K_row2to4_reg[0][1];mul_40x19_in2[2] = linear_K_row2to4_reg[0][2];mul_40x19_in2[3] = linear_K_row2to4_reg[0][3];
                                mul_40x19_in2[4] = linear_K_row2to4_reg[0][4];mul_40x19_in2[5] = linear_K_row2to4_reg[0][5];mul_40x19_in2[6] = linear_K_row2to4_reg[0][6];mul_40x19_in2[7] = linear_K_row2to4_reg[0][7];
                            end
                            2,6:begin
                                mul_40x19_in2[0] = linear_K_row2to4_reg[1][0];mul_40x19_in2[1] = linear_K_row2to4_reg[1][1];mul_40x19_in2[2] = linear_K_row2to4_reg[1][2];mul_40x19_in2[3] = linear_K_row2to4_reg[1][3];
                                mul_40x19_in2[4] = linear_K_row2to4_reg[1][4];mul_40x19_in2[5] = linear_K_row2to4_reg[1][5];mul_40x19_in2[6] = linear_K_row2to4_reg[1][6];mul_40x19_in2[7] = linear_K_row2to4_reg[1][7];
                            end
                            3,7:begin
                                mul_40x19_in2[0] = linear_K_row2to4_reg[2][0];mul_40x19_in2[1] = linear_K_row2to4_reg[2][1];mul_40x19_in2[2] = linear_K_row2to4_reg[2][2];mul_40x19_in2[3] = linear_K_row2to4_reg[2][3];
                                mul_40x19_in2[4] = linear_K_row2to4_reg[2][4];mul_40x19_in2[5] = linear_K_row2to4_reg[2][5];mul_40x19_in2[6] = linear_K_row2to4_reg[2][6];mul_40x19_in2[7] = linear_K_row2to4_reg[2][7];
                            end 
                        endcase
                    end
                    'd2:begin
                        case (cnt_x)
                            0:begin
                                mul_40x19_in2[0] = linear_K_row1_reg[0];mul_40x19_in2[1] = linear_K_row1_reg[1];mul_40x19_in2[2] = linear_K_row1_reg[2];mul_40x19_in2[3] = linear_K_row1_reg[3];
                                mul_40x19_in2[4] = linear_K_row1_reg[4];mul_40x19_in2[5] = linear_K_row1_reg[5];mul_40x19_in2[6] = linear_K_row1_reg[6];mul_40x19_in2[7] = linear_K_row1_reg[7];
                            end  
                            1:begin
                                mul_40x19_in2[0] = linear_K_row2to4_reg[0][0];mul_40x19_in2[1] = linear_K_row2to4_reg[0][1];mul_40x19_in2[2] = linear_K_row2to4_reg[0][2];mul_40x19_in2[3] = linear_K_row2to4_reg[0][3];
                                mul_40x19_in2[4] = linear_K_row2to4_reg[0][4];mul_40x19_in2[5] = linear_K_row2to4_reg[0][5];mul_40x19_in2[6] = linear_K_row2to4_reg[0][6];mul_40x19_in2[7] = linear_K_row2to4_reg[0][7];
                            end
                            2:begin
                                mul_40x19_in2[0] = linear_K_row2to4_reg[1][0];mul_40x19_in2[1] = linear_K_row2to4_reg[1][1];mul_40x19_in2[2] = linear_K_row2to4_reg[1][2];mul_40x19_in2[3] = linear_K_row2to4_reg[1][3];
                                mul_40x19_in2[4] = linear_K_row2to4_reg[1][4];mul_40x19_in2[5] = linear_K_row2to4_reg[1][5];mul_40x19_in2[6] = linear_K_row2to4_reg[1][6];mul_40x19_in2[7] = linear_K_row2to4_reg[1][7];
                            end
                            3:begin
                                mul_40x19_in2[0] = linear_K_row2to4_reg[2][0];mul_40x19_in2[1] = linear_K_row2to4_reg[2][1];mul_40x19_in2[2] = linear_K_row2to4_reg[2][2];mul_40x19_in2[3] = linear_K_row2to4_reg[2][3];
                                mul_40x19_in2[4] = linear_K_row2to4_reg[2][4];mul_40x19_in2[5] = linear_K_row2to4_reg[2][5];mul_40x19_in2[6] = linear_K_row2to4_reg[2][6];mul_40x19_in2[7] = linear_K_row2to4_reg[2][7];
                            end
                            4:begin
                                mul_40x19_in2[0] = linear_K_row5to8_reg[0][0];mul_40x19_in2[1] = linear_K_row5to8_reg[0][1];mul_40x19_in2[2] = linear_K_row5to8_reg[0][2];mul_40x19_in2[3] = linear_K_row5to8_reg[0][3];
                                mul_40x19_in2[4] = linear_K_row5to8_reg[0][4];mul_40x19_in2[5] = linear_K_row5to8_reg[0][5];mul_40x19_in2[6] = linear_K_row5to8_reg[0][6];mul_40x19_in2[7] = linear_K_row5to8_reg[0][7];
                            end
                            5:begin
                                mul_40x19_in2[0] = linear_K_row5to8_reg[1][0];mul_40x19_in2[1] = linear_K_row5to8_reg[1][1];mul_40x19_in2[2] = linear_K_row5to8_reg[1][2];mul_40x19_in2[3] = linear_K_row5to8_reg[1][3];
                                mul_40x19_in2[4] = linear_K_row5to8_reg[1][4];mul_40x19_in2[5] = linear_K_row5to8_reg[1][5];mul_40x19_in2[6] = linear_K_row5to8_reg[1][6];mul_40x19_in2[7] = linear_K_row5to8_reg[1][7];
                            end
                            6:begin
                                mul_40x19_in2[0] = linear_K_row5to8_reg[2][0];mul_40x19_in2[1] = linear_K_row5to8_reg[2][1];mul_40x19_in2[2] = linear_K_row5to8_reg[2][2];mul_40x19_in2[3] = linear_K_row5to8_reg[2][3];
                                mul_40x19_in2[4] = linear_K_row5to8_reg[2][4];mul_40x19_in2[5] = linear_K_row5to8_reg[2][5];mul_40x19_in2[6] = linear_K_row5to8_reg[2][6];mul_40x19_in2[7] = linear_K_row5to8_reg[2][7];
                            end
                            7:begin
                                mul_40x19_in2[0] = linear_K_row5to8_reg[3][0];mul_40x19_in2[1] = linear_K_row5to8_reg[3][1];mul_40x19_in2[2] = linear_K_row5to8_reg[3][2];mul_40x19_in2[3] = linear_K_row5to8_reg[3][3];
                                mul_40x19_in2[4] = linear_K_row5to8_reg[3][4];mul_40x19_in2[5] = linear_K_row5to8_reg[3][5];mul_40x19_in2[6] = linear_K_row5to8_reg[3][6];mul_40x19_in2[7] = linear_K_row5to8_reg[3][7];
                            end
                        endcase
                    end  
                endcase
            end  
            MAT_MUL_2,OUT :begin
                case (T_buffer)
                    'd0:begin
                        case (cnt_x)
                            0:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[0]      ;//;mul_40x19_in2[1] = linear_V_row2to4_reg[0][0];mul_40x19_in2[2] = linear_V_row2to4_reg[1][0];mul_40x19_in2[3] = linear_V_row2to4_reg[2][0];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][0];mul_40x19_in2[5] = linear_V_row5to8_reg[1][0];mul_40x19_in2[6] = linear_V_row5to8_reg[2][0];mul_40x19_in2[7] = linear_V_row5to8_reg[3][0];
                            end 
                            1:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[1]      ;//mul_40x19_in2[1] = linear_V_row2to4_reg[0][1];mul_40x19_in2[2] = linear_V_row2to4_reg[1][1];mul_40x19_in2[3] = linear_V_row2to4_reg[2][1];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][1];mul_40x19_in2[5] = linear_V_row5to8_reg[1][1];mul_40x19_in2[6] = linear_V_row5to8_reg[2][1];mul_40x19_in2[7] = linear_V_row5to8_reg[3][1];
                            end
                            2:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[2]      ;//mul_40x19_in2[1] = linear_V_row2to4_reg[0][2];mul_40x19_in2[2] = linear_V_row2to4_reg[1][2];mul_40x19_in2[3] = linear_V_row2to4_reg[2][2];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][2];mul_40x19_in2[5] = linear_V_row5to8_reg[1][2];mul_40x19_in2[6] = linear_V_row5to8_reg[2][2];mul_40x19_in2[7] = linear_V_row5to8_reg[3][2];
                            end
                            3:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[3]      ;//mul_40x19_in2[1] = linear_V_row2to4_reg[0][3];mul_40x19_in2[2] = linear_V_row2to4_reg[1][3];mul_40x19_in2[3] = linear_V_row2to4_reg[2][3];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][3];mul_40x19_in2[5] = linear_V_row5to8_reg[1][3];mul_40x19_in2[6] = linear_V_row5to8_reg[2][3];mul_40x19_in2[7] = linear_V_row5to8_reg[3][3];
                            end
                            4:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[4]      ;//mul_40x19_in2[1] = linear_V_row2to4_reg[0][4];mul_40x19_in2[2] = linear_V_row2to4_reg[1][4];mul_40x19_in2[3] = linear_V_row2to4_reg[2][4];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][4];mul_40x19_in2[5] = linear_V_row5to8_reg[1][4];mul_40x19_in2[6] = linear_V_row5to8_reg[2][4];mul_40x19_in2[7] = linear_V_row5to8_reg[3][4];
                            end
                            5:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[5]      ;//mul_40x19_in2[1] = linear_V_row2to4_reg[0][5];mul_40x19_in2[2] = linear_V_row2to4_reg[1][5];mul_40x19_in2[3] = linear_V_row2to4_reg[2][5];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][5];mul_40x19_in2[5] = linear_V_row5to8_reg[1][5];mul_40x19_in2[6] = linear_V_row5to8_reg[2][5];mul_40x19_in2[7] = linear_V_row5to8_reg[3][5];
                            end
                            6:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[6]      ;//mul_40x19_in2[1] = linear_V_row2to4_reg[0][6];mul_40x19_in2[2] = linear_V_row2to4_reg[1][6];mul_40x19_in2[3] = linear_V_row2to4_reg[2][6];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][6];mul_40x19_in2[5] = linear_V_row5to8_reg[1][6];mul_40x19_in2[6] = linear_V_row5to8_reg[2][6];mul_40x19_in2[7] = linear_V_row5to8_reg[3][6];
                            end
                            7:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[7]      ;//mul_40x19_in2[1] = linear_V_row2to4_reg[0][7];mul_40x19_in2[2] = linear_V_row2to4_reg[1][7];mul_40x19_in2[3] = linear_V_row2to4_reg[2][7];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][7];mul_40x19_in2[5] = linear_V_row5to8_reg[1][7];mul_40x19_in2[6] = linear_V_row5to8_reg[2][7];mul_40x19_in2[7] = linear_V_row5to8_reg[3][7];
                            end 
                        endcase
                    end
                    'd1:begin
                        case (cnt_x)
                            0:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[0]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][0];mul_40x19_in2[2] = linear_V_row2to4_reg[1][0];mul_40x19_in2[3] = linear_V_row2to4_reg[2][0];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][0];mul_40x19_in2[5] = linear_V_row5to8_reg[1][0];mul_40x19_in2[6] = linear_V_row5to8_reg[2][0];mul_40x19_in2[7] = linear_V_row5to8_reg[3][0];
                            end 
                            1:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[1]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][1];mul_40x19_in2[2] = linear_V_row2to4_reg[1][1];mul_40x19_in2[3] = linear_V_row2to4_reg[2][1];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][1];mul_40x19_in2[5] = linear_V_row5to8_reg[1][1];mul_40x19_in2[6] = linear_V_row5to8_reg[2][1];mul_40x19_in2[7] = linear_V_row5to8_reg[3][1];
                            end
                            2:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[2]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][2];mul_40x19_in2[2] = linear_V_row2to4_reg[1][2];mul_40x19_in2[3] = linear_V_row2to4_reg[2][2];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][2];mul_40x19_in2[5] = linear_V_row5to8_reg[1][2];mul_40x19_in2[6] = linear_V_row5to8_reg[2][2];mul_40x19_in2[7] = linear_V_row5to8_reg[3][2];
                            end
                            3:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[3]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][3];mul_40x19_in2[2] = linear_V_row2to4_reg[1][3];mul_40x19_in2[3] = linear_V_row2to4_reg[2][3];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][3];mul_40x19_in2[5] = linear_V_row5to8_reg[1][3];mul_40x19_in2[6] = linear_V_row5to8_reg[2][3];mul_40x19_in2[7] = linear_V_row5to8_reg[3][3];
                            end
                            4:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[4]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][4];mul_40x19_in2[2] = linear_V_row2to4_reg[1][4];mul_40x19_in2[3] = linear_V_row2to4_reg[2][4];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][4];mul_40x19_in2[5] = linear_V_row5to8_reg[1][4];mul_40x19_in2[6] = linear_V_row5to8_reg[2][4];mul_40x19_in2[7] = linear_V_row5to8_reg[3][4];
                            end
                            5:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[5]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][5];mul_40x19_in2[2] = linear_V_row2to4_reg[1][5];mul_40x19_in2[3] = linear_V_row2to4_reg[2][5];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][5];mul_40x19_in2[5] = linear_V_row5to8_reg[1][5];mul_40x19_in2[6] = linear_V_row5to8_reg[2][5];mul_40x19_in2[7] = linear_V_row5to8_reg[3][5];
                            end
                            6:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[6]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][6];mul_40x19_in2[2] = linear_V_row2to4_reg[1][6];mul_40x19_in2[3] = linear_V_row2to4_reg[2][6];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][6];mul_40x19_in2[5] = linear_V_row5to8_reg[1][6];mul_40x19_in2[6] = linear_V_row5to8_reg[2][6];mul_40x19_in2[7] = linear_V_row5to8_reg[3][6];
                            end
                            7:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[7]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][7];mul_40x19_in2[2] = linear_V_row2to4_reg[1][7];mul_40x19_in2[3] = linear_V_row2to4_reg[2][7];
                                // mul_40x19_in2[4] = linear_V_row5to8_reg[0][7];mul_40x19_in2[5] = linear_V_row5to8_reg[1][7];mul_40x19_in2[6] = linear_V_row5to8_reg[2][7];mul_40x19_in2[7] = linear_V_row5to8_reg[3][7];
                            end 
                        endcase
                    end 
                    'd2:begin
                        case (cnt_x)
                            0:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[0]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][0];mul_40x19_in2[2] = linear_V_row2to4_reg[1][0];mul_40x19_in2[3] = linear_V_row2to4_reg[2][0];
                                mul_40x19_in2[4] = linear_V_row5to8_reg[0][0];mul_40x19_in2[5] = linear_V_row5to8_reg[1][0];mul_40x19_in2[6] = linear_V_row5to8_reg[2][0];mul_40x19_in2[7] = linear_V_row5to8_reg[3][0];
                            end 
                            1:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[1]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][1];mul_40x19_in2[2] = linear_V_row2to4_reg[1][1];mul_40x19_in2[3] = linear_V_row2to4_reg[2][1];
                                mul_40x19_in2[4] = linear_V_row5to8_reg[0][1];mul_40x19_in2[5] = linear_V_row5to8_reg[1][1];mul_40x19_in2[6] = linear_V_row5to8_reg[2][1];mul_40x19_in2[7] = linear_V_row5to8_reg[3][1];
                            end
                            2:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[2]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][2];mul_40x19_in2[2] = linear_V_row2to4_reg[1][2];mul_40x19_in2[3] = linear_V_row2to4_reg[2][2];
                                mul_40x19_in2[4] = linear_V_row5to8_reg[0][2];mul_40x19_in2[5] = linear_V_row5to8_reg[1][2];mul_40x19_in2[6] = linear_V_row5to8_reg[2][2];mul_40x19_in2[7] = linear_V_row5to8_reg[3][2];
                            end
                            3:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[3]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][3];mul_40x19_in2[2] = linear_V_row2to4_reg[1][3];mul_40x19_in2[3] = linear_V_row2to4_reg[2][3];
                                mul_40x19_in2[4] = linear_V_row5to8_reg[0][3];mul_40x19_in2[5] = linear_V_row5to8_reg[1][3];mul_40x19_in2[6] = linear_V_row5to8_reg[2][3];mul_40x19_in2[7] = linear_V_row5to8_reg[3][3];
                            end
                            4:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[4]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][4];mul_40x19_in2[2] = linear_V_row2to4_reg[1][4];mul_40x19_in2[3] = linear_V_row2to4_reg[2][4];
                                mul_40x19_in2[4] = linear_V_row5to8_reg[0][4];mul_40x19_in2[5] = linear_V_row5to8_reg[1][4];mul_40x19_in2[6] = linear_V_row5to8_reg[2][4];mul_40x19_in2[7] = linear_V_row5to8_reg[3][4];
                            end
                            5:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[5]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][5];mul_40x19_in2[2] = linear_V_row2to4_reg[1][5];mul_40x19_in2[3] = linear_V_row2to4_reg[2][5];
                                mul_40x19_in2[4] = linear_V_row5to8_reg[0][5];mul_40x19_in2[5] = linear_V_row5to8_reg[1][5];mul_40x19_in2[6] = linear_V_row5to8_reg[2][5];mul_40x19_in2[7] = linear_V_row5to8_reg[3][5];
                            end
                            6:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[6]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][6];mul_40x19_in2[2] = linear_V_row2to4_reg[1][6];mul_40x19_in2[3] = linear_V_row2to4_reg[2][6];
                                mul_40x19_in2[4] = linear_V_row5to8_reg[0][6];mul_40x19_in2[5] = linear_V_row5to8_reg[1][6];mul_40x19_in2[6] = linear_V_row5to8_reg[2][6];mul_40x19_in2[7] = linear_V_row5to8_reg[3][6];
                            end
                            7:begin
                                mul_40x19_in2[0] = linear_V_row1_reg[7]      ;mul_40x19_in2[1] = linear_V_row2to4_reg[0][7];mul_40x19_in2[2] = linear_V_row2to4_reg[1][7];mul_40x19_in2[3] = linear_V_row2to4_reg[2][7];
                                mul_40x19_in2[4] = linear_V_row5to8_reg[0][7];mul_40x19_in2[5] = linear_V_row5to8_reg[1][7];mul_40x19_in2[6] = linear_V_row5to8_reg[2][7];mul_40x19_in2[7] = linear_V_row5to8_reg[3][7];
                            end 
                        endcase
                    end 
                endcase
                
                // end 
                // 'd2:begin
                    // case (cnt_x)
                    //     0:begin
                    //         mul_40x19_in2[0] = linear_V_row1_reg[0];mul_40x19_in2[1] = linear_V_row1_reg[1];mul_40x19_in2[2] = linear_V_row1_reg[2];mul_40x19_in2[3] = linear_V_row1_reg[3];
                    //         mul_40x19_in2[4] = linear_V_row1_reg[4];mul_40x19_in2[5] = linear_V_row1_reg[5];mul_40x19_in2[6] = linear_V_row1_reg[6];mul_40x19_in2[7] = linear_V_row1_reg[7];
                    //     end  
                    //     1:begin
                    //         mul_40x19_in2[0] = linear_V_row2to4_reg[0][0];mul_40x19_in2[1] = linear_V_row2to4_reg[0][1];mul_40x19_in2[2] = linear_V_row2to4_reg[0][2];mul_40x19_in2[3] = linear_V_row2to4_reg[0][3];
                    //         mul_40x19_in2[4] = linear_V_row2to4_reg[0][4];mul_40x19_in2[5] = linear_V_row2to4_reg[0][5];mul_40x19_in2[6] = linear_V_row2to4_reg[0][6];mul_40x19_in2[7] = linear_V_row2to4_reg[0][7];
                    //     end
                    //     2:begin
                    //         mul_40x19_in2[0] = linear_V_row2to4_reg[1][0];mul_40x19_in2[1] = linear_V_row2to4_reg[1][1];mul_40x19_in2[2] = linear_V_row2to4_reg[1][2];mul_40x19_in2[3] = linear_V_row2to4_reg[1][3];
                    //         mul_40x19_in2[4] = linear_V_row2to4_reg[1][4];mul_40x19_in2[5] = linear_V_row2to4_reg[1][5];mul_40x19_in2[6] = linear_V_row2to4_reg[1][6];mul_40x19_in2[7] = linear_V_row2to4_reg[1][7];
                    //     end
                    //     3:begin
                    //         mul_40x19_in2[0] = linear_V_row2to4_reg[2][0];mul_40x19_in2[1] = linear_V_row2to4_reg[2][1];mul_40x19_in2[2] = linear_V_row2to4_reg[2][2];mul_40x19_in2[3] = linear_V_row2to4_reg[2][3];
                    //         mul_40x19_in2[4] = linear_V_row2to4_reg[2][4];mul_40x19_in2[5] = linear_V_row2to4_reg[2][5];mul_40x19_in2[6] = linear_V_row2to4_reg[2][6];mul_40x19_in2[7] = linear_V_row2to4_reg[2][7];
                    //     end
                    //     4:begin
                    //         mul_40x19_in2[0] = linear_V_row5to8_reg[0][0];mul_40x19_in2[1] = linear_V_row5to8_reg[0][1];mul_40x19_in2[2] = linear_V_row5to8_reg[0][2];mul_40x19_in2[3] = linear_V_row5to8_reg[0][3];
                    //         mul_40x19_in2[4] = linear_V_row5to8_reg[0][4];mul_40x19_in2[5] = linear_V_row5to8_reg[0][5];mul_40x19_in2[6] = linear_V_row5to8_reg[0][6];mul_40x19_in2[7] = linear_V_row5to8_reg[0][7];
                    //     end
                    //     5:begin
                    //         mul_40x19_in2[0] = linear_V_row5to8_reg[1][0];mul_40x19_in2[1] = linear_V_row5to8_reg[1][1];mul_40x19_in2[2] = linear_V_row5to8_reg[1][2];mul_40x19_in2[3] = linear_V_row5to8_reg[1][3];
                    //         mul_40x19_in2[4] = linear_V_row5to8_reg[1][4];mul_40x19_in2[5] = linear_V_row5to8_reg[1][5];mul_40x19_in2[6] = linear_V_row5to8_reg[1][6];mul_40x19_in2[7] = linear_V_row5to8_reg[1][7];
                    //     end
                    //     6:begin
                    //         mul_40x19_in2[0] = linear_V_row5to8_reg[2][0];mul_40x19_in2[1] = linear_V_row5to8_reg[2][1];mul_40x19_in2[2] = linear_V_row5to8_reg[2][2];mul_40x19_in2[3] = linear_V_row5to8_reg[2][3];
                    //         mul_40x19_in2[4] = linear_V_row5to8_reg[2][4];mul_40x19_in2[5] = linear_V_row5to8_reg[2][5];mul_40x19_in2[6] = linear_V_row5to8_reg[2][6];mul_40x19_in2[7] = linear_V_row5to8_reg[2][7];
                    //     end
                    //     7:begin
                    //         mul_40x19_in2[0] = linear_V_row5to8_reg[3][0];mul_40x19_in2[1] = linear_V_row5to8_reg[3][1];mul_40x19_in2[2] = linear_V_row5to8_reg[3][2];mul_40x19_in2[3] = linear_V_row5to8_reg[3][3];
                    //         mul_40x19_in2[4] = linear_V_row5to8_reg[3][4];mul_40x19_in2[5] = linear_V_row5to8_reg[3][5];mul_40x19_in2[6] = linear_V_row5to8_reg[3][6];mul_40x19_in2[7] = linear_V_row5to8_reg[3][7];
                    //     end
                    // endcase
            end
        endcase
    end
//==============================================//
// assign add_mat_out = mul_40x19_out[0] + mul_40x19_out[1] + mul_40x19_out[2] + mul_40x19_out[3] + mul_40x19_out[4] + mul_40x19_out[5] + mul_40x19_out[6] + mul_40x19_out[7];
assign scale_out = add_mat_out / 3;
assign relu_out = scale_out[39] ? 0 : scale_out;
//================================================//
// Linear QKV buffer
//================================================//
//Linear Q buffer
    //row1
    always @(posedge g_linear_q_clk[0] ) begin
        if(cs == IDLE)begin
            for (i = 0; i < 8; i = i + 1) begin
                linear_Q_row1_reg[i] <= 0;
            end
        end
        else if(ns == READ_WEIGHT_K || cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd0,3'd0}: linear_Q_row1_reg[0] <= add_linear_out;
                {3'd0,3'd1}: linear_Q_row1_reg[1] <= add_linear_out;
                {3'd0,3'd2}: linear_Q_row1_reg[2] <= add_linear_out;
                {3'd0,3'd3}: linear_Q_row1_reg[3] <= add_linear_out;
                {3'd0,3'd4}: linear_Q_row1_reg[4] <= add_linear_out;
                {3'd0,3'd5}: linear_Q_row1_reg[5] <= add_linear_out;
                {3'd0,3'd6}: linear_Q_row1_reg[6] <= add_linear_out;
                {3'd0,3'd7}: linear_Q_row1_reg[7] <= add_linear_out;
            endcase
        end
    end
    //row2
    always @(posedge g_linear_q_clk[1] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_Q_row2to4_reg[0][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_K || cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd1,3'd0}: linear_Q_row2to4_reg[0][0] <= add_linear_out;
                {3'd1,3'd1}: linear_Q_row2to4_reg[0][1] <= add_linear_out;
                {3'd1,3'd2}: linear_Q_row2to4_reg[0][2] <= add_linear_out;
                {3'd1,3'd3}: linear_Q_row2to4_reg[0][3] <= add_linear_out;
                {3'd1,3'd4}: linear_Q_row2to4_reg[0][4] <= add_linear_out;
                {3'd1,3'd5}: linear_Q_row2to4_reg[0][5] <= add_linear_out;
                {3'd1,3'd6}: linear_Q_row2to4_reg[0][6] <= add_linear_out;
                {3'd1,3'd7}: linear_Q_row2to4_reg[0][7] <= add_linear_out;
            endcase
        end
    end
    //row3
    always @(posedge g_linear_q_clk[2] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_Q_row2to4_reg[1][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_K || cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd2,3'd0}: linear_Q_row2to4_reg[1][0] <= add_linear_out;
                {3'd2,3'd1}: linear_Q_row2to4_reg[1][1] <= add_linear_out;
                {3'd2,3'd2}: linear_Q_row2to4_reg[1][2] <= add_linear_out;
                {3'd2,3'd3}: linear_Q_row2to4_reg[1][3] <= add_linear_out;
                {3'd2,3'd4}: linear_Q_row2to4_reg[1][4] <= add_linear_out;
                {3'd2,3'd5}: linear_Q_row2to4_reg[1][5] <= add_linear_out;
                {3'd2,3'd6}: linear_Q_row2to4_reg[1][6] <= add_linear_out;
                {3'd2,3'd7}: linear_Q_row2to4_reg[1][7] <= add_linear_out;
            endcase
        end
    end
    //row4
    always @(posedge g_linear_q_clk[3] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_Q_row2to4_reg[2][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_K || cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd3,3'd0}: linear_Q_row2to4_reg[2][0] <= add_linear_out;
                {3'd3,3'd1}: linear_Q_row2to4_reg[2][1] <= add_linear_out;
                {3'd3,3'd2}: linear_Q_row2to4_reg[2][2] <= add_linear_out;
                {3'd3,3'd3}: linear_Q_row2to4_reg[2][3] <= add_linear_out;
                {3'd3,3'd4}: linear_Q_row2to4_reg[2][4] <= add_linear_out;
                {3'd3,3'd5}: linear_Q_row2to4_reg[2][5] <= add_linear_out;
                {3'd3,3'd6}: linear_Q_row2to4_reg[2][6] <= add_linear_out;
                {3'd3,3'd7}: linear_Q_row2to4_reg[2][7] <= add_linear_out;
            endcase
        end
    end
    //row5
    always @(posedge g_linear_q_clk[4] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_Q_row5to8_reg[0][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_K || cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd4,3'd0}: linear_Q_row5to8_reg[0][0] <= add_linear_out;
                {3'd4,3'd1}: linear_Q_row5to8_reg[0][1] <= add_linear_out;
                {3'd4,3'd2}: linear_Q_row5to8_reg[0][2] <= add_linear_out;
                {3'd4,3'd3}: linear_Q_row5to8_reg[0][3] <= add_linear_out;
                {3'd4,3'd4}: linear_Q_row5to8_reg[0][4] <= add_linear_out;
                {3'd4,3'd5}: linear_Q_row5to8_reg[0][5] <= add_linear_out;
                {3'd4,3'd6}: linear_Q_row5to8_reg[0][6] <= add_linear_out;
                {3'd4,3'd7}: linear_Q_row5to8_reg[0][7] <= add_linear_out;
            endcase
        end
    end
    //row6
    always @(posedge g_linear_q_clk[5] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_Q_row5to8_reg[1][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_K || cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd5,3'd0}: linear_Q_row5to8_reg[1][0] <= add_linear_out;
                {3'd5,3'd1}: linear_Q_row5to8_reg[1][1] <= add_linear_out;
                {3'd5,3'd2}: linear_Q_row5to8_reg[1][2] <= add_linear_out;
                {3'd5,3'd3}: linear_Q_row5to8_reg[1][3] <= add_linear_out;
                {3'd5,3'd4}: linear_Q_row5to8_reg[1][4] <= add_linear_out;
                {3'd5,3'd5}: linear_Q_row5to8_reg[1][5] <= add_linear_out;
                {3'd5,3'd6}: linear_Q_row5to8_reg[1][6] <= add_linear_out;
                {3'd5,3'd7}: linear_Q_row5to8_reg[1][7] <= add_linear_out;
            endcase
        end
    end
    //row7
    always @(posedge g_linear_q_clk[6] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_Q_row5to8_reg[2][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_K || cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd6,3'd0}: linear_Q_row5to8_reg[2][0] <= add_linear_out;
                {3'd6,3'd1}: linear_Q_row5to8_reg[2][1] <= add_linear_out;
                {3'd6,3'd2}: linear_Q_row5to8_reg[2][2] <= add_linear_out;
                {3'd6,3'd3}: linear_Q_row5to8_reg[2][3] <= add_linear_out;
                {3'd6,3'd4}: linear_Q_row5to8_reg[2][4] <= add_linear_out;
                {3'd6,3'd5}: linear_Q_row5to8_reg[2][5] <= add_linear_out;
                {3'd6,3'd6}: linear_Q_row5to8_reg[2][6] <= add_linear_out;
                {3'd6,3'd7}: linear_Q_row5to8_reg[2][7] <= add_linear_out;
            endcase
        end
    end
    //row8
    always @(posedge g_linear_q_clk[7] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_Q_row5to8_reg[3][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_K || cs == READ_WEIGHT_K)begin
            case ({cnt_y, cnt_x})
                {3'd7,3'd0}: linear_Q_row5to8_reg[3][0] <= add_linear_out;
                {3'd7,3'd1}: linear_Q_row5to8_reg[3][1] <= add_linear_out;
                {3'd7,3'd2}: linear_Q_row5to8_reg[3][2] <= add_linear_out;
                {3'd7,3'd3}: linear_Q_row5to8_reg[3][3] <= add_linear_out;
                {3'd7,3'd4}: linear_Q_row5to8_reg[3][4] <= add_linear_out;
                {3'd7,3'd5}: linear_Q_row5to8_reg[3][5] <= add_linear_out;
                {3'd7,3'd6}: linear_Q_row5to8_reg[3][6] <= add_linear_out;
                {3'd7,3'd7}: linear_Q_row5to8_reg[3][7] <= add_linear_out;
            endcase
        end
    end
//Linear K buffer
    //row1
    always @(posedge g_linear_k_clk[0] ) begin
        if(cs == IDLE)begin
            for (i = 0; i < 8; i = i + 1) begin
                linear_K_row1_reg[i] <= 0;
            end
        end
        else if(ns == READ_WEIGHT_V || cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd0,3'd0}: linear_K_row1_reg[0] <= add_linear_out;
                {3'd0,3'd1}: linear_K_row1_reg[1] <= add_linear_out;
                {3'd0,3'd2}: linear_K_row1_reg[2] <= add_linear_out;
                {3'd0,3'd3}: linear_K_row1_reg[3] <= add_linear_out;
                {3'd0,3'd4}: linear_K_row1_reg[4] <= add_linear_out;
                {3'd0,3'd5}: linear_K_row1_reg[5] <= add_linear_out;
                {3'd0,3'd6}: linear_K_row1_reg[6] <= add_linear_out;
                {3'd0,3'd7}: linear_K_row1_reg[7] <= add_linear_out;
            endcase
        end
    end
    //row2
    always @(posedge g_linear_k_clk[1] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_K_row2to4_reg[0][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_V || cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd1,3'd0}: linear_K_row2to4_reg[0][0] <= add_linear_out;
                {3'd1,3'd1}: linear_K_row2to4_reg[0][1] <= add_linear_out;
                {3'd1,3'd2}: linear_K_row2to4_reg[0][2] <= add_linear_out;
                {3'd1,3'd3}: linear_K_row2to4_reg[0][3] <= add_linear_out;
                {3'd1,3'd4}: linear_K_row2to4_reg[0][4] <= add_linear_out;
                {3'd1,3'd5}: linear_K_row2to4_reg[0][5] <= add_linear_out;
                {3'd1,3'd6}: linear_K_row2to4_reg[0][6] <= add_linear_out;
                {3'd1,3'd7}: linear_K_row2to4_reg[0][7] <= add_linear_out;
            endcase
        end
    end
    //row3
    always @(posedge g_linear_k_clk[2] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_K_row2to4_reg[1][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_V || cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd2,3'd0}: linear_K_row2to4_reg[1][0] <= add_linear_out;
                {3'd2,3'd1}: linear_K_row2to4_reg[1][1] <= add_linear_out;
                {3'd2,3'd2}: linear_K_row2to4_reg[1][2] <= add_linear_out;
                {3'd2,3'd3}: linear_K_row2to4_reg[1][3] <= add_linear_out;
                {3'd2,3'd4}: linear_K_row2to4_reg[1][4] <= add_linear_out;
                {3'd2,3'd5}: linear_K_row2to4_reg[1][5] <= add_linear_out;
                {3'd2,3'd6}: linear_K_row2to4_reg[1][6] <= add_linear_out;
                {3'd2,3'd7}: linear_K_row2to4_reg[1][7] <= add_linear_out;
            endcase
        end
    end
    //row4
    always @(posedge g_linear_k_clk[3] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_K_row2to4_reg[2][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_V || cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd3,3'd0}: linear_K_row2to4_reg[2][0] <= add_linear_out;
                {3'd3,3'd1}: linear_K_row2to4_reg[2][1] <= add_linear_out;
                {3'd3,3'd2}: linear_K_row2to4_reg[2][2] <= add_linear_out;
                {3'd3,3'd3}: linear_K_row2to4_reg[2][3] <= add_linear_out;
                {3'd3,3'd4}: linear_K_row2to4_reg[2][4] <= add_linear_out;
                {3'd3,3'd5}: linear_K_row2to4_reg[2][5] <= add_linear_out;
                {3'd3,3'd6}: linear_K_row2to4_reg[2][6] <= add_linear_out;
                {3'd3,3'd7}: linear_K_row2to4_reg[2][7] <= add_linear_out;
            endcase
        end
    end
    //row5
    always @(posedge g_linear_k_clk[4] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_K_row5to8_reg[0][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_V || cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd4,3'd0}: linear_K_row5to8_reg[0][0] <= add_linear_out;
                {3'd4,3'd1}: linear_K_row5to8_reg[0][1] <= add_linear_out;
                {3'd4,3'd2}: linear_K_row5to8_reg[0][2] <= add_linear_out;
                {3'd4,3'd3}: linear_K_row5to8_reg[0][3] <= add_linear_out;
                {3'd4,3'd4}: linear_K_row5to8_reg[0][4] <= add_linear_out;
                {3'd4,3'd5}: linear_K_row5to8_reg[0][5] <= add_linear_out;
                {3'd4,3'd6}: linear_K_row5to8_reg[0][6] <= add_linear_out;
                {3'd4,3'd7}: linear_K_row5to8_reg[0][7] <= add_linear_out;
            endcase
        end
    end
    //row6
    always @(posedge g_linear_k_clk[5] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_K_row5to8_reg[1][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_V || cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd5,3'd0}: linear_K_row5to8_reg[1][0] <= add_linear_out;
                {3'd5,3'd1}: linear_K_row5to8_reg[1][1] <= add_linear_out;
                {3'd5,3'd2}: linear_K_row5to8_reg[1][2] <= add_linear_out;
                {3'd5,3'd3}: linear_K_row5to8_reg[1][3] <= add_linear_out;
                {3'd5,3'd4}: linear_K_row5to8_reg[1][4] <= add_linear_out;
                {3'd5,3'd5}: linear_K_row5to8_reg[1][5] <= add_linear_out;
                {3'd5,3'd6}: linear_K_row5to8_reg[1][6] <= add_linear_out;
                {3'd5,3'd7}: linear_K_row5to8_reg[1][7] <= add_linear_out;
            endcase
        end
    end
    //row7
    always @(posedge g_linear_k_clk[6] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_K_row5to8_reg[2][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_V || cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd6,3'd0}: linear_K_row5to8_reg[2][0] <= add_linear_out;
                {3'd6,3'd1}: linear_K_row5to8_reg[2][1] <= add_linear_out;
                {3'd6,3'd2}: linear_K_row5to8_reg[2][2] <= add_linear_out;
                {3'd6,3'd3}: linear_K_row5to8_reg[2][3] <= add_linear_out;
                {3'd6,3'd4}: linear_K_row5to8_reg[2][4] <= add_linear_out;
                {3'd6,3'd5}: linear_K_row5to8_reg[2][5] <= add_linear_out;
                {3'd6,3'd6}: linear_K_row5to8_reg[2][6] <= add_linear_out;
                {3'd6,3'd7}: linear_K_row5to8_reg[2][7] <= add_linear_out;
            endcase
        end
    end
    //row8
    always @(posedge g_linear_k_clk[7] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_K_row5to8_reg[3][j] <= 0;
                end
            // end
        end
        else if(ns == READ_WEIGHT_V || cs == READ_WEIGHT_V)begin
            case ({cnt_y, cnt_x})
                {3'd7,3'd0}: linear_K_row5to8_reg[3][0] <= add_linear_out;
                {3'd7,3'd1}: linear_K_row5to8_reg[3][1] <= add_linear_out;
                {3'd7,3'd2}: linear_K_row5to8_reg[3][2] <= add_linear_out;
                {3'd7,3'd3}: linear_K_row5to8_reg[3][3] <= add_linear_out;
                {3'd7,3'd4}: linear_K_row5to8_reg[3][4] <= add_linear_out;
                {3'd7,3'd5}: linear_K_row5to8_reg[3][5] <= add_linear_out;
                {3'd7,3'd6}: linear_K_row5to8_reg[3][6] <= add_linear_out;
                {3'd7,3'd7}: linear_K_row5to8_reg[3][7] <= add_linear_out;
            endcase
        end
    end
//Linear V buffer
    //row1
    always @(posedge g_linear_v_clk[0] ) begin
        if(cs == IDLE)begin
            for (i = 0; i < 8; i = i + 1) begin
                linear_V_row1_reg[i] <= 0;
            end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR)begin
            case ({cnt_y, cnt_x})
                {3'd0,3'd0}: linear_V_row1_reg[0] <= add_linear_out;
                {3'd0,3'd1}: linear_V_row1_reg[1] <= add_linear_out;
                {3'd0,3'd2}: linear_V_row1_reg[2] <= add_linear_out;
                {3'd0,3'd3}: linear_V_row1_reg[3] <= add_linear_out;
                {3'd0,3'd4}: linear_V_row1_reg[4] <= add_linear_out;
                {3'd0,3'd5}: linear_V_row1_reg[5] <= add_linear_out;
                {3'd0,3'd6}: linear_V_row1_reg[6] <= add_linear_out;
                {3'd0,3'd7}: linear_V_row1_reg[7] <= add_linear_out;
            endcase
        end
    end
    //row2
    always @(posedge g_linear_v_clk[1] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_V_row2to4_reg[0][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case ({cnt_y, cnt_x})
                {3'd1,3'd0}: linear_V_row2to4_reg[0][0] <= add_linear_out;
                {3'd1,3'd1}: linear_V_row2to4_reg[0][1] <= add_linear_out;
                {3'd1,3'd2}: linear_V_row2to4_reg[0][2] <= add_linear_out;
                {3'd1,3'd3}: linear_V_row2to4_reg[0][3] <= add_linear_out;
                {3'd1,3'd4}: linear_V_row2to4_reg[0][4] <= add_linear_out;
                {3'd1,3'd5}: linear_V_row2to4_reg[0][5] <= add_linear_out;
                {3'd1,3'd6}: linear_V_row2to4_reg[0][6] <= add_linear_out;
                {3'd1,3'd7}: linear_V_row2to4_reg[0][7] <= add_linear_out;
            endcase
        end
    end
    //row3
    always @(posedge g_linear_v_clk[2] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_V_row2to4_reg[1][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case ({cnt_y, cnt_x})
                {3'd2,3'd0}: linear_V_row2to4_reg[1][0] <= add_linear_out;
                {3'd2,3'd1}: linear_V_row2to4_reg[1][1] <= add_linear_out;
                {3'd2,3'd2}: linear_V_row2to4_reg[1][2] <= add_linear_out;
                {3'd2,3'd3}: linear_V_row2to4_reg[1][3] <= add_linear_out;
                {3'd2,3'd4}: linear_V_row2to4_reg[1][4] <= add_linear_out;
                {3'd2,3'd5}: linear_V_row2to4_reg[1][5] <= add_linear_out;
                {3'd2,3'd6}: linear_V_row2to4_reg[1][6] <= add_linear_out;
                {3'd2,3'd7}: linear_V_row2to4_reg[1][7] <= add_linear_out;
            endcase
        end
    end
    //row4
    always @(posedge g_linear_v_clk[3] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_V_row2to4_reg[2][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case ({cnt_y, cnt_x})
                {3'd3,3'd0}: linear_V_row2to4_reg[2][0] <= add_linear_out;
                {3'd3,3'd1}: linear_V_row2to4_reg[2][1] <= add_linear_out;
                {3'd3,3'd2}: linear_V_row2to4_reg[2][2] <= add_linear_out;
                {3'd3,3'd3}: linear_V_row2to4_reg[2][3] <= add_linear_out;
                {3'd3,3'd4}: linear_V_row2to4_reg[2][4] <= add_linear_out;
                {3'd3,3'd5}: linear_V_row2to4_reg[2][5] <= add_linear_out;
                {3'd3,3'd6}: linear_V_row2to4_reg[2][6] <= add_linear_out;
                {3'd3,3'd7}: linear_V_row2to4_reg[2][7] <= add_linear_out;
            endcase
        end
    end
    //row5
    always @(posedge g_linear_v_clk[4] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_V_row5to8_reg[0][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case ({cnt_y, cnt_x})
                {3'd4,3'd0}: linear_V_row5to8_reg[0][0] <= add_linear_out;
                {3'd4,3'd1}: linear_V_row5to8_reg[0][1] <= add_linear_out;
                {3'd4,3'd2}: linear_V_row5to8_reg[0][2] <= add_linear_out;
                {3'd4,3'd3}: linear_V_row5to8_reg[0][3] <= add_linear_out;
                {3'd4,3'd4}: linear_V_row5to8_reg[0][4] <= add_linear_out;
                {3'd4,3'd5}: linear_V_row5to8_reg[0][5] <= add_linear_out;
                {3'd4,3'd6}: linear_V_row5to8_reg[0][6] <= add_linear_out;
                {3'd4,3'd7}: linear_V_row5to8_reg[0][7] <= add_linear_out;
            endcase
        end
    end
    //row6
    always @(posedge g_linear_v_clk[5] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_V_row5to8_reg[1][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case ({cnt_y, cnt_x})
                {3'd5,3'd0}: linear_V_row5to8_reg[1][0] <= add_linear_out;
                {3'd5,3'd1}: linear_V_row5to8_reg[1][1] <= add_linear_out;
                {3'd5,3'd2}: linear_V_row5to8_reg[1][2] <= add_linear_out;
                {3'd5,3'd3}: linear_V_row5to8_reg[1][3] <= add_linear_out;
                {3'd5,3'd4}: linear_V_row5to8_reg[1][4] <= add_linear_out;
                {3'd5,3'd5}: linear_V_row5to8_reg[1][5] <= add_linear_out;
                {3'd5,3'd6}: linear_V_row5to8_reg[1][6] <= add_linear_out;
                {3'd5,3'd7}: linear_V_row5to8_reg[1][7] <= add_linear_out;
            endcase
        end
    end
    //row7
    always @(posedge g_linear_v_clk[6] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_V_row5to8_reg[2][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case ({cnt_y, cnt_x})
                {3'd6,3'd0}: linear_V_row5to8_reg[2][0] <= add_linear_out;
                {3'd6,3'd1}: linear_V_row5to8_reg[2][1] <= add_linear_out;
                {3'd6,3'd2}: linear_V_row5to8_reg[2][2] <= add_linear_out;
                {3'd6,3'd3}: linear_V_row5to8_reg[2][3] <= add_linear_out;
                {3'd6,3'd4}: linear_V_row5to8_reg[2][4] <= add_linear_out;
                {3'd6,3'd5}: linear_V_row5to8_reg[2][5] <= add_linear_out;
                {3'd6,3'd6}: linear_V_row5to8_reg[2][6] <= add_linear_out;
                {3'd6,3'd7}: linear_V_row5to8_reg[2][7] <= add_linear_out;
            endcase
        end
    end
    //row8
    always @(posedge g_linear_v_clk[7] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    linear_V_row5to8_reg[3][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case ({cnt_y, cnt_x})
                {3'd7,3'd0}: linear_V_row5to8_reg[3][0] <= add_linear_out;
                {3'd7,3'd1}: linear_V_row5to8_reg[3][1] <= add_linear_out;
                {3'd7,3'd2}: linear_V_row5to8_reg[3][2] <= add_linear_out;
                {3'd7,3'd3}: linear_V_row5to8_reg[3][3] <= add_linear_out;
                {3'd7,3'd4}: linear_V_row5to8_reg[3][4] <= add_linear_out;
                {3'd7,3'd5}: linear_V_row5to8_reg[3][5] <= add_linear_out;
                {3'd7,3'd6}: linear_V_row5to8_reg[3][6] <= add_linear_out;
                {3'd7,3'd7}: linear_V_row5to8_reg[3][7] <= add_linear_out;
            endcase
        end
    end
//================================================//
// S_reg
//================================================//
    always @(posedge g_S_clk[0] ) begin
        if(cs == IDLE)begin
            for (i = 0; i < 8; i = i + 1) begin
                S_row1_reg[i] <= 0;
            end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR)begin
            case (T_buffer)
                'd0:begin
                    case ({cnt_y, cnt_x})
                        {3'd0,3'd0}: S_row1_reg[0] <= relu_out;  
                    endcase
                end
                'd1:begin
                    case ({cnt_y, cnt_x})
                        {3'd0,3'd0}: S_row1_reg[0] <= relu_out; 
                        {3'd0,3'd1}: S_row1_reg[1] <= relu_out;
                        {3'd0,3'd2}: S_row1_reg[2] <= relu_out;
                        {3'd0,3'd3}: S_row1_reg[3] <= relu_out; 
                    endcase
                end 
                'd2:begin
                    case ({cnt_y, cnt_x})
                        {3'd0,3'd0}: S_row1_reg[0] <= relu_out;
                        {3'd0,3'd1}: S_row1_reg[1] <= relu_out;
                        {3'd0,3'd2}: S_row1_reg[2] <= relu_out;
                        {3'd0,3'd3}: S_row1_reg[3] <= relu_out;
                        {3'd0,3'd4}: S_row1_reg[4] <= relu_out;
                        {3'd0,3'd5}: S_row1_reg[5] <= relu_out;
                        {3'd0,3'd6}: S_row1_reg[6] <= relu_out;
                        {3'd0,3'd7}: S_row1_reg[7] <= relu_out;   
                    endcase
                end 
            endcase
        end
    end
    //row2
    always @(posedge g_S_clk[1] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    S_row2to4_reg[0][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case (T_buffer)
                'd1:begin
                    case ({cnt_y, cnt_x})
                        {3'd0,3'd4}: S_row2to4_reg[0][0] <= relu_out;
                        {3'd0,3'd5}: S_row2to4_reg[0][1] <= relu_out;
                        {3'd0,3'd6}: S_row2to4_reg[0][2] <= relu_out;
                        {3'd0,3'd7}: S_row2to4_reg[0][3] <= relu_out;
                    endcase
                end 
                'd2:begin
                    case ({cnt_y, cnt_x})
                        {3'd1,3'd0}: S_row2to4_reg[0][0] <= relu_out;
                        {3'd1,3'd1}: S_row2to4_reg[0][1] <= relu_out;
                        {3'd1,3'd2}: S_row2to4_reg[0][2] <= relu_out;
                        {3'd1,3'd3}: S_row2to4_reg[0][3] <= relu_out;
                        {3'd1,3'd4}: S_row2to4_reg[0][4] <= relu_out;
                        {3'd1,3'd5}: S_row2to4_reg[0][5] <= relu_out;
                        {3'd1,3'd6}: S_row2to4_reg[0][6] <= relu_out;
                        {3'd1,3'd7}: S_row2to4_reg[0][7] <= relu_out;
                    endcase
                end 
            endcase
        end
    end
    //row3
    always @(posedge g_S_clk[2] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    S_row2to4_reg[1][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case (T_buffer)
                'd1:begin
                    case ({cnt_y, cnt_x})
                        {3'd1,3'd0}: S_row2to4_reg[1][0] <= relu_out; 
                        {3'd1,3'd1}: S_row2to4_reg[1][1] <= relu_out;
                        {3'd1,3'd2}: S_row2to4_reg[1][2] <= relu_out;
                        {3'd1,3'd3}: S_row2to4_reg[1][3] <= relu_out; 
                    endcase
                end 
                'd2:begin
                    case ({cnt_y, cnt_x})
                        {3'd2,3'd0}: S_row2to4_reg[1][0] <= relu_out;
                        {3'd2,3'd1}: S_row2to4_reg[1][1] <= relu_out;
                        {3'd2,3'd2}: S_row2to4_reg[1][2] <= relu_out;
                        {3'd2,3'd3}: S_row2to4_reg[1][3] <= relu_out;
                        {3'd2,3'd4}: S_row2to4_reg[1][4] <= relu_out;
                        {3'd2,3'd5}: S_row2to4_reg[1][5] <= relu_out;
                        {3'd2,3'd6}: S_row2to4_reg[1][6] <= relu_out;
                        {3'd2,3'd7}: S_row2to4_reg[1][7] <= relu_out;
                    endcase
                end 
            endcase
        end
    end
    //row4
    always @(posedge g_S_clk[3] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    S_row2to4_reg[2][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case (T_buffer)
                'd1:begin
                    case ({cnt_y, cnt_x})
                        {3'd1,3'd4}: S_row2to4_reg[2][0] <= relu_out;
                        {3'd1,3'd5}: S_row2to4_reg[2][1] <= relu_out;
                        {3'd1,3'd6}: S_row2to4_reg[2][2] <= relu_out;
                        {3'd1,3'd7}: S_row2to4_reg[2][3] <= relu_out; 
                    endcase
                end 
                'd2:begin
                    case ({cnt_y, cnt_x})
                        {3'd3,3'd0}: S_row2to4_reg[2][0] <= relu_out;
                        {3'd3,3'd1}: S_row2to4_reg[2][1] <= relu_out;
                        {3'd3,3'd2}: S_row2to4_reg[2][2] <= relu_out;
                        {3'd3,3'd3}: S_row2to4_reg[2][3] <= relu_out;
                        {3'd3,3'd4}: S_row2to4_reg[2][4] <= relu_out;
                        {3'd3,3'd5}: S_row2to4_reg[2][5] <= relu_out;
                        {3'd3,3'd6}: S_row2to4_reg[2][6] <= relu_out;
                        {3'd3,3'd7}: S_row2to4_reg[2][7] <= relu_out;
                    endcase
                end 
            endcase
        end
    end
    //row5
    always @(posedge g_S_clk[4] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    S_row5to8_reg[0][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case (T_buffer)
                'd2:begin
                    case ({cnt_y, cnt_x})
                        {3'd4,3'd0}: S_row5to8_reg[0][0] <= relu_out;
                        {3'd4,3'd1}: S_row5to8_reg[0][1] <= relu_out;
                        {3'd4,3'd2}: S_row5to8_reg[0][2] <= relu_out;
                        {3'd4,3'd3}: S_row5to8_reg[0][3] <= relu_out;
                        {3'd4,3'd4}: S_row5to8_reg[0][4] <= relu_out;
                        {3'd4,3'd5}: S_row5to8_reg[0][5] <= relu_out;
                        {3'd4,3'd6}: S_row5to8_reg[0][6] <= relu_out;
                        {3'd4,3'd7}: S_row5to8_reg[0][7] <= relu_out;
                    endcase 
                end  
            endcase
        end
    end
    //row6
    always @(posedge g_S_clk[5] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    S_row5to8_reg[1][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case (T_buffer)
                'd2:begin
                    case ({cnt_y, cnt_x})
                        {3'd5,3'd0}: S_row5to8_reg[1][0] <= relu_out;
                        {3'd5,3'd1}: S_row5to8_reg[1][1] <= relu_out;
                        {3'd5,3'd2}: S_row5to8_reg[1][2] <= relu_out;
                        {3'd5,3'd3}: S_row5to8_reg[1][3] <= relu_out;
                        {3'd5,3'd4}: S_row5to8_reg[1][4] <= relu_out;
                        {3'd5,3'd5}: S_row5to8_reg[1][5] <= relu_out;
                        {3'd5,3'd6}: S_row5to8_reg[1][6] <= relu_out;
                        {3'd5,3'd7}: S_row5to8_reg[1][7] <= relu_out;
                    endcase 
                end  
            endcase
        end
    end
    //row7
    always @(posedge g_S_clk[6] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    S_row5to8_reg[2][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case (T_buffer)
                'd2:begin
                    case ({cnt_y, cnt_x})
                        {3'd6,3'd0}: S_row5to8_reg[2][0] <= relu_out;
                        {3'd6,3'd1}: S_row5to8_reg[2][1] <= relu_out;
                        {3'd6,3'd2}: S_row5to8_reg[2][2] <= relu_out;
                        {3'd6,3'd3}: S_row5to8_reg[2][3] <= relu_out;
                        {3'd6,3'd4}: S_row5to8_reg[2][4] <= relu_out;
                        {3'd6,3'd5}: S_row5to8_reg[2][5] <= relu_out;
                        {3'd6,3'd6}: S_row5to8_reg[2][6] <= relu_out;
                        {3'd6,3'd7}: S_row5to8_reg[2][7] <= relu_out;
                    endcase 
                end  
            endcase
        end
    end
    //row8
    always @(posedge g_S_clk[7] ) begin
        if(cs == IDLE)begin
            // for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    S_row5to8_reg[3][j] <= 0;
                end
            // end
        end
        else if(ns == CAL_V_LINEAR || cs == CAL_V_LINEAR || cs == MAT_MUL_2)begin
            case (T_buffer)
                'd2:begin
                    case ({cnt_y, cnt_x})
                        {3'd7,3'd0}: S_row5to8_reg[3][0] <= relu_out;
                        {3'd7,3'd1}: S_row5to8_reg[3][1] <= relu_out;
                        {3'd7,3'd2}: S_row5to8_reg[3][2] <= relu_out;
                        {3'd7,3'd3}: S_row5to8_reg[3][3] <= relu_out;
                        {3'd7,3'd4}: S_row5to8_reg[3][4] <= relu_out;
                        {3'd7,3'd5}: S_row5to8_reg[3][5] <= relu_out;
                        {3'd7,3'd6}: S_row5to8_reg[3][6] <= relu_out;
                        {3'd7,3'd7}: S_row5to8_reg[3][7] <= relu_out;
                    endcase 
                end  
            endcase
        end
    end
//================================================//
// out_buffer
//================================================//
always @(posedge clk ) begin
    if(ns == IDLE)
        out_buffer <= 0;
    else if(cs == MAT_MUL_2 || cs == OUT)
        out_buffer <= add_mat_out;
end
//================================================//
// OUTPUT
//================================================//
always @(*) begin
    if(cs == OUT)
        out_valid = 1;
    else
        out_valid = 0;
end
always @(*) begin
    if(cs == OUT)begin
        out_data = out_buffer;
    end
    else
        out_data = 0;
end
endmodule

