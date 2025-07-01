//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Fall
//   Lab01 Exercise		: Snack Shopping Calculator
//   Author     		  : Yu-Hsiang Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SSC.v
//   Module Name : SSC
//   Release version : V1.0 (Release Date: 2024-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SSC(
    // Input signals
    card_num,
    input_money,
    snack_num,
    price, 
    // Output signals
    out_valid,
    out_change
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [63:0] card_num;
input [8:0] input_money;
input [31:0] snack_num;
input [31:0] price;
output out_valid;
output [8:0] out_change;    

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment
wire [3:0] temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8;
wire [6:0] sum;
wire [7:0] weight1, weight2, weight3, weight4, weight5, weight6, weight7, weight8;
wire [7:0] out1, out2, out3, out4, out5, out6, out7, out8;
wire snack_1_check, snack_2_check, snack_3_check, snack_4_check, snack_5_check, snack_6_check, snack_7_check, snack_8_check;
wire [9:0] buy_snack_1, buy_snack_2, buy_snack_3, buy_snack_4, buy_snack_5, buy_snack_6, buy_snack_7, buy_snack_left;
wire [9:0] buy_1_left, buy_2_left, buy_3_left, buy_4_left, buy_5_left, buy_6_left, buy_7_left, buy_8_left;
// reg  [8:0] out_left;
//output------------------------------------------------
reg [8:0] out_change_temp;
reg out_valid_temp;
//================================================================
//    DESIGN
//================================================================
// //321399
    wire [3:0] LUT [0:9];
    assign LUT[0] = 4'd0;
    assign LUT[1] = 4'd2;
    assign LUT[2] = 4'd4;
    assign LUT[3] = 4'd6;
    assign LUT[4] = 4'd8;
    assign LUT[5] = 4'd1;
    assign LUT[6] = 4'd3;
    assign LUT[7] = 4'd5;
    assign LUT[8] = 4'd7;
    assign LUT[9] = 4'd9;
    assign temp1 = LUT[card_num[63:60]];
    assign temp2 = LUT[card_num[55:52]];
    assign temp3 = LUT[card_num[47:44]];
    assign temp4 = LUT[card_num[39:36]];
    assign temp5 = LUT[card_num[31:28]];
    assign temp6 = LUT[card_num[23:20]];
    assign temp7 = LUT[card_num[15:12]];
    assign temp8 = LUT[card_num[7:4]];
//319613
    // assign temp1 = card_num[63:60] > 4 ? (card_num[63:60] << 1) - 4'b1001 : card_num[63:60] << 1;
    // assign temp2 = card_num[55:52] > 4 ? (card_num[55:52] << 1) - 4'b1001 : card_num[55:52] << 1;
    // assign temp3 = card_num[47:44] > 4 ? (card_num[47:44] << 1) - 4'b1001 : card_num[47:44] << 1;
    // assign temp4 = card_num[39:36] > 4 ? (card_num[39:36] << 1) - 4'b1001 : card_num[39:36] << 1;
    // assign temp5 = card_num[31:28] > 4 ? (card_num[31:28] << 1) - 4'b1001 : card_num[31:28] << 1;
    // assign temp6 = card_num[23:20] > 4 ? (card_num[23:20] << 1) - 4'b1001 : card_num[23:20] << 1;
    // assign temp7 = card_num[15:12] > 4 ? (card_num[15:12] << 1) - 4'b1001 : card_num[15:12] << 1;
    // assign temp8 = card_num[7:4]   > 4 ? (card_num[7:4]   << 1) - 4'b1001 : card_num[7:4] << 1;
