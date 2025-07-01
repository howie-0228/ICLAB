//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/9
//		Version		: v1.0
//   	File Name   : MDC.v
//   	Module Name : MDC
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "HAMMING_IP.v"
//synopsys translate_on

module MDC(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_data, 
	in_mode,
    // Output signals
    out_valid, 
	out_data
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [8:0] in_mode;
input [14:0] in_data;

output reg out_valid;
output reg [206:0] out_data;
//==================================================================
// parameter & integer
//==================================================================
// parameter IDLE = 0, CALC = 1, OUT = 2;

genvar  j;
integer i;
//==================================================================
// reg & wire
//==================================================================
reg signed [10:0] in_data_dec;
reg [4:0] in_mode_dec;

reg signed [10:0] HM_reg[0:7];
reg [1:0] dec_inst;

reg [4:0] cnt_16;
reg [4:0] cnt_16_ns;

reg signed [10:0] mult11x11_0_in1, mult11x11_1_in1, mult11x11_2_in1;
reg signed [10:0] mult11x11_0_in2, mult11x11_1_in2, mult11x11_2_in2;

reg signed [21:0] mult22x11_0_in1, mult22x11_1_in1;
reg signed [10:0] mult22x11_0_in2, mult22x11_1_in2;

reg signed [33:0] mult34x11_0_in1;
reg signed [10:0] mult34x11_0_in2;

wire signed [21:0] mult11x11_0_out, mult11x11_1_out, mult11x11_2_out;
wire signed [31:0] mult22x11_0_out, mult22x11_1_out;
wire signed [43:0] mult34x11_0_out;

reg signed [21:0] det_2x2[0:5];
reg signed [33:0] det_3x3[0:2];
reg signed [45:0] det_4x4;

reg signed [21:0] add_2x2_in0;
reg signed [21:0] add_2x2_in1;
wire signed [21:0] add_2x2_out;

reg signed [33:0] add_3x3_0_in0;
reg signed [33:0] add_3x3_0_in1;//31
wire signed [33:0] add_3x3_0_out;

reg signed [33:0] add_3x3_1_in0;
reg signed [33:0] add_3x3_1_in1;//31
wire signed [33:0] add_3x3_1_out;

reg signed [45:0] add_4x4_in0;
reg signed [45:0] add_4x4_in1;//43
wire signed [45:0] add_4x4_out;

//==================================================================
// design
//==================================================================
//IP
    HAMMING_IP #(.IP_BIT(11)) u_HM_IP_0(in_data, in_data_dec);
    HAMMING_IP #(.IP_BIT(5))  u_HM_IP_1(in_mode, in_mode_dec);
//==================================================================
// Counter
//==================================================================
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) 
            cnt_16 <= 0;
        else  
            cnt_16 <= cnt_16_ns;
    end
    always @(*) begin
        cnt_16_ns = cnt_16;
        
        if(cnt_16 == 17)
            cnt_16_ns = 0;
        else if(in_valid | cnt_16 != 0)
            cnt_16_ns = cnt_16 + 1;    
    end
//==================================================================
// Input Register
//==================================================================
    always @(posedge clk) begin
        if(in_valid && cnt_16 == 0)begin
            case (in_mode_dec)
                5'b00100:dec_inst <= 2'd0;
                5'b00110:dec_inst <= 2'd1;
                5'b10110:dec_inst <= 2'd2;  
            endcase
        end
    end
    generate
        for ( j = 0 ; j < 7; j = j + 1) begin
            always @(posedge clk) begin
                if(in_valid) HM_reg[j] <= HM_reg[j+1];
            end    
        end
    endgenerate
    always @(posedge clk) begin
        if(in_valid) HM_reg[7] <= in_data_dec;
    end
//==================================================================
// Multiplication
//==================================================================
assign mult11x11_0_out = mult11x11_0_in1 * mult11x11_0_in2;
assign mult11x11_1_out = mult11x11_1_in1 * mult11x11_1_in2;
assign mult11x11_2_out = mult11x11_2_in1 * mult11x11_2_in2;

assign mult22x11_0_out = mult22x11_0_in1 * mult22x11_0_in2;
assign mult22x11_1_out = mult22x11_1_in1 * mult22x11_1_in2;

assign mult34x11_0_out = mult34x11_0_in1 * mult34x11_0_in2;

always @(*) begin
    mult11x11_0_in1 = HM_reg[2];mult11x11_0_in2 = HM_reg[7];
    mult11x11_1_in1 = HM_reg[3];mult11x11_1_in2 = HM_reg[6];
    mult11x11_2_in1 = HM_reg[1];mult11x11_2_in2 = HM_reg[7];
