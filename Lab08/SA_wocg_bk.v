/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: SA_wocg.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Spring IC Lab / Exersise Lab08 / SA_wocg
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

module SA(
	// Input signals
	clk,
	rst_n,
	in_valid,
	T,
	in_data,
	w_Q,
	w_K,
	w_V,
	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
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
genvar  i, j;
integer k, l;
//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [2:0] cs, ns;
wire read_weight_done;
reg mat_mul_1_done, start_mat_mul, cal_v_linear_done, mat_mul_2_done, out_done;

reg [5:0] cnt_64;
reg [2:0] cnt_8;
reg [1:0] cnt_4;


reg signed [7:0] img_buffer[0:7][0:7];
reg signed [7:0] weight_buffer_Q[0:7][0:7];
reg signed [7:0] weight_buffer_K[0:7][0:7];
reg signed [7:0] weight_buffer_V[0:7][0:7];
reg [1:0] T_buffer;

reg signed [18:0] linear_Q_reg [0:7][0:7];
reg signed [18:0] linear_K_reg [0:7][0:7];
reg signed [18:0] linear_V_reg [0:7][0:7];

reg  signed [39:0]  mul_1_in1, mul_2_in1, mul_3_in1, mul_4_in1, mul_5_in1, mul_6_in1, mul_7_in1, mul_8_in1;
reg  signed [18:0]  mul_1_in2, mul_2_in2, mul_3_in2, mul_4_in2, mul_5_in2, mul_6_in2, mul_7_in2, mul_8_in2;
wire signed [59:0]  mul_out[0:7];

reg signed [63:0]  add_1_in1, add_2_in1, add_3_in1, add_4_in1, add_5_in1, add_6_in1, add_7_in1, add_8_in1;
reg signed [63:0]  add_1_in2, add_2_in2, add_3_in2, add_4_in2, add_5_in2, add_6_in2, add_7_in2, add_8_in2;
reg signed [63:0]  add_out[0:7];

wire signed [40:0]  mat_mul_out;
wire signed [40:0]  scale_out;
wire signed [40:0]  relu_out;

reg signed [40:0] S_reg [0:63];

reg signed [63:0] out_buffer [0:7][0:7];
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
        READ_WEIGHT_V :ns = start_mat_mul    ? MAT_MUL_1     : READ_WEIGHT_V;
        MAT_MUL_1     :ns = in_valid ? MAT_MUL_1 : (mat_mul_1_done   ? CAL_V_LINEAR  : MAT_MUL_1);
        CAL_V_LINEAR  :ns = cal_v_linear_done? MAT_MUL_2     : CAL_V_LINEAR;
        MAT_MUL_2     :ns = mat_mul_2_done   ? OUT           : MAT_MUL_2;
        OUT           :ns = out_done         ? IDLE          : OUT;
        default       :ns = IDLE;
    endcase
end
assign read_weight_done = (cnt_64 == 63) ? 1 : 0;
always @(*) begin
    case (T_buffer)
        'd0    :start_mat_mul = cnt_64 == 7;  //1
        'd1    :start_mat_mul = cnt_64 == 31; //4
        'd2    :start_mat_mul = cnt_64 == 63; //8
        default:start_mat_mul = 0; 
    endcase
end
always @(posedge clk ) begin
    if(cs == IDLE)
        mat_mul_1_done <= 0;
    else if(cs == MAT_MUL_1)begin
        case (T_buffer)
            'd0    :mat_mul_1_done <= cnt_64 == 8 ? 1 : mat_mul_1_done;  //1
            'd1    :mat_mul_1_done <= cnt_64 -32 == 15? 1 : mat_mul_1_done; //4
            'd2    :mat_mul_1_done <= cnt_64 == 63? 1 : mat_mul_1_done; //8
            // default:mat_mul_1_done = 0; 
        endcase
    end
end
always @(*) begin
    case (T_buffer)
        'd0    :cal_v_linear_done = cnt_64 == 7;  //1
        'd1    :cal_v_linear_done = cnt_64 == 31; //4
        'd2    :cal_v_linear_done = cnt_64 == 63; //8
        default:cal_v_linear_done = 0;
    endcase
end
always @(*) begin
    case (T_buffer)
        'd0    :mat_mul_2_done = cnt_64 == 0;  //1
        'd1    :mat_mul_2_done = cnt_64 == 15; //4
        'd2    :mat_mul_2_done = cnt_64 == 63; //8
        default:mat_mul_2_done = 0;
    endcase
end
always @(*) begin
    case (T_buffer)
        'd0     :out_done = cnt_64 == 7; 
        'd1     :out_done = cnt_64 == 31;
        default :out_done = cnt_64 == 63;
    endcase
end
//==============================================//
// counter
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt_64 <= 0;
    else if(ns == IDLE)
        cnt_64 <= 0;
    else if(cs == MAT_MUL_1 && ns == CAL_V_LINEAR)
        cnt_64 <= 0;
    else if(cs == CAL_V_LINEAR && ns == MAT_MUL_2)
        cnt_64 <= 0;
    else if(cs == MAT_MUL_2 && ns == OUT)
        cnt_64 <= 0;
    else if(cs == IDLE && ns == READ_WEIGHT_Q)
        cnt_64 <= cnt_64 + 1;
    else if(cs == READ_WEIGHT_Q || cs == READ_WEIGHT_K || cs == READ_WEIGHT_V)
        cnt_64 <= cnt_64 + 1;
    else if(cs == MAT_MUL_1)
        cnt_64 <= cnt_64 + 1;
    else if(cs == CAL_V_LINEAR)
        cnt_64 <= cnt_64 + 1;
    else if(cs == MAT_MUL_2)
        cnt_64 <= cnt_64 + 1;
    else if(cs == OUT)
        cnt_64 <= cnt_64 + 1;
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt_8 <= 0;
    else if(ns == IDLE)
        cnt_8 <= 0;
    else if(cs == CAL_V_LINEAR && ns == MAT_MUL_2)
        cnt_8 <= 0;
    else if(cs == READ_WEIGHT_K || cs == READ_WEIGHT_V|| cs == CAL_V_LINEAR)
        cnt_8 <= cnt_8 + 1;
    else if(cs == MAT_MUL_1)begin
        case (T_buffer)
            'd1:begin
                if(cnt_8 == 3)
                    cnt_8 <= 0;
                else
                    cnt_8 <= cnt_8 + 1;
            end 
            default: cnt_8 <= cnt_8 + 1;
        endcase
    end
    else if(cs == MAT_MUL_2)begin
        case (T_buffer)
            'd1:begin
                if(cnt_8 == 3)
                    cnt_8 <= 0;
                else
                    cnt_8 <= cnt_8 + 1;
            end 
            default: cnt_8 <= cnt_8 + 1;
        endcase
    end
end
// always @(posedge clk or negedge rst_n) begin
//     if(~rst_n)
//         cnt_4 <= 0;
//     else if(ns == MAT_MUL_2)
//         cnt_4 <= cnt_4 + 1;
// end
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
//Weight Q buffer
    generate
        for(i = 0; i < 7; i = i + 1) begin
            for(j = 0; j < 7; j = j + 1) begin
                always @(posedge clk) begin
                    if(ns == IDLE)
                        weight_buffer_Q[i][j] <= 0;
                    else if(cs == READ_WEIGHT_Q)
                        weight_buffer_Q[i][j] <= weight_buffer_Q[i][j + 1];
                    else if(cs == READ_WEIGHT_K)
                        weight_buffer_Q[i][j] <= weight_buffer_Q[i + 1][j];
                end
            end
        end
    endgenerate
    generate
        for(i = 0; i < 7; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    weight_buffer_Q[i][7] <= 0;
                else if(cs == READ_WEIGHT_Q)
                    weight_buffer_Q[i][7] <= weight_buffer_Q[i + 1][0];
                else if(cs == READ_WEIGHT_K)
                    weight_buffer_Q[i][7] <= weight_buffer_Q[i + 1][7];
            end
        end
    endgenerate
    generate
        for(j = 0; j < 7; j = j + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    weight_buffer_Q[7][j] <= 0;
                else if(cs == READ_WEIGHT_Q)
                    weight_buffer_Q[7][j] <= weight_buffer_Q[7][j + 1];
                else if(cs == READ_WEIGHT_K)
                    weight_buffer_Q[7][j] <= weight_buffer_Q[0][j];
            end
        end
    endgenerate
    always @(posedge clk) begin
        if(ns == IDLE)
            weight_buffer_Q[7][7] <= 0;
        else if(ns == READ_WEIGHT_Q || cs == READ_WEIGHT_Q)begin
            weight_buffer_Q[7][7] <= w_Q;
        end
        else if(cs == READ_WEIGHT_K)
            weight_buffer_Q[7][7] <= weight_buffer_Q[0][7];
    end
//Weight K buffer
    generate
        for(i = 0; i < 7; i = i + 1) begin
            for(j = 0; j < 7; j = j + 1) begin
                always @(posedge clk) begin
                    if(ns == IDLE)
                        weight_buffer_K[i][j] <= 0;
                    else if(cs == READ_WEIGHT_K)
                        weight_buffer_K[i][j] <= weight_buffer_K[i][j + 1];
                    else if(cs == READ_WEIGHT_V)
                        weight_buffer_K[i][j] <= weight_buffer_K[i + 1][j];
                end
            end
        end
    endgenerate
    generate
        for(i = 0; i < 7; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    weight_buffer_K[i][7] <= 0;
                else if(cs == READ_WEIGHT_K)
                    weight_buffer_K[i][7] <= weight_buffer_K[i + 1][0];
                else if(cs == READ_WEIGHT_V)
                    weight_buffer_K[i][7] <= weight_buffer_K[i + 1][7];
            end
        end
    endgenerate
    generate
        for(j = 0; j < 7; j = j + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    weight_buffer_K[7][j] <= 0;
                else if(cs == READ_WEIGHT_K)
                    weight_buffer_K[7][j] <= weight_buffer_K[7][j + 1];
                else if(cs == READ_WEIGHT_V)
                    weight_buffer_K[7][j] <= weight_buffer_K[0][j];
            end
        end
    endgenerate
    always @(posedge clk) begin
        if(ns == IDLE)
            weight_buffer_K[7][7] <= 0;
        else if(cs == READ_WEIGHT_K)begin
            weight_buffer_K[7][7] <= w_K;
        end
        else if(cs == READ_WEIGHT_V)
            weight_buffer_K[7][7] <= weight_buffer_K[0][7];
    end
//Weight V buffer
    generate
        for(i = 0; i < 7; i = i + 1) begin
            for(j = 0; j < 7; j = j + 1) begin
                always @(posedge clk) begin
                    if(ns == IDLE)
                        weight_buffer_V[i][j] <= 0;
                    else if((T_buffer == 0 || T_buffer == 1) && (cs == READ_WEIGHT_V || ns == MAT_MUL_1))
                        weight_buffer_V[i][j] <= weight_buffer_V[i][j + 1];
                    else if(T_buffer == 2 && cs == READ_WEIGHT_V)
                        weight_buffer_V[i][j] <= weight_buffer_V[i][j + 1];
                    else if(cs == CAL_V_LINEAR)
                        weight_buffer_V[i][j] <= weight_buffer_V[i + 1][j];
                end
            end
        end
    endgenerate
    generate
        for(i = 0; i < 7; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    weight_buffer_V[i][7] <= 0;
                else if((T_buffer == 0 || T_buffer == 1) && (cs == READ_WEIGHT_V || ns == MAT_MUL_1))
                    weight_buffer_V[i][7] <= weight_buffer_V[i + 1][0];
                else if(T_buffer == 2 && cs == READ_WEIGHT_V)
                    weight_buffer_V[i][7] <= weight_buffer_V[i + 1][0];
                else if(cs == CAL_V_LINEAR)
                    weight_buffer_V[i][7] <= weight_buffer_V[i + 1][7];
            end
        end
    endgenerate
    generate
        for(j = 0; j < 7; j = j + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    weight_buffer_V[7][j] <= 0;
                else if((T_buffer == 0 || T_buffer == 1) && (cs == READ_WEIGHT_V || ns == MAT_MUL_1))
                    weight_buffer_V[7][j] <= weight_buffer_V[7][j + 1];
                else if(T_buffer == 2 && cs == READ_WEIGHT_V)
                    weight_buffer_V[7][j] <= weight_buffer_V[7][j + 1];
                else if(cs == CAL_V_LINEAR)
                    weight_buffer_V[7][j] <= weight_buffer_V[0][j];
            end
        end
    endgenerate
    always @(posedge clk) begin
        if(ns == IDLE)
            weight_buffer_V[7][7] <= 0;
        else if((T_buffer == 0 || T_buffer == 1) && (cs == READ_WEIGHT_V || ns == MAT_MUL_1))
            weight_buffer_V[7][7] <= w_V;
        else if(T_buffer == 2 && cs == READ_WEIGHT_V)
            weight_buffer_V[7][7] <= w_V;
        else if(cs == CAL_V_LINEAR)
            weight_buffer_V[7][7] <= weight_buffer_V[0][7];
    end
//Img buffer
    generate
        for(i = 0; i < 8; i = i + 1) begin
            for(j = 0; j < 7; j = j + 1) begin
                always @(posedge clk) begin
                    if(ns == IDLE)
                        img_buffer[i][j] <= 0;
                    else if(in_valid)
                        img_buffer[i][j] <= img_buffer[i][j + 1];
                    else if(cs == CAL_V_LINEAR)
                        img_buffer[i][j] <= img_buffer[i][j + 1];
                end
            end
        end
    endgenerate
    generate
        for(i = 0; i < 7; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    img_buffer[i][7] <= 0;
                else if(in_valid)
                    img_buffer[i][7] <= img_buffer[i + 1][0];
                else if(cs == CAL_V_LINEAR)
                    img_buffer[i][7] <= img_buffer[i + 1][0];
            end
        end
    endgenerate
    always @(posedge clk) begin
        if(ns == IDLE)
            img_buffer[7][7] <= 0; 
        else if(cs == IDLE && ns == READ_WEIGHT_Q)
            img_buffer[7][7] <= in_data;
        else if(cs == READ_WEIGHT_Q)begin
            case (T_buffer)
                'd0:img_buffer[7][7] <= cnt_64 < 8  ? in_data : 0;
                'd1:img_buffer[7][7] <= cnt_64 < 32 ? in_data : 0;
                'd2:img_buffer[7][7] <= in_data; 
            endcase
        end
        else if(cs == MAT_MUL_1)
            img_buffer[7][7] <= img_buffer[7][7];
        else 
            img_buffer[7][7] <= img_buffer[0][0];
    end
//==============================================//
// Multiplier
//==============================================//
assign mul_out[0] = mul_1_in1 * mul_1_in2;
assign mul_out[1] = mul_2_in1 * mul_2_in2;
assign mul_out[2] = mul_3_in1 * mul_3_in2;
assign mul_out[3] = mul_4_in1 * mul_4_in2;
assign mul_out[4] = mul_5_in1 * mul_5_in2;
assign mul_out[5] = mul_6_in1 * mul_6_in2;
assign mul_out[6] = mul_7_in1 * mul_7_in2;
assign mul_out[7] = mul_8_in1 * mul_8_in2;
always @(*) begin
    mul_1_in1 = 0;mul_2_in1 = 0;mul_3_in1 = 0;mul_4_in1 = 0;
    mul_5_in1 = 0;mul_6_in1 = 0;mul_7_in1 = 0;mul_8_in1 = 0;
    case (cs)
        READ_WEIGHT_K  :begin
            mul_1_in1 = img_buffer[0][0];mul_2_in1 = img_buffer[0][0];mul_3_in1 = img_buffer[0][0];mul_4_in1 = img_buffer[0][0];
            mul_5_in1 = img_buffer[0][0];mul_6_in1 = img_buffer[0][0];mul_7_in1 = img_buffer[0][0];mul_8_in1 = img_buffer[0][0];
        end 
        READ_WEIGHT_V  :begin
            mul_1_in1 = img_buffer[0][0];mul_2_in1 = img_buffer[0][0];mul_3_in1 = img_buffer[0][0];mul_4_in1 = img_buffer[0][0];
            mul_5_in1 = img_buffer[0][0];mul_6_in1 = img_buffer[0][0];mul_7_in1 = img_buffer[0][0];mul_8_in1 = img_buffer[0][0];
        end
        MAT_MUL_1      :begin
            mul_1_in1 = linear_Q_reg[0][0];mul_2_in1 = linear_Q_reg[0][1];mul_3_in1 = linear_Q_reg[0][2];mul_4_in1 = linear_Q_reg[0][3];
            mul_5_in1 = linear_Q_reg[0][4];mul_6_in1 = linear_Q_reg[0][5];mul_7_in1 = linear_Q_reg[0][6];mul_8_in1 = linear_Q_reg[0][7];
        end
        CAL_V_LINEAR   :begin
            mul_1_in1 = img_buffer[0][0];mul_2_in1 = img_buffer[0][0];mul_3_in1 = img_buffer[0][0];mul_4_in1 = img_buffer[0][0];
            mul_5_in1 = img_buffer[0][0];mul_6_in1 = img_buffer[0][0];mul_7_in1 = img_buffer[0][0];mul_8_in1 = img_buffer[0][0];
        end
        MAT_MUL_2      :begin
            case (T_buffer)
                'd0:begin
                    mul_1_in1 = S_reg[63];mul_2_in1 = S_reg[63];mul_3_in1 = S_reg[63];mul_4_in1 = S_reg[63];
                    mul_5_in1 = S_reg[63];mul_6_in1 = S_reg[63];mul_7_in1 = S_reg[63];mul_8_in1 = S_reg[63];
                end
                'd1:begin
                    mul_1_in1 = S_reg[0];mul_2_in1 = S_reg[0];mul_3_in1 = S_reg[0];mul_4_in1 = S_reg[0];
                    mul_5_in1 = S_reg[0];mul_6_in1 = S_reg[0];mul_7_in1 = S_reg[0];mul_8_in1 = S_reg[0];
                end
                'd2:begin
                    mul_1_in1 = S_reg[0];mul_2_in1 = S_reg[0];mul_3_in1 = S_reg[0];mul_4_in1 = S_reg[0];
                    mul_5_in1 = S_reg[0];mul_6_in1 = S_reg[0];mul_7_in1 = S_reg[0];mul_8_in1 = S_reg[0];
                end   
            endcase
            
        
        end
    endcase
end
always @(*) begin
    mul_1_in2 = 0;mul_2_in2 = 0;mul_3_in2 = 0;mul_4_in2 = 0;
    mul_5_in2 = 0;mul_6_in2 = 0;mul_7_in2 = 0;mul_8_in2 = 0;
    case (cs)
        READ_WEIGHT_K  :begin
            mul_1_in2 = weight_buffer_Q[0][0];mul_2_in2 = weight_buffer_Q[0][1];mul_3_in2 = weight_buffer_Q[0][2];mul_4_in2 = weight_buffer_Q[0][3];
            mul_5_in2 = weight_buffer_Q[0][4];mul_6_in2 = weight_buffer_Q[0][5];mul_7_in2 = weight_buffer_Q[0][6];mul_8_in2 = weight_buffer_Q[0][7];
        end
        READ_WEIGHT_V  :begin
            mul_1_in2 = weight_buffer_K[0][0];mul_2_in2 = weight_buffer_K[0][1];mul_3_in2 = weight_buffer_K[0][2];mul_4_in2 = weight_buffer_K[0][3];
            mul_5_in2 = weight_buffer_K[0][4];mul_6_in2 = weight_buffer_K[0][5];mul_7_in2 = weight_buffer_K[0][6];mul_8_in2 = weight_buffer_K[0][7];
        end
        MAT_MUL_1      :begin
            case (T_buffer)
                'd0:begin
                    mul_1_in2 = linear_K_reg[7][0];mul_2_in2 = linear_K_reg[7][1];mul_3_in2 = linear_K_reg[7][2];mul_4_in2 = linear_K_reg[7][3];
                    mul_5_in2 = linear_K_reg[7][4];mul_6_in2 = linear_K_reg[7][5];mul_7_in2 = linear_K_reg[7][6];mul_8_in2 = linear_K_reg[7][7];
                end 
                'd1:begin
                    mul_1_in2 = linear_K_reg[4][0];mul_2_in2 = linear_K_reg[4][1];mul_3_in2 = linear_K_reg[4][2];mul_4_in2 = linear_K_reg[4][3];
                    mul_5_in2 = linear_K_reg[4][4];mul_6_in2 = linear_K_reg[4][5];mul_7_in2 = linear_K_reg[4][6];mul_8_in2 = linear_K_reg[4][7];
                end
                'd2:begin
                    mul_1_in2 = linear_K_reg[0][0];mul_2_in2 = linear_K_reg[0][1];mul_3_in2 = linear_K_reg[0][2];mul_4_in2 = linear_K_reg[0][3];
                    mul_5_in2 = linear_K_reg[0][4];mul_6_in2 = linear_K_reg[0][5];mul_7_in2 = linear_K_reg[0][6];mul_8_in2 = linear_K_reg[0][7];
                end 
            endcase
        end
        CAL_V_LINEAR   :begin
            mul_1_in2 = weight_buffer_V[0][0];mul_2_in2 = weight_buffer_V[0][1];mul_3_in2 = weight_buffer_V[0][2];mul_4_in2 = weight_buffer_V[0][3];
            mul_5_in2 = weight_buffer_V[0][4];mul_6_in2 = weight_buffer_V[0][5];mul_7_in2 = weight_buffer_V[0][6];mul_8_in2 = weight_buffer_V[0][7];
        end
        MAT_MUL_2      :begin
            case (T_buffer)
                'd0:begin
                    mul_1_in2 = linear_V_reg[6][0];mul_2_in2 = linear_V_reg[6][1];mul_3_in2 = linear_V_reg[6][2];mul_4_in2 = linear_V_reg[6][3];
                    mul_5_in2 = linear_V_reg[6][4];mul_6_in2 = linear_V_reg[6][5];mul_7_in2 = linear_V_reg[6][6];mul_8_in2 = linear_V_reg[6][7];
                end 
                'd1:begin
                    mul_1_in2 = linear_V_reg[3][0];mul_2_in2 = linear_V_reg[3][1];mul_3_in2 = linear_V_reg[3][2];mul_4_in2 = linear_V_reg[3][3];
                    mul_5_in2 = linear_V_reg[3][4];mul_6_in2 = linear_V_reg[3][5];mul_7_in2 = linear_V_reg[3][6];mul_8_in2 = linear_V_reg[3][7];
                end
                'd2:begin
                    mul_1_in2 = linear_V_reg[7][0];mul_2_in2 = linear_V_reg[7][1];mul_3_in2 = linear_V_reg[7][2];mul_4_in2 = linear_V_reg[7][3];
                    mul_5_in2 = linear_V_reg[7][4];mul_6_in2 = linear_V_reg[7][5];mul_7_in2 = linear_V_reg[7][6];mul_8_in2 = linear_V_reg[7][7];
                end 
            endcase
        end
    endcase
end
//==============================================//
// Adder
//==============================================//
assign add_out[0] = add_1_in1 + add_1_in2;
assign add_out[1] = add_2_in1 + add_2_in2;
assign add_out[2] = add_3_in1 + add_3_in2;
assign add_out[3] = add_4_in1 + add_4_in2;
assign add_out[4] = add_5_in1 + add_5_in2;
assign add_out[5] = add_6_in1 + add_6_in2;
assign add_out[6] = add_7_in1 + add_7_in2;
assign add_out[7] = add_8_in1 + add_8_in2;
always @(*) begin
    add_1_in1 = 0;add_2_in1 = 0;add_3_in1 = 0;add_4_in1 = 0;
    add_5_in1 = 0;add_6_in1 = 0;add_7_in1 = 0;add_8_in1 = 0;
    case (cs)
        READ_WEIGHT_K  :begin
            add_1_in1 = mul_out[0];add_2_in1 = mul_out[1];add_3_in1 = mul_out[2];add_4_in1 = mul_out[3];
            add_5_in1 = mul_out[4];add_6_in1 = mul_out[5];add_7_in1 = mul_out[6];add_8_in1 = mul_out[7];
        end
        READ_WEIGHT_V  :begin
            add_1_in1 = mul_out[0];add_2_in1 = mul_out[1];add_3_in1 = mul_out[2];add_4_in1 = mul_out[3];
            add_5_in1 = mul_out[4];add_6_in1 = mul_out[5];add_7_in1 = mul_out[6];add_8_in1 = mul_out[7];
        end
        // MAT_MUL_1      :begin
        //     add_1_in1 = mul_out[0];add_2_in1 = mul_out[1];add_3_in1 = mul_out[2];add_4_in1 = mul_out[3];
        //     add_5_in1 = mul_out[4];add_6_in1 = mul_out[5];add_7_in1 = mul_out[6];add_8_in1 = mul_out[7];
        // end
        CAL_V_LINEAR   :begin
            add_1_in1 = mul_out[0];add_2_in1 = mul_out[1];add_3_in1 = mul_out[2];add_4_in1 = mul_out[3];
            add_5_in1 = mul_out[4];add_6_in1 = mul_out[5];add_7_in1 = mul_out[6];add_8_in1 = mul_out[7];
        end
        MAT_MUL_2      :begin
            add_1_in1 = mul_out[0];add_2_in1 = mul_out[1];add_3_in1 = mul_out[2];add_4_in1 = mul_out[3];
            add_5_in1 = mul_out[4];add_6_in1 = mul_out[5];add_7_in1 = mul_out[6];add_8_in1 = mul_out[7];
        end
    endcase
end
always @(*) begin
    add_1_in2 = 0;add_2_in2 = 0;add_3_in2 = 0;add_4_in2 = 0;
    add_5_in2 = 0;add_6_in2 = 0;add_7_in2 = 0;add_8_in2 = 0;
    case (cs)
        READ_WEIGHT_K:begin
            if(cnt_8 == 0)begin
                add_1_in2 = linear_Q_reg[0][0];add_2_in2 = linear_Q_reg[0][1];add_3_in2 = linear_Q_reg[0][2];add_4_in2 = linear_Q_reg[0][3];
                add_5_in2 = linear_Q_reg[0][4];add_6_in2 = linear_Q_reg[0][5];add_7_in2 = linear_Q_reg[0][6];add_8_in2 = linear_Q_reg[0][7];
            end
            else begin
                add_1_in2 = linear_Q_reg[7][0];add_2_in2 = linear_Q_reg[7][1];add_3_in2 = linear_Q_reg[7][2];add_4_in2 = linear_Q_reg[7][3];
                add_5_in2 = linear_Q_reg[7][4];add_6_in2 = linear_Q_reg[7][5];add_7_in2 = linear_Q_reg[7][6];add_8_in2 = linear_Q_reg[7][7];
            end
        end
        READ_WEIGHT_V:begin
            if(cnt_8 == 0)begin
                add_1_in2 = linear_K_reg[0][0];add_2_in2 = linear_K_reg[0][1];add_3_in2 = linear_K_reg[0][2];add_4_in2 = linear_K_reg[0][3];
                add_5_in2 = linear_K_reg[0][4];add_6_in2 = linear_K_reg[0][5];add_7_in2 = linear_K_reg[0][6];add_8_in2 = linear_K_reg[0][7];
            end
            else begin
                add_1_in2 = linear_K_reg[7][0];add_2_in2 = linear_K_reg[7][1];add_3_in2 = linear_K_reg[7][2];add_4_in2 = linear_K_reg[7][3];
                add_5_in2 = linear_K_reg[7][4];add_6_in2 = linear_K_reg[7][5];add_7_in2 = linear_K_reg[7][6];add_8_in2 = linear_K_reg[7][7];
            end
        end
        // MAT_MUL_1      :begin
        
        // end
        CAL_V_LINEAR   :begin
            // if(cnt_8 == 1)begin
            //     add_1_in2 = linear_V_reg[0][0];add_2_in2 = linear_V_reg[0][1];add_3_in2 = linear_V_reg[0][2];add_4_in2 = linear_V_reg[0][3];
            //     add_5_in2 = linear_V_reg[0][4];add_6_in2 = linear_V_reg[0][5];add_7_in2 = linear_V_reg[0][6];add_8_in2 = linear_V_reg[0][7];
            // end
            // else begin
                add_1_in2 = linear_V_reg[7][0];add_2_in2 = linear_V_reg[7][1];add_3_in2 = linear_V_reg[7][2];add_4_in2 = linear_V_reg[7][3];
                add_5_in2 = linear_V_reg[7][4];add_6_in2 = linear_V_reg[7][5];add_7_in2 = linear_V_reg[7][6];add_8_in2 = linear_V_reg[7][7];
            // end
        end
        MAT_MUL_2      :begin
            add_1_in2 = out_buffer[7][0];add_2_in2 = out_buffer[7][1];add_3_in2 = out_buffer[7][2];add_4_in2 = out_buffer[7][3];
            add_5_in2 = out_buffer[7][4];add_6_in2 = out_buffer[7][5];add_7_in2 = out_buffer[7][6];add_8_in2 = out_buffer[7][7];
        end  
    endcase
end
//==============================================//
assign mat_mul_out = (mul_out[0] + mul_out[1]) + (mul_out[2] + mul_out[3]) + (mul_out[4] + mul_out[5]) + (mul_out[6] + mul_out[7]);
assign scale_out = mat_mul_out / 3;
assign relu_out = (scale_out > 0) ? scale_out : 0;
//================================================//
// Linear QKV buffer
//================================================//
//Linear Q buffer
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_Q_reg[0][i] <= 0;
                else if(cs == READ_WEIGHT_K)begin
                    if(cnt_8 == 0)    
                        linear_Q_reg[0][i] <= linear_Q_reg[1][i];
                end
                else if(cs == MAT_MUL_1)begin
                    case (T_buffer)
                        'd1:begin
                            if(cnt_8 == 3)
                                linear_Q_reg[0][i] <= linear_Q_reg[1][i]; 
                        end
                        'd2:begin
                            if(cnt_8 == 7)
                                linear_Q_reg[0][i] <= linear_Q_reg[1][i];
                        end  
                    endcase
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_Q_reg[1][i] <= 0;
                else if(cs == READ_WEIGHT_K)begin
                    if(cnt_8 == 0)
                        linear_Q_reg[1][i] <= linear_Q_reg[2][i];
                end
                else if(cs == MAT_MUL_1)begin
                    case (T_buffer)
                        'd1:begin
                            if(cnt_8 == 3)
                                linear_Q_reg[1][i] <= linear_Q_reg[2][i]; 
                        end
                        'd2:begin
                            if(cnt_8 == 7)
                                linear_Q_reg[1][i] <= linear_Q_reg[2][i];
                        end  
                    endcase
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_Q_reg[2][i] <= 0;
                else if(cs == READ_WEIGHT_K)begin
                    if(cnt_8 == 0)
                        linear_Q_reg[2][i] <= linear_Q_reg[3][i];
                end
                else if(cs == MAT_MUL_1)begin
                    case (T_buffer)
                        'd1:begin
                            if(cnt_8 == 3)
                                linear_Q_reg[2][i] <= linear_Q_reg[3][i]; 
                        end
                        'd2:begin
                            if(cnt_8 == 7)
                                linear_Q_reg[2][i] <= linear_Q_reg[3][i];
                        end  
                    endcase
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_Q_reg[3][i] <= 0;
                else if(cs == READ_WEIGHT_K)begin
                    if(cnt_8 == 0)
                        linear_Q_reg[3][i] <= linear_Q_reg[4][i];
                end
                else if(cs == MAT_MUL_1)begin
                    case (T_buffer)
                        'd1:begin
                            if(cnt_8 == 3)
                                linear_Q_reg[3][i] <= linear_Q_reg[0][i]; 
                        end
                        'd2:begin
                            if(cnt_8 == 7)
                                linear_Q_reg[3][i] <= linear_Q_reg[4][i];
                        end  
                    endcase
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_Q_reg[4][i] <= 0;
                else if(cs == READ_WEIGHT_K)begin
                    if(cnt_8 == 0)
                        linear_Q_reg[4][i] <= linear_Q_reg[5][i];
                end
                else if(cs == MAT_MUL_1)begin
                    case (T_buffer)
                        'd2:begin
                            if(cnt_8 == 7)
                                linear_Q_reg[4][i] <= linear_Q_reg[5][i];
                        end  
                    endcase
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_Q_reg[5][i] <= 0;
                else if(cs == READ_WEIGHT_K)begin
                    if(cnt_8 == 0)
                        linear_Q_reg[5][i] <= linear_Q_reg[6][i];
                end
                else if(cs == MAT_MUL_1)begin
                    case (T_buffer)
                        'd2:begin
                            if(cnt_8 == 7)
                                linear_Q_reg[5][i] <= linear_Q_reg[6][i];
                        end  
                    endcase
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_Q_reg[6][i] <= 0;
                else if(cs == READ_WEIGHT_K)begin
                    if(cnt_8 == 0)
                        linear_Q_reg[6][i] <= linear_Q_reg[7][i];
                end
                else if(cs == MAT_MUL_1)begin
                    case (T_buffer)
                        'd2:begin
                            if(cnt_8 == 7)
                                linear_Q_reg[6][i] <= linear_Q_reg[7][i];
                        end  
                    endcase
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_Q_reg[7][i] <= 0;
                else if(cs == READ_WEIGHT_K)begin
                    if(cnt_8 == 0)
                        linear_Q_reg[7][i] <= linear_Q_reg[0][i] + add_out[i];
                    else
                        linear_Q_reg[7][i] <= add_out[i];    
                end
                else if(cs == MAT_MUL_1)begin
                    case (T_buffer)
                        'd2:begin
                            if(cnt_8 == 7)
                                linear_Q_reg[7][i] <= linear_Q_reg[0][i];
                        end  
                    endcase
                end
            end
        end
    endgenerate
//Linear K buffer
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_K_reg[0][i] <= 0;
                else if(cs == READ_WEIGHT_V)begin
                    if(cnt_8 == 0)
                        linear_K_reg[0][i] <= linear_K_reg[1][i];
                end
                else if(cs == MAT_MUL_1)begin
                    // case (T_buffer)
                    //     'd4:begin
                            // if(cnt_64 == 7 || cnt_64 == 15 || cnt_64 == 23 || cnt_64 == 31 || cnt_64 == 39 || cnt_64 == 47 || cnt_64 == 55)begin
                            //     linear_K_reg[0][i] <= linear_K_reg[2][i];
                            // end
                            // else begin
                                linear_K_reg[0][i] <= linear_K_reg[1][i];
                            // end
                        // end 
                    // endcase
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_K_reg[1][i] <= 0;
                else if(cs == READ_WEIGHT_V)begin
                    if(cnt_8 == 0)
                        linear_K_reg[1][i] <= linear_K_reg[2][i];
                end
                else if(cs == MAT_MUL_1)begin
                    // case (T_buffer)
                    //     'd4:begin
                            // if(cnt_64 == 7 || cnt_64 == 15 || cnt_64 == 23 || cnt_64 == 31 || cnt_64 == 39 || cnt_64 == 47 || cnt_64 == 55)begin
                            //     linear_K_reg[1][i] <= linear_K_reg[3][i];
                            // end
                            // else begin
                                linear_K_reg[1][i] <= linear_K_reg[2][i];
                            // end
                    //     end 
                    // endcase
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_K_reg[2][i] <= 0;
                else if(cs == READ_WEIGHT_V)begin
                    if(cnt_8 == 0)
                        linear_K_reg[2][i] <= linear_K_reg[3][i];
                end
                else if(cs == MAT_MUL_1)begin
                    // case (T_buffer)
                    //     'd4:begin
                            // if(cnt_64 == 7 || cnt_64 == 15 || cnt_64 == 23 || cnt_64 == 31 || cnt_64 == 39 || cnt_64 == 47 || cnt_64 == 55)begin
                            //     linear_K_reg[2][i] <= linear_K_reg[4][i];
                            // end
                            // else begin
                                linear_K_reg[2][i] <= linear_K_reg[3][i];
                            // end
                    //     end 
                    // endcase
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_K_reg[3][i] <= 0;
                else if(cs == READ_WEIGHT_V)begin
                    if(cnt_8 == 0)
                        linear_K_reg[3][i] <= linear_K_reg[4][i];
                end
                else if(cs == MAT_MUL_1)begin
                    // case (T_buffer)
                    //     'd4:begin
                            // if(cnt_64 == 7 || cnt_64 == 15 || cnt_64 == 23 || cnt_64 == 31 || cnt_64 == 39 || cnt_64 == 47 || cnt_64 == 55)begin
                            //     linear_K_reg[3][i] <= linear_K_reg[5][i];
                            // end
                            // else begin
                                linear_K_reg[3][i] <= linear_K_reg[4][i];
                            // end
                    //     end 
                    // endcase
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_K_reg[4][i] <= 0;
                else if(cs == READ_WEIGHT_V)begin
                    if(cnt_8 == 0)
                        linear_K_reg[4][i] <= linear_K_reg[5][i];
                end
                else if(cs == MAT_MUL_1)begin
                    // case (T_buffer)
                    //     'd4:begin
                    //         if(cnt_64 == 3 || cnt_64 == 7 || cnt_64 == 11)begin
                    //             linear_K_reg[4][i] <= linear_K_reg[6][i];
                    //         end
                    //         else begin
                    //             linear_K_reg[4][i] <= linear_K_reg[5][i];
                    //         end
                    //     end
                    //     'd0:begin
                    //         if (cnt_64 == 7 || cnt_64 == 15 || cnt_64 == 23 || cnt_64 == 31 || cnt_64 == 39 || cnt_64 == 47 || cnt_64 == 55) begin
                    //             linear_K_reg[4][i] <= linear_K_reg[6][i];
                    //         end
                    //         else begin
                    //             linear_K_reg[4][i] <= linear_K_reg[5][i];
                    //         end
                    //     end
                    // endcase
                    linear_K_reg[4][i] <= linear_K_reg[5][i];
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_K_reg[5][i] <= 0;
                else if(cs == READ_WEIGHT_V)begin
                    if(cnt_8 == 0)
                        linear_K_reg[5][i] <= linear_K_reg[6][i];
                end
                else if(cs == MAT_MUL_1)begin
                    // case (T_buffer)
                    //     'd4:begin
                    //         if(cnt_64 == 3 || cnt_64 == 7 || cnt_64 == 11)begin
                    //             linear_K_reg[5][i] <= linear_K_reg[7][i];
                    //         end
                    //         else begin
                    //             linear_K_reg[5][i] <= linear_K_reg[6][i];
                    //         end
                    //     end
                    //     'd0:begin
                    //         if (cnt_64 == 7 || cnt_64 == 15 || cnt_64 == 23 || cnt_64 == 31 || cnt_64 == 39 || cnt_64 == 47 || cnt_64 == 55) begin
                    //             linear_K_reg[5][i] <= linear_K_reg[7][i];
                    //         end
                    //         else begin
                    //             linear_K_reg[5][i] <= linear_K_reg[6][i];
                    //         end
                    //     end
                    // endcase
                    linear_K_reg[5][i] <= linear_K_reg[6][i];
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_K_reg[6][i] <= 0;
                else if(cs == READ_WEIGHT_V)begin
                    if(cnt_8 == 0)
                        linear_K_reg[6][i] <= linear_K_reg[7][i];
                end
                else if(cs == MAT_MUL_1)begin
                    // case (T_buffer)
                    //     'd4:begin
                    //         if(cnt_64 == 3 || cnt_64 == 7 || cnt_64 == 11)begin
                    //             linear_K_reg[6][i] <= linear_K_reg[4][i];
                    //         end
                    //         else begin
                    //             linear_K_reg[6][i] <= linear_K_reg[7][i];
                    //         end
                    //     end
                    //     'd0:begin
                    //         if (cnt_64 == 7 || cnt_64 == 15 || cnt_64 == 23 || cnt_64 == 31 || cnt_64 == 39 || cnt_64 == 47 || cnt_64 == 55) begin
                    //             linear_K_reg[6][i] <= linear_K_reg[0][i];
                    //         end
                    //         else begin
                    //             linear_K_reg[6][i] <= linear_K_reg[7][i];
                    //         end
                    //     end
                    // endcase
                    linear_K_reg[6][i] <= linear_K_reg[7][i];
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_K_reg[7][i] <= 0;
                else if(cs == READ_WEIGHT_V)begin
                    if(cnt_8 == 0)
                        linear_K_reg[7][i] <= linear_K_reg[0][i] + add_out[i];
                    else
                        linear_K_reg[7][i] <= add_out[i];
                end
                else if(cs == MAT_MUL_1)begin
                    case (T_buffer)
                        'd1:begin
                            // if(cnt_64 == 3 || cnt_64 == 7 || cnt_64 == 11)begin
                            //     linear_K_reg[7][i] <= linear_K_reg[5][i];
                            // end
                            // else begin
                                linear_K_reg[7][i] <= linear_K_reg[4][i];
                            // end
                        end
                        'd2:begin
                            // if (cnt_64 == 7 || cnt_64 == 15 || cnt_64 == 23 || cnt_64 == 31 || cnt_64 == 39 || cnt_64 == 47 || cnt_64 == 55) begin
                            //     linear_K_reg[7][i] <= linear_K_reg[1][i];
                            // end
                            // else begin
                                linear_K_reg[7][i] <= linear_K_reg[0][i];
                            // end
                        end
                    endcase
                end
            end
        end
    endgenerate
//Linear V buffer
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_V_reg[0][i] <= 0;
                else if(cs == CAL_V_LINEAR)begin
                    if(cnt_8 == 0)
                        linear_V_reg[0][i] <= linear_V_reg[1][i];
                end   
                else if(cs == MAT_MUL_2)begin
                    linear_V_reg[0][i] <= linear_V_reg[1][i];
                end 
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_V_reg[1][i] <= 0;
                else if(cs == CAL_V_LINEAR)begin
                    if(cnt_8 == 0)
                        linear_V_reg[1][i] <= linear_V_reg[2][i];
                end
                else if(cs == MAT_MUL_2)begin
                    linear_V_reg[1][i] <= linear_V_reg[2][i];
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_V_reg[2][i] <= 0;
                else if(cs == CAL_V_LINEAR)begin
                    if(cnt_8 == 0)
                        linear_V_reg[2][i] <= linear_V_reg[3][i];
                end
                else if(cs == MAT_MUL_2)begin
                    linear_V_reg[2][i] <= linear_V_reg[3][i];
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_V_reg[3][i] <= 0;
                else if(cs == CAL_V_LINEAR)begin
                    if(cnt_8 == 0)
                        linear_V_reg[3][i] <= linear_V_reg[4][i];
                end
                else if(cs == MAT_MUL_2)begin
                    linear_V_reg[3][i] <= linear_V_reg[4][i];
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_V_reg[4][i] <= 0;
                else if(cs == CAL_V_LINEAR)begin
                    if(cnt_8 == 0)
                        linear_V_reg[4][i] <= linear_V_reg[5][i];
                end
                else if(cs == MAT_MUL_2)begin
                    linear_V_reg[4][i] <= linear_V_reg[5][i];
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_V_reg[5][i] <= 0;
                else if(cs == CAL_V_LINEAR)begin
                    if(cnt_8 == 0)
                        linear_V_reg[5][i] <= linear_V_reg[6][i];
                end
                else if(cs == MAT_MUL_2)begin
                    linear_V_reg[5][i] <= linear_V_reg[6][i];
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_V_reg[6][i] <= 0;
                else if(cs == CAL_V_LINEAR)begin
                    if(cnt_8 == 0)
                        linear_V_reg[6][i] <= add_out[i];
                end
                else if(cs == MAT_MUL_2)begin
                    case (T_buffer)
                        'd1:linear_V_reg[6][i] <= linear_V_reg[3][i]; 
                        'd2:linear_V_reg[6][i] <= linear_V_reg[7][i];
                    endcase
                end
            end
        end
    endgenerate
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if(ns == IDLE)
                    linear_V_reg[7][i] <= 0;
                else if(cs == CAL_V_LINEAR)begin
                    if(cnt_8 == 0)
                        linear_V_reg[7][i] <= linear_V_reg[0][i];
                    else
                        linear_V_reg[7][i] <= add_out[i];
                end
                else if(cs == MAT_MUL_2)begin
                    linear_V_reg[7][i] <= linear_V_reg[0][i];
                end
            end
        end
    endgenerate
    // always @(posedge clk ) begin
    //     if(ns == IDLE)begin
    //         linear_V_reg[0][7] <= 0;
    //         linear_V_reg[1][7] <= 0;
    //         linear_V_reg[2][7] <= 0;
    //         linear_V_reg[3][7] <= 0;
    //         linear_V_reg[4][7] <= 0;
    //         linear_V_reg[5][7] <= 0;
    //         linear_V_reg[6][7] <= 0;
    //         linear_V_reg[7][7] <= 0;
    //     end
    //     else if(ns == CAL_V_LINEAR)begin
    //         if(cnt_8 == 7)begin
    //             linear_V_reg[0][7] <= linear_V_reg[1][7];
    //             linear_V_reg[1][7] <= linear_V_reg[2][7];
    //             linear_V_reg[2][7] <= linear_V_reg[3][7];
    //             linear_V_reg[3][7] <= linear_V_reg[4][7];
    //             linear_V_reg[4][7] <= linear_V_reg[5][7];
    //             linear_V_reg[5][7] <= linear_V_reg[6][7];
    //             linear_V_reg[6][7] <= linear_V_reg[7][7];
    //             linear_V_reg[7][7] <= add_out[7];
    //         end
    //     end
    //     else if(ns == MAT_MUL_2)begin
    //         linear_V_reg[0][7] <= linear_V_reg[1][0];
    //         linear_V_reg[1][7] <= linear_V_reg[2][0];
    //         linear_V_reg[2][7] <= linear_V_reg[3][0];
    //         linear_V_reg[3][7] <= linear_V_reg[4][0];
    //         linear_V_reg[4][7] <= linear_V_reg[5][0];
    //         linear_V_reg[5][7] <= linear_V_reg[6][0];
    //         linear_V_reg[6][7] <= linear_V_reg[7][0];
    //         linear_V_reg[7][7] <= linear_V_reg[0][0];
    //     end
    // end
//================================================//
// S_reg
//================================================//
always @(posedge clk ) begin
    if(ns == IDLE)begin
        for(k = 0; k < 64; k = k + 1)begin
            S_reg[k] <= 0;
        end
    end
    else if(ns == MAT_MUL_1)begin
        case (T_buffer)
            'd0:S_reg[cnt_64]      <= relu_out;
            'd1:S_reg[cnt_64 - 32] <= relu_out; 
            'd2:S_reg[cnt_64]      <= relu_out;
        endcase
        
    end
    else if(cs == MAT_MUL_2)begin
        for(k = 0; k < 63; k = k + 1)begin
            S_reg[k] <= S_reg[k + 1];
        end
        S_reg[63] <= S_reg[63];
    end
end
//================================================//
// out_buffer
//================================================//
always @(posedge clk ) begin
    if(ns == IDLE)begin
        for(k = 0; k < 8; k = k + 1)begin
            out_buffer[0][k] <= 0;
            out_buffer[1][k] <= 0;
            out_buffer[2][k] <= 0;
            out_buffer[3][k] <= 0;
            out_buffer[4][k] <= 0;
            out_buffer[5][k] <= 0;
            out_buffer[6][k] <= 0;
            out_buffer[7][k] <= 0;
        end
    end
    else if(cs == MAT_MUL_2)begin
        case (T_buffer)
            'd0    :begin
                out_buffer[7][0] <= add_out[0];out_buffer[7][1] <= add_out[1];out_buffer[7][2] <= add_out[2];out_buffer[7][3] <= add_out[3];
                out_buffer[7][4] <= add_out[4];out_buffer[7][5] <= add_out[5];out_buffer[7][6] <= add_out[6];out_buffer[7][7] <= add_out[7];
            end
            'd1    :begin
                if(cnt_8 == 3)begin
                    for(k = 0; k < 8; k = k + 1)begin
                        out_buffer[7][k] <= out_buffer[0][k];
                        out_buffer[6][k] <= add_out[k];
                        out_buffer[5][k] <= out_buffer[6][k];
                        out_buffer[4][k] <= out_buffer[5][k];
                        out_buffer[3][k] <= out_buffer[4][k];
                    end
                end
                else begin
                    for(k = 0; k < 8; k = k + 1)begin
                        out_buffer[7][k] <= add_out[k];
                    end
                end
            end
            'd2    :begin
                if(cnt_8 == 7)begin
                    for(k = 0; k < 8; k = k + 1)begin
                        out_buffer[7][k] <= out_buffer[0][k];
                        out_buffer[6][k] <= add_out[k];
                        out_buffer[5][k] <= out_buffer[6][k];
                        out_buffer[4][k] <= out_buffer[5][k];
                        out_buffer[3][k] <= out_buffer[4][k];
                        out_buffer[2][k] <= out_buffer[3][k];
                        out_buffer[1][k] <= out_buffer[2][k];
                        out_buffer[0][k] <= out_buffer[1][k];
                    end
                end
                else begin
                    for(k = 0; k < 8; k = k + 1)begin
                        out_buffer[7][k] <= add_out[k];
                    end
                end
            end 
        endcase
    end
    else if(cs == OUT)begin
        for(k = 0; k < 8; k = k + 1)begin
            for(l = 0; l < 7; l = l + 1)begin
                out_buffer[k][l] <= out_buffer[k][l + 1];
            end
        end
        out_buffer[0][7] <= out_buffer[1][0];
        out_buffer[1][7] <= out_buffer[2][0];
        out_buffer[2][7] <= out_buffer[3][0];
        out_buffer[3][7] <= out_buffer[4][0];
        out_buffer[4][7] <= out_buffer[5][0];
        out_buffer[5][7] <= out_buffer[6][0];
        out_buffer[6][7] <= out_buffer[7][0];
        out_buffer[7][7] <= out_buffer[0][0];
    end
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
        case (T_buffer)
            'd0    : out_data = out_buffer[7][0];
            'd1    : out_data = out_buffer[3][0];
            'd2    : out_data = out_buffer[7][0];
            default: out_data = 0;
        endcase
    end
    else
        out_data = 0;
end
endmodule