//--------------------------
// card_number check
//--------------------------
//326154
// LUT LUT1(.in(card_num[63:60]), .out(temp1));
// LUT LUT2(.in(card_num[55:52]), .out(temp2));
// LUT LUT3(.in(card_num[47:44]), .out(temp3));
// LUT LUT4(.in(card_num[39:36]), .out(temp4));
// LUT LUT5(.in(card_num[31:28]), .out(temp5));
// LUT LUT6(.in(card_num[23:20]), .out(temp6));
// LUT LUT7(.in(card_num[15:12]), .out(temp7));
// LUT LUT8(.in(card_num[7:4])  , .out(temp8));
// 56578
// assign sum = (temp2 + temp1) + (temp3 + temp4) + 
//              (temp5 + temp6) + (temp8 + temp7) + 
//              (card_num[3:0] + card_num[11:8])  + 
//              (card_num[19:16] + card_num[27:24]) + 
//              (card_num[35:32] + card_num[43:40]) + 
//              (card_num[51:48] + card_num[59:56]);
// 56688
assign sum = temp1 + temp2 + temp3 + temp4 + temp5 + temp6 + temp7 + temp8 + card_num[3:0] + card_num[11:8]  + card_num[19:16] + card_num[27:24] + card_num[35:32] + card_num[43:40] + card_num[51:48] + card_num[59:56];
//55578
    // assign sum = (temp1 + temp2 + temp3 + temp4) + 
    //              (temp5 + temp6 + temp7 + temp8) + 
    //              (card_num[3:0] + card_num[11:8] + card_num[19:16] + card_num[27:24]) + 
    //              (card_num[35:32] + card_num[43:40] + card_num[51:48] + card_num[59:56]);
    
// assign out_valid = sum%10 == 0;
// always @(*) begin
//     if(sum % 10 == 0)
//         $display("sum = %d", sum);
// end
always @(*) begin
    case (sum)
        10, 50,60,70,80,90,100,110,120 : out_valid_temp = 1'b1;  
        default: out_valid_temp = 1'b0;
    endcase
end
assign out_valid = out_valid_temp;

//--------------------------
// buy snack
//--------------------------
// assign weight1 = snack_num[31:28] * price[31:28];
// assign weight2 = snack_num[27:24] * price[27:24];
// assign weight3 = snack_num[23:20] * price[23:20];
// assign weight4 = snack_num[19:16] * price[19:16];
// assign weight5 = snack_num[15:12] * price[15:12];
// assign weight6 = snack_num[11:8]  * price[11:8];
// assign weight7 = snack_num[7:4]   * price[7:4];
// assign weight8 = snack_num[3:0]   * price[3:0];
mult4 mult1(.in1(snack_num[31:28]), .in2(price[31:28]), .out(weight1));
mult4 mult2(.in1(snack_num[27:24]), .in2(price[27:24]), .out(weight2));
mult4 mult3(.in1(snack_num[23:20]), .in2(price[23:20]), .out(weight3));
mult4 mult4(.in1(snack_num[19:16]), .in2(price[19:16]), .out(weight4));
mult4 mult5(.in2(snack_num[15:12]), .in1(price[15:12]), .out(weight5));
mult4 mult6(.in1(snack_num[11:8] ), .in2(price[11:8] ), .out(weight6));
mult4 mult7(.in1(snack_num[7:4]  ), .in2(price[7:4]  ), .out(weight7));
mult4 mult8(.in1(snack_num[3:0]  ), .in2(price[3:0]  ), .out(weight8));


sorting u_sort(
    .weight1(weight1), .weight2(weight2), .weight3(weight3), .weight4(weight4), .weight5(weight5), .weight6(weight6), .weight7(weight7), .weight8(weight8),
    .out1(out1), .out2(out2), .out3(out3), .out4(out4), .out5(out5), .out6(out6), .out7(out7), .out8(out8)
);

assign snack_1_check = (out1 > input_money) ? 0 : 1;
assign snack_2_check = (out2 > buy_snack_1) ? 0 : snack_1_check;
assign snack_3_check = (out3 > buy_snack_2) ? 0 : snack_2_check;
assign snack_4_check = (out4 > buy_snack_3) ? 0 : snack_3_check;
assign snack_5_check = (out5 > buy_snack_4) ? 0 : snack_4_check;
assign snack_6_check = (out6 > buy_snack_5) ? 0 : snack_5_check;
assign snack_7_check = (out7 > buy_snack_6) ? 0 : snack_6_check;
assign snack_8_check = (out8 > buy_snack_7) ? 0 : snack_7_check;