end
always @(*) begin
    mult22x11_0_in1 = 0;mult22x11_0_in2 = HM_reg[7];
    mult22x11_1_in1 = 0;mult22x11_1_in2 = HM_reg[7];
    case (cnt_16)
        8:begin
            mult22x11_0_in1 = HM_reg[0];
            mult22x11_1_in1 = HM_reg[3];mult22x11_1_in2 = HM_reg[4];
        end
        9:begin
            mult22x11_0_in1 = det_2x2[1];//8x1256
            mult22x11_1_in1 = det_2x2[3];//8x2367
        end
        10:begin
            mult22x11_0_in1 = det_2x2[2];//9x0246
            mult22x11_1_in1 = det_2x2[3];//9x2367
        end
        11:begin
            mult22x11_0_in1 = det_2x2[0];//10x0145
            mult22x11_1_in1 = det_2x2[4];//10x1357
        end
        12:begin
            mult22x11_0_in1 = det_2x2[0];//11x0145
            mult22x11_1_in1 = det_2x2[1];//11x1256
        end
        13:begin
            mult22x11_0_in1 = det_2x2[3];//12x56910
        end
        14:begin
            mult22x11_0_in1 = det_2x2[0];//13x671011
            mult22x11_1_in1 = det_2x2[4];//13x46810
        end
        15:begin
            mult22x11_0_in1 = det_2x2[2];//14x4589
            mult22x11_1_in1 = det_2x2[1];//14x57911
        end
        16:begin
            mult22x11_1_in1 = det_2x2[3];//15x56910
        end
    endcase
end
always @(*) begin
    mult34x11_0_in1 = 0;mult34x11_0_in2 = HM_reg[7];
    case (dec_inst)
        'd1:begin
            mult34x11_0_in1 = HM_reg[3];mult34x11_0_in2 = HM_reg[5];
        end
        'd2:begin
            case (cnt_16)
                7:begin
                    mult34x11_0_in1 = HM_reg[3];mult34x11_0_in2 = HM_reg[5];
                end
                8:begin
                    mult34x11_0_in1 = HM_reg[3];mult34x11_0_in2 = HM_reg[5];
                end
                9:begin
                    mult34x11_0_in1 = det_2x2[4];//8x1357
                end
                10:begin
                    mult34x11_0_in1 = det_2x2[5];//9x0347
                end
                11:begin
                    mult34x11_0_in1 = det_2x2[5];//10x0347
                end
                12:begin
                    mult34x11_0_in1 = det_2x2[2];//11x0246
                end
                13:begin
                    mult34x11_0_in1 = det_3x3[1];//12x12356791011
                end
                14:begin
                    mult34x11_0_in1 = det_3x3[2];//13x02346781011
                end
                15:begin
                    mult34x11_0_in1 = det_3x3[1];//14x0134578911
                end
                16:begin
                    mult34x11_0_in1 = det_3x3[0];//15x0124568910
                end 
            endcase
        end
    endcase
end
//==================================================================
// Determinant Calculation
//==================================================================
assign add_2x2_out   = add_2x2_in0   + add_2x2_in1;
assign add_3x3_0_out = add_3x3_0_in0 + add_3x3_0_in1;
assign add_3x3_1_out = add_3x3_1_in0 + add_3x3_1_in1;
assign add_4x4_out   = add_4x4_in0   + add_4x4_in1;
always @(*) begin
    add_2x2_in0 = mult11x11_0_out;
    add_2x2_in1 = ~mult11x11_1_out + 1;
end
always @(*) begin
    add_3x3_0_in0 = 0;
    add_3x3_0_in1 = 0;
    case (cnt_16)
        'd8:begin
            add_3x3_0_in0 = mult22x11_0_out;//0347
            add_3x3_0_in1 = ~mult22x11_1_out + 1;//0347
        end
        'd9:begin
            add_3x3_0_in0 = 0;
            add_3x3_0_in1 = mult22x11_0_out;//8x1256
        end 
        'd10:begin
            add_3x3_0_in0 = det_3x3[0];
            add_3x3_0_in1 = ~mult22x11_0_out + 1;//9x0246
        end
        'd11:begin
            add_3x3_0_in0 = det_3x3[0];
            add_3x3_0_in1 = mult22x11_0_out;//10x0145
        end 
        'd12:begin
            add_3x3_0_in0 = det_4x4;
            add_3x3_0_in1 = mult22x11_0_out;;//11x0145
        end
        'd13:begin
            add_3x3_0_in0 = 0;
            add_3x3_0_in1 = mult22x11_0_out;//12x56910
        end
        'd14:begin
            add_3x3_0_in0 = det_3x3[2];
            add_3x3_0_in1 = ~mult22x11_1_out + 1;//13x46810
        end
        'd15:begin
            add_3x3_0_in0 = det_3x3[2];
            add_3x3_0_in1 = mult22x11_0_out;//14x4589
        end
    endcase
end
always @(*) begin
    add_3x3_1_in0 = 0;
    add_3x3_1_in1 = 0;
    case (cnt_16)
        'd9:begin
            add_3x3_1_in0 = 0;
            add_3x3_1_in1 = mult22x11_1_out;//8x2367
        end
        'd10:begin
            add_3x3_1_in0 = 0;
            add_3x3_1_in1 = mult22x11_1_out;//9x2367
        end 
        'd11:begin
            add_3x3_1_in0 = det_3x3[1];
            add_3x3_1_in1 = ~mult22x11_1_out + 1;//10x1357
        end
        'd12:begin
            add_3x3_1_in0 = det_3x3[1];
            add_3x3_1_in1 = mult22x11_1_out;//11x1256
        end 
        'd14:begin
            add_3x3_1_in0 = 0;
            add_3x3_1_in1 = mult22x11_0_out;//13x671011
        end
        'd15:begin
            add_3x3_1_in0 = det_4x4;
            add_3x3_1_in1 = ~mult22x11_1_out + 1;//14x57911
        end
        'd16:begin
            add_3x3_1_in0 = det_4x4;
            add_3x3_1_in1 = mult22x11_1_out;//15x56910
        end
    endcase
end
always @(*) begin
    add_4x4_in0 = mult11x11_2_out;
    add_4x4_in1 = ~mult34x11_0_out + 1;
    case (dec_inst)
        'd2:begin
            case (cnt_16)
                'd9:begin
                    add_4x4_in0 = 0;
                    add_4x4_in1 = mult34x11_0_out;//8x1357
                end
                'd10:begin
                    add_4x4_in0 = det_4x4;
                    add_4x4_in1 = ~mult34x11_0_out + 1;//9x0347
                end
                'd11:begin
                    add_4x4_in0 = det_3x3[2];
                    add_4x4_in1 = ~mult34x11_0_out + 1;;
                end
                'd12:begin
                    add_4x4_in0 = det_3x3[2];
                    add_4x4_in1 = mult34x11_0_out;//11x0246
                end 
                'd13:begin
                    add_4x4_in0 = 0;
                    add_4x4_in1 = ~mult34x11_0_out + 1;//12x12356791011
                end 
                'd14:begin
                    add_4x4_in0 = det_4x4;
                    add_4x4_in1 = mult34x11_0_out;//13x02346781011
                end
                'd15:begin
                    add_4x4_in0 = det_4x4;
                    add_4x4_in1 = ~mult34x11_0_out + 1;//14x0134578911
                end
                'd16:begin
                    add_4x4_in0 = det_4x4;
                    add_4x4_in1 = mult34x11_0_out;//15x0124568910
                end 
            endcase
        end  
    endcase
end
//TODO ba reset
always @(posedge clk ) begin
    if(out_valid)begin
        for ( i = 0 ; i < 6; i = i + 1) begin
            det_2x2[i] <= 0;
        end
    end
    else begin
        case (dec_inst)
            'd0:begin
                case (cnt_16)
                    'd6 :det_2x2[0] <= add_2x2_out;//0145
                    'd7 :det_2x2[1] <= add_2x2_out;//1256
                    'd8 :det_2x2[2] <= add_2x2_out;//2367
                    'd10:det_2x2[3] <= add_2x2_out;//4589
                    'd11:det_2x2[4] <= add_2x2_out;//56910
                    'd12:det_2x2[5] <= add_2x2_out;//671011 
                endcase
            end 
            'd1:begin
                case (cnt_16)
                    'd6 :begin
                        det_2x2[0] <= add_2x2_out;//0145
                    end
                    'd7 :begin
                        det_2x2[1] <= add_2x2_out;//1256
                        det_2x2[2] <= add_4x4_out;//0246
                    end
                    'd8 :begin
                        det_2x2[3] <= add_2x2_out;//2367
                        det_2x2[4] <= add_4x4_out;//1357
                        // det_2x2[5] <= add_3x3_0_out;//0347
                    end
                    'd10:begin
                        det_2x2[2] <= add_2x2_out;//4589
                    end
                    'd11:begin
                        det_2x2[3] <= add_2x2_out;//56910
                        det_2x2[4] <= add_4x4_out;//46810
                    end
                    'd12:begin
                        det_2x2[0] <= add_2x2_out;//671011
                        det_2x2[1] <= add_4x4_out;//57911
                    end
                endcase
            end
            'd2:begin
                case (cnt_16)
                    'd6 :begin
                        det_2x2[0] <= add_2x2_out;//0145
                    end
                    'd7 :begin
                        det_2x2[1] <= add_2x2_out;//1256
                        det_2x2[2] <= add_4x4_out;//0246
                    end
                    'd8 :begin
                        det_2x2[3] <= add_2x2_out;//2367
                        det_2x2[4] <= add_4x4_out;//1357
                        det_2x2[5] <= add_3x3_0_out;//0347
                    end
                endcase
            end
        endcase 
    end