assign buy_snack_1    = input_money + ~out1 + 1'b1;
// assign buy_snack_1    = input_money - out1;//53704
assign buy_snack_2    = buy_snack_1 + ~out2 + 1'b1;
// assign buy_snack_2    = buy_snack_1 - out2;
assign buy_snack_3    = buy_snack_2 + ~out3 + 1'b1;
assign buy_snack_4    = buy_snack_3 + ~out4 + 1'b1;
assign buy_snack_5    = buy_snack_4 + ~out5 + 1'b1;
assign buy_snack_6    = buy_snack_5 + ~out6 + 1'b1;
assign buy_snack_7    = buy_snack_6 + ~out7 + 1'b1;
// assign buy_snack_7    = buy_snack_6 - out7 ;
// assign buy_snack_left = buy_snack_7 + ~out8 + 1'b1;
assign buy_snack_left = buy_snack_7 - out8 ;//52946

//55168,change to decimal (1+1+1 -> 3)63903
// always @(*) begin
//     if(out_valid)begin
//         if(out1 > input_money)
//             out_change_temp = input_money;
//         else if ( out2 > (input_money + ~out1 + 1'b1))
//             out_change_temp = input_money  + ~out1 + 1'b1;
//         else if ( out3 > (input_money + ~out1 + 1'b1 + ~out2 + 1'b1))
//             out_change_temp = input_money  + ~out1 + 1'b1 + ~out2 + 1'b1;
//         else if ( out4 > (input_money + ~out1 + 1'b1 + ~out2 + 1'b1 + ~out3 + 1'b1))
//             out_change_temp = input_money  + ~out1 + 1'b1 + ~out2 + 1'b1 + ~out3 + 1'b1;
//         else if ( out5 > (input_money + ~out1 + 1'b1 + ~out2 + 1'b1 + ~out3 + 1'b1 + ~out4 + 1'b1))
//             out_change_temp = input_money  + ~out1 + 1'b1 + ~out2 + 1'b1 + ~out3 + 1'b1 + ~out4 + 1'b1;
//         else if ( out6 > (input_money + ~out1 + 1'b1 + ~out2 + 1'b1 + ~out3 + 1'b1 + ~out4 + 1'b1 + ~out5 + 1'b1))
//             out_change_temp = input_money  + ~out1 + 1'b1 + ~out2 + 1'b1 + ~out3 + 1'b1 + ~out4 + 1'b1 + ~out5 + 1'b1;
//         else if ( out7 > (input_money + ~out1 + 1'b1 + ~out2 + 1'b1 + ~out3 + 1'b1 + ~out4 + 1'b1 + ~out5 + 1'b1 + ~out6 + 1'b1))
//             out_change_temp = input_money  + ~out1 + 1'b1 + ~out2 + 1'b1 + ~out3 + 1'b1 + ~out4 + 1'b1 + ~out5 + 1'b1 + ~out6 + 1'b1;
//         else if ( out8 > (input_money + ~out1 + 1'b1 + ~out2 + 1'b1 + ~out3 + 1'b1 + ~out4 + 1'b1 + ~out5 + 1'b1 + ~out6 + 1'b1 + ~out7 + 1'b1))
//             out_change_temp = input_money  + ~out1 + 1'b1 + ~out2 + 1'b1 + ~out3 + 1'b1 + ~out4 + 1'b1 + ~out5 + 1'b1 + ~out6 + 1'b1 + ~out7 + 1'b1;
//         else
//             out_change_temp = input_money  + ~out1 + ~out2 + ~out3 + ~out4 + ~out5 + ~out6 + ~out7 + ~out8 + 1'b1 + 1'b1 + 1'b1 + 1'b1 + 1'b1 + 1'b1 + 1'b1 + 1'b1;
//     end
//     else 
//         out_change_temp = input_money;
// end
// assign out_change = out_change_temp;
//--------------------------------------
// case over ifelse
//--------------------------------------
    always @(*) begin
        if(out_valid) begin
            case (1'b1)
                snack_8_check : out_change_temp = buy_snack_left;
                snack_7_check : out_change_temp = buy_snack_7;
                snack_6_check : out_change_temp = buy_snack_6;
                snack_5_check : out_change_temp = buy_snack_5;
                snack_4_check : out_change_temp = buy_snack_4;
                snack_3_check : out_change_temp = buy_snack_3;
                snack_2_check : out_change_temp = buy_snack_2;
                snack_1_check : out_change_temp = buy_snack_1;
                default : out_change_temp = input_money;  
            endcase
        end
        else
            out_change_temp = input_money;
    end
    assign out_change = out_change_temp;
    // always @(*) begin
    //     if (out_valid)begin
    //         if(snack_8_check) out_change_temp = buy_snack_left; 
    //         else if (snack_7_check) out_change_temp = buy_snack_7;
    //         else if (snack_6_check) out_change_temp = buy_snack_6;
    //         else if (snack_5_check) out_change_temp = buy_snack_5;
    //         else if (snack_4_check) out_change_temp = buy_snack_4;
    //         else if (snack_3_check) out_change_temp = buy_snack_3;
    //         else if (snack_2_check) out_change_temp = buy_snack_2;
    //         else if (snack_1_check) out_change_temp = buy_snack_1;
    //         else out_change_temp = input_money;
    //     end
    //     else out_change_temp = input_money;
    // end
    // assign out_change = out_change_temp;
    // always @(*) begin
    //     if(out_valid)begin
    //         if(snack_8_check)
    //             out_change_temp = buy_snack_left;
    //         else begin
    //             if(snack_7_check)
    //                 out_change_temp = buy_snack_7;
    //             else begin
    //                 if(snack_6_check)
    //                     out_change_temp = buy_snack_6;
    //                 else begin
    //                     if(snack_5_check)
    //                         out_change_temp = buy_snack_5;
    //                     else begin
    //                         if(snack_4_check)
    //                             out_change_temp = buy_snack_4;
    //                         else begin
    //                             if(snack_3_check)
    //                                 out_change_temp = buy_snack_3;
    //                             else begin
    //                                 if(snack_2_check)
    //                                     out_change_temp = buy_snack_2;
    //                                 else begin
    //                                     if(snack_1_check)
    //                                         out_change_temp = buy_snack_1;
    //                                     else
    //                                         out_change_temp = input_money;
    //                                 end        
    //                             end
    //                         end
    //                     end
    //                 end
    //             end
    //         end
    //     end
    //     else
    //         out_change_temp = input_money;
    // end
    // assign out_change = out_change_temp;
    // always @(*) begin
    //     if(out_valid) begin
    //         case ({snack_8_check, snack_7_check, snack_6_check, snack_5_check, snack_4_check, snack_3_check, snack_2_check, snack_1_check})
    //             8'b11111111: out_change = buy_snack_left;
    //             8'b01111111: out_change = buy_snack_7;
    //             8'b00111111: out_change = buy_snack_6;
    //             8'b00011111: out_change = buy_snack_5;
    //             8'b00001111: out_change = buy_snack_4;
    //             8'b00000111: out_change = buy_snack_3;
    //             8'b00000011: out_change = buy_snack_2;
    //             8'b00000001: out_change = buy_snack_1;
    //             default: out_change = input_money; 
    //         endcase
    //     end
    //     else
    //         out_change = input_money;
    // end
endmodule
//326154
// module LUT (
//     in,out
// );
//     input [3:0] in;
//     output reg[3:0] out;

//     always @(*) begin
//         case(in)
//             4'd0: out = 4'd0;
//             4'd1: out = 4'd2;
//             4'd2: out = 4'd4;
//             4'd3: out = 4'd6;
//             4'd4: out = 4'd8;
//             4'd5: out = 4'd1;
//             4'd6: out = 4'd3;
//             4'd7: out = 4'd5;
//             4'd8: out = 4'd7;
//             4'd9: out = 4'd9;
//             default : out = 4'd0;
//         endcase
//     end
// endmodule

module mult4(
    in1, in2, out
);
    input [3:0] in1, in2;
    output [7:0] out;

    wire [3:0] a,b,c,d;
    assign a = in2[0] ? in1 : 0;
    assign b = in2[1] ? in1 : 0;
    assign c = in2[2] ? in1 : 0;
    assign d = in2[3] ? in1 : 0;

    assign out = ((d << 3) + (c << 2)) + ((b << 1) + a) ;
endmodule

module sorting (
    weight1, weight2, weight3, weight4, weight5, weight6, weight7, weight8,
    out1, out2, out3, out4, out5, out6, out7, out8
);
    input [7:0] weight1, weight2, weight3, weight4, weight5, weight6, weight7, weight8;
    output [7:0] out1, out2, out3, out4, out5, out6, out7, out8;

    wire [7:0] a[0:7], b[0:7], c[0:7], d[0:7], e[0:7], f[0:7];
// //sorting_1_52946
//     assign a[0] = ( weight1 > weight2 ) ? weight1 : weight2;
//     assign a[1] = ( weight1 > weight2 ) ? weight2 : weight1;
//     assign a[2] = ( weight3 > weight4 ) ? weight3 : weight4;
//     assign a[3] = ( weight3 > weight4 ) ? weight4 : weight3;
//     assign a[4] = ( weight5 > weight6 ) ? weight5 : weight6;
//     assign a[5] = ( weight5 > weight6 ) ? weight6 : weight5;
//     assign a[6] = ( weight7 > weight8 ) ? weight7 : weight8;
//     assign a[7] = ( weight7 > weight8 ) ? weight8 : weight7;

//     assign b[0] = ( a[2] > a[0] ) ? a[2] : a[0];
//     assign b[2] = ( a[2] > a[0] ) ? a[0] : a[2];
//     assign b[1] = ( a[3] > a[1] ) ? a[3] : a[1];
//     assign b[3] = ( a[3] > a[1] ) ? a[1] : a[3];
//     assign b[4] = ( a[6] > a[4] ) ? a[6] : a[4];
//     assign b[6] = ( a[6] > a[4] ) ? a[4] : a[6];
//     assign b[5] = ( a[7] > a[5] ) ? a[7] : a[5];
//     assign b[7] = ( a[7] > a[5] ) ? a[5] : a[7];

//     assign c[0] = b[0];
//     assign c[1] = ( b[1] > b[2] ) ? b[1] : b[2];
//     assign c[2] = ( b[1] > b[2] ) ? b[2] : b[1];
//     assign c[3] = b[3];
//     assign c[4] = b[4];
//     assign c[5] = ( b[5] > b[6] ) ? b[5] : b[6];
//     assign c[6] = ( b[5] > b[6] ) ? b[6] : b[5];
//     assign c[7] = b[7];

//     assign d[0] = ( c[0] > c[4] ) ? c[0] : c[4];
//     assign d[4] = ( c[0] > c[4] ) ? c[4] : c[0];
//     assign d[1] = ( c[1] > c[5] ) ? c[1] : c[5];
//     assign d[5] = ( c[1] > c[5] ) ? c[5] : c[1];
//     assign d[2] = ( c[2] > c[6] ) ? c[2] : c[6];
//     assign d[6] = ( c[2] > c[6] ) ? c[6] : c[2];
//     assign d[3] = ( c[3] > c[7] ) ? c[3] : c[7];
//     assign d[7] = ( c[3] > c[7] ) ? c[7] : c[3];

//     assign out1 = d[0];
//     assign out2 = ( d[1] > d[4] ) ? d[1] : d[4];
//     assign e[0] = ( d[1] > d[4] ) ? d[4] : d[1];
//     assign out3 = ( d[2] > e[0] ) ? d[2] : e[0];
//     assign e[4] = ( d[2] > e[0] ) ? e[0] : d[2];
//     assign e[1] = ( d[3] > d[6] ) ? d[3] : d[6];
//     assign e[2] = ( d[3] > d[6] ) ? d[6] : d[3];
//     assign e[3] = ( e[1] > d[5] ) ? e[1] : d[5];
//     assign out6 = ( e[1] > d[5] ) ? d[5] : e[1];
//     assign out4 = ( e[3] > e[4] ) ? e[3] : e[4];
//     assign out5 = ( e[3] > e[4] ) ? e[4] : e[3];
//     assign out7 = e[2];
//     assign out8 = d[7];
// //sorting_2_51030
//     assign a[0] = weight1 > weight3 ? weight1 : weight3;
//     assign a[2] = weight1 > weight3 ? weight3 : weight1;
//     assign a[1] = weight2 > weight4 ? weight2 : weight4;
//     assign a[3] = weight2 > weight4 ? weight4 : weight2;
//     assign a[4] = weight5 > weight7 ? weight5 : weight7;
//     assign a[6] = weight5 > weight7 ? weight7 : weight5;
//     assign a[5] = weight6 > weight8 ? weight6 : weight8;
//     assign a[7] = weight6 > weight8 ? weight8 : weight6;

//     assign b[0] = a[0] > a[4] ? a[0] : a[4];
//     assign b[4] = a[0] > a[4] ? a[4] : a[0];
//     assign b[1] = a[5] > a[1] ? a[5] : a[1];
//     assign b[5] = a[5] > a[1] ? a[1] : a[5];
//     assign b[2] = a[6] > a[2] ? a[6] : a[2];
//     assign b[6] = a[6] > a[2] ? a[2] : a[6];
//     assign b[3] = a[3] > a[7] ? a[3] : a[7];
//     assign b[7] = a[3] > a[7] ? a[7] : a[3];

//     assign c[0] = b[0] > b[1] ? b[0] : b[1];
//     assign c[1] = b[0] > b[1] ? b[1] : b[0];
//     assign c[2] = b[2] > b[3] ? b[2] : b[3];
//     assign c[3] = b[2] > b[3] ? b[3] : b[2];
//     assign c[4] = b[5] > b[4] ? b[5] : b[4];
//     assign c[5] = b[5] > b[4] ? b[4] : b[5];
//     assign c[6] = b[6] > b[7] ? b[6] : b[7];
//     assign c[7] = b[6] > b[7] ? b[7] : b[6];

//     assign d[0] = c[0];
//     assign d[1] = c[1];
//     assign d[2] = c[2] > c[4] ? c[2] : c[4];
//     assign d[4] = c[2] > c[4] ? c[4] : c[2];
//     assign d[3] = c[3] > c[5] ? c[3] : c[5];
//     assign d[5] = c[3] > c[5] ? c[5] : c[3];
//     assign d[6] = c[6];
//     assign d[7] = c[7];

//     assign e[0] = d[0];
//     assign e[1] = d[1] > d[4] ? d[1] : d[4];
//     assign e[4] = d[1] > d[4] ? d[4] : d[1];
//     assign e[2] = d[2];
//     assign e[3] = d[6] > d[3] ? d[6] : d[3];
//     assign e[6] = d[6] > d[3] ? d[3] : d[6];
//     assign e[5] = d[5];
//     assign e[7] = d[7];

//     assign f[0] = e[0];
//     assign f[1] = e[2] > e[1] ? e[2] : e[1];
//     assign f[2] = e[2] > e[1] ? e[1] : e[2];
//     assign f[3] = e[3] > e[4] ? e[3] : e[4];
//     assign f[4] = e[3] > e[4] ? e[4] : e[3];
//     assign f[5] = e[5] > e[6] ? e[5] : e[6];
//     assign f[6] = e[5] > e[6] ? e[6] : e[5];
//     assign f[7] = e[7];

//     assign out1 = f[0];
//     assign out2 = f[1];
//     assign out3 = f[2];
//     assign out4 = f[3];
//     assign out5 = f[4];
//     assign out6 = f[5];
//     assign out7 = f[6];
//     assign out8 = f[7];
//sorting_wolfram_50913
            assign a[0] = weight1 > weight5 ? weight1 : weight5;
            assign a[4] = weight1 > weight5 ? weight5 : weight1;
            assign a[1] = weight2 > weight6 ? weight2 : weight6;
            assign a[5] = weight2 > weight6 ? weight6 : weight2;
            assign a[2] = weight3 > weight7 ? weight3 : weight7;
            assign a[6] = weight3 > weight7 ? weight7 : weight3;
            assign a[3] = weight4 > weight8 ? weight4 : weight8;
            assign a[7] = weight4 > weight8 ? weight8 : weight4;
    
            assign b[0] = a[2] > a[0] ? a[2] : a[0];
            assign b[2] = a[2] > a[0] ? a[0] : a[2];
            assign b[1] = a[1] > a[3] ? a[1] : a[3];
            assign b[3] = a[1] > a[3] ? a[3] : a[1];
            assign b[4] = a[4] > a[6] ? a[4] : a[6];
            assign b[6] = a[4] > a[6] ? a[6] : a[4];
            assign b[5] = a[7] > a[5] ? a[7] : a[5];
            assign b[7] = a[7] > a[5] ? a[5] : a[7];

            assign c[0] = b[0];
            assign c[1] = b[1];
            assign c[2] = b[4] > b[2] ? b[4] : b[2];
            assign c[4] = b[4] > b[2] ? b[2] : b[4];
            assign c[3] = b[3] > b[5] ? b[3] : b[5];
            assign c[5] = b[3] > b[5] ? b[5] : b[3];
            assign c[6] = b[6];
            assign c[7] = b[7];

            assign d[0] = c[0] > c[1] ? c[0] : c[1];
            assign d[1] = c[0] > c[1] ? c[1] : c[0];
            assign d[2] = c[2] > c[3] ? c[2] : c[3];
            assign d[3] = c[2] > c[3] ? c[3] : c[2];
            assign d[4] = c[4] > c[5] ? c[4] : c[5];
            assign d[5] = c[4] > c[5] ? c[5] : c[4];
            assign d[6] = c[6] > c[7] ? c[6] : c[7];
            assign d[7] = c[6] > c[7] ? c[7] : c[6];

            assign e[0] = d[0];
            assign e[1] = d[1] > d[4] ? d[1] : d[4];
            assign e[4] = d[1] > d[4] ? d[4] : d[1];
            assign e[2] = d[2];
            assign e[3] = d[3] > d[6] ? d[3] : d[6];
            assign e[6] = d[3] > d[6] ? d[6] : d[3];
            assign e[5] = d[5];
            assign e[7] = d[7];

            assign f[0] = e[0];
            assign f[1] = e[1] > e[2] ? e[1] : e[2];
            assign f[2] = e[1] > e[2] ? e[2] : e[1];
            assign f[3] = e[3] > e[4] ? e[3] : e[4];
            assign f[4] = e[3] > e[4] ? e[4] : e[3];
            assign f[5] = e[6] > e[5] ? e[6] : e[5];
            assign f[6] = e[6] > e[5] ? e[5] : e[6];
            assign f[7] = e[7];

            assign out1 = f[0];
            assign out2 = f[1];
            assign out3 = f[2];
            assign out4 = f[3];
            assign out5 = f[4];
            assign out6 = f[5];
            assign out7 = f[6];
            assign out8 = f[7];
endmodule