end
always @(posedge clk ) begin
    if(out_valid)begin
        for ( i = 0 ; i < 3; i = i + 1) begin
            det_3x3[i] <= 0;
        end
    end
    else begin
        case (dec_inst)
            'd0:begin
                case (cnt_16)
                    'd14:det_3x3[0] <= add_2x2_out;//891213
                    'd15:det_3x3[1] <= add_2x2_out;//9101314
                    'd16:det_3x3[2] <= add_2x2_out;//10111415
                endcase
            end
            'd1:begin
                case (cnt_16)
                    'd9 :det_3x3[0] <= add_3x3_0_out;
                    'd10:begin
                        det_3x3[0] <= add_3x3_0_out;
                        det_3x3[1] <= add_3x3_1_out;
                    end
                    'd11:begin
                        det_3x3[0] <= add_3x3_0_out;
                        det_3x3[1] <= add_3x3_1_out;
                    end
                    'd12:det_3x3[1] <= add_3x3_1_out;
                    'd13:det_3x3[2] <= add_3x3_0_out;
                    'd14:det_3x3[2] <= add_3x3_0_out;
                    'd15:det_3x3[2] <= add_3x3_0_out;
                endcase
            end 
            'd2:begin
                case (cnt_16)
                    'd9 :begin
                        det_3x3[0] <= add_3x3_0_out;
                        det_3x3[2] <= add_3x3_1_out;
                    end
                    'd10:begin
                        det_3x3[0] <= add_3x3_0_out;
                        det_3x3[1] <= add_3x3_1_out;
                    end
                    'd11:begin
                        det_3x3[0] <= add_3x3_0_out;
                        det_3x3[1] <= add_3x3_1_out;
                        det_3x3[2] <= add_4x4_out;
                    end
                    'd12:begin
                        det_3x3[1] <= add_3x3_1_out;
                        det_3x3[2] <= add_4x4_out;
                    end
                    'd13:begin
                        det_3x3[1] <= det_4x4;
                    end
                endcase
            end
        endcase
    end
end
always @(posedge clk) begin
    if(out_valid)
        det_4x4 <= 0;
    else begin
        case (dec_inst)
            'd1:det_4x4 <= add_3x3_1_out; 
            'd2:begin
                case (cnt_16)
                    'd9 :det_4x4 <= add_4x4_out;
                    'd10:det_4x4 <= add_4x4_out;
                    'd12:det_4x4 <= add_3x3_0_out; 
                    'd13:det_4x4 <= add_4x4_out;
                    'd14:det_4x4 <= add_4x4_out;
                    'd15:det_4x4 <= add_4x4_out;
                    'd16:det_4x4 <= add_4x4_out;
                endcase
            end
        endcase
    end
end
//==================================================================
// Output
//==================================================================
always @(*) begin
    if(cnt_16 == 17)
        out_valid = 1;
    else
        out_valid = 0;
end
always @(*) begin
    if(out_valid)begin
        case (dec_inst)
            'd0:begin
                out_data = {{det_2x2[0][21], det_2x2[0]}, {det_2x2[1][21], det_2x2[1]}, {det_2x2[2][21], det_2x2[2]}, {det_2x2[3][21], det_2x2[3]}, {det_2x2[4][21], det_2x2[4]}, {det_2x2[5][21], det_2x2[5]}, det_3x3[0][22:0], det_3x3[1][22:0], det_3x3[2][22:0]};
            end 
            'd1:begin
                out_data = {3'b000, {{17{det_3x3[0][33]}}, det_3x3[0]}, {{17{det_3x3[1][33]}}, det_3x3[1]}, {{17{det_3x3[2][33]}}, det_3x3[2]}, {{5{det_4x4[45]}}, det_4x4}};
            end
            'd2:begin
                out_data = {{201{det_4x4[45]}}, det_4x4};
            end
            default: out_data = 0;
        endcase
    end       
    else
        out_data = 0;
end
endmodule