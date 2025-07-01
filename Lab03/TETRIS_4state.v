/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: TETRIS
// FILE NAME: TETRIS.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / TETRIS
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module TETRIS (
	//INPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//OUTPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[2:0]	tetrominoes;
input		[2:0]	position;
output reg			tetris_valid, score_valid, fail;
output reg	[3:0]	score;
output reg 	[71:0]	tetris;


//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
parameter  NEXT_ROUND = 'd0,CALC = 'd1, OUT = 'd2, IDLE = 'd3;
integer i, j;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [1:0] cs, ns;
reg [5:0] tetris_map[13:0];
reg [5:0] tetris_map_ns[13:0];
reg [3:0] flag[0:5];
reg fail_temp;
reg [3:0] erase_row;
// wire erase_row;
reg row_0, row_1, row_2, row_3, row_4, row_5, row_6, row_7, row_8, row_9, row_10, row_11;
//---------------------------------------------------------------------
//   COUNTER ba rst_n(26584 -> 27213)
//---------------------------------------------------------------------
reg [3:0] count,count_ns;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) count <= 'd0;
    else if(tetris_valid) count <= 'd0;
    else if(in_valid) count <= count + 1;
end
// always @(posedge clk) begin
//     // if(~rst_n) count <= 'd0;
//     count <= count_ns;
// end
// always @(*) begin
//     // if(~rst_n) count_ns = 'd0;
//     if(cs == NEXT_ROUND || tetris_valid) count_ns = 'd0;
//     else if(in_valid) count_ns = count + 1;
//     else count_ns = count;
// end
//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) cs <= NEXT_ROUND;
    else cs <= ns;
    // $display("cs = %d, ns = %d", cs, ns);
end
always @(*) begin
    case (cs)
        NEXT_ROUND: ns = in_valid      ? CALC : NEXT_ROUND;
        // CALC      : ns = erase_row==12 ? OUT : CALC;
        CALC      : ns = erase_row[3]&&erase_row[2] ? OUT : CALC;
        // OUT       : ns = in_valid      ? CALC : (tetris_valid  ? NEXT_ROUND : IDLE);
        OUT       : ns = in_valid      ? CALC : IDLE;
        IDLE      : ns = in_valid      ? CALC : IDLE; 
        default   : ns = IDLE;
    endcase
end
//---------------------------------------------------------------------
//   Flag (seq -> comb)
//---------------------------------------------------------------------
always @(*) begin
    for(i = 0; i < 6; i = i + 1)begin
        if(tetris_map[11][i] == 1)
            flag[i] = 12;
        else if(tetris_map[10][i] == 1)
            flag[i] = 11;
        else if(tetris_map[9][i] == 1)
            flag[i] = 10;
        else if(tetris_map[8][i] == 1)
            flag[i] = 9;
        else if(tetris_map[7][i] == 1)
            flag[i] = 8;
        else if(tetris_map[6][i] == 1)
            flag[i] = 7;
        else if(tetris_map[5][i] == 1)
            flag[i] = 6;
        else if(tetris_map[4][i] == 1)
            flag[i] = 5;
        else if(tetris_map[3][i] == 1)
            flag[i] = 4;
        else if(tetris_map[2][i] == 1)
            flag[i] = 3;
        else if(tetris_map[1][i] == 1)
            flag[i] = 2;
        else if(tetris_map[0][i] == 1)
            flag[i] = 1;
        else
            flag[i] = 0;
    end
end
//---------------------------------------------------------------------
//   Compare 4 -> Compare 3 does not work(26993 -> 32651)
//---------------------------------------------------------------------
reg [3:0] cmp_in1, cmp_in2, cmp_in3,cmp_in4, cmp_out;
// reg [3:0] cmp_out_for_I;
cmp_4 u_cmp_4(
    .in1(cmp_in1),
    .in2(cmp_in2),
    .in3(cmp_in3),
    .in4(cmp_in4),
    .out(cmp_out)
);
always @(*) begin
    case (tetrominoes)
        'd0:begin
            cmp_in1 = flag[position    ];
            cmp_in2 = flag[position + 1];
            cmp_in3 = 'd0;
            cmp_in4 = 'd0;
        end 
        'd1:begin
            cmp_in1 = flag[position];
            cmp_in2 = 'd0;
            cmp_in3 = 'd0;
            cmp_in4 = 'd0;
        end
        'd2:begin
            cmp_in1 = flag[position    ];
            cmp_in2 = flag[position + 1];
            cmp_in3 = flag[position + 2];
            cmp_in4 = flag[position + 3];
        end
        'd3:begin
            cmp_in1 = flag[position    ]    ;
            cmp_in2 = flag[position + 1] + 2;
            cmp_in3 = 'd0;
            cmp_in4 = 'd0;
        end
        'd4:begin//+ 1
            cmp_in1 = flag[position    ] + 1;
            cmp_in2 = flag[position + 1]    ;
            cmp_in3 = flag[position + 2]    ;
            cmp_in4 = 'd0;
        end
        'd5:begin
            cmp_in1 = flag[position    ];
            cmp_in2 = flag[position + 1];
            cmp_in3 = 'd0;
            cmp_in4 = 'd0;
        end
        'd6:begin
            cmp_in1 = flag[position    ]    ;
            cmp_in2 = flag[position + 1] + 1;
            cmp_in3 = 'd0;
            cmp_in4 = 'd0;
        end
        'd7:begin//+ 1
            cmp_in1 = flag[position    ] + 1;
            cmp_in2 = flag[position + 1] + 1;
            cmp_in3 = flag[position + 2]    ;
            cmp_in4 = 'd0;
        end
        default: begin
            cmp_in1 = 'd0    ;
            cmp_in2 = 'd0    ;
            cmp_in3 = 'd0    ;
            cmp_in4 = 'd0    ;
        end
    endcase
end
// always @(*) begin
//     cmp_out_for_I = cmp_out > flag[position + 3] ? cmp_out : flag[position + 3];
// end
//---------------------------------------------------------------------
//   Tetris Map
//---------------------------------------------------------------------
always @(posedge clk) begin
    for(i = 0; i < 14; i = i + 1)begin
        tetris_map[i] <= tetris_map_ns[i];
    end
end
always @(*) begin
    for(i = 0; i < 14; i = i + 1)begin
        tetris_map_ns[i] = tetris_map[i];
    end
    if(tetris_valid || ns == NEXT_ROUND)begin
        for(i = 0; i < 14; i = i + 1)begin
            tetris_map_ns[i] = 0;
        end
    end
    else if(in_valid)begin
    //---------------------------------------------------------------------
    //   Row,Column Selector fail... 26993 -> 33310
    //---------------------------------------------------------------------
    // if(ns == CALC)begin
        case (tetrominoes)
            'd0:begin
                tetris_map_ns[cmp_out       ][position    ] = 1;
                tetris_map_ns[cmp_out       ][position + 1] = 1;
                tetris_map_ns[cmp_out + 4'd1][position    ] = 1;//1 -> 4'd1
                tetris_map_ns[cmp_out + 4'd1][position + 1] = 1;
            end 
            'd1:begin
                tetris_map_ns[cmp_out       ][position] = 1;
                tetris_map_ns[cmp_out + 4'd1][position] = 1;
                tetris_map_ns[cmp_out + 2   ][position] = 1;//2 -> 2'd2 does not work
                tetris_map_ns[cmp_out + 3   ][position] = 1;//3 -> 4'd3 ,2'b11 does not work
            end
            'd2:begin
                tetris_map_ns[cmp_out    ][position    ] = 1;
                tetris_map_ns[cmp_out    ][position + 1] = 1;
                tetris_map_ns[cmp_out    ][position + 2] = 1;
                tetris_map_ns[cmp_out    ][position + 3] = 1;
                // tetris_map[cmp_out_for_I ][position    ] <= 1;
                // tetris_map[cmp_out_for_I ][position + 1] <= 1;
                // tetris_map[cmp_out_for_I ][position + 2] <= 1;
                // tetris_map[cmp_out_for_I ][position + 3] <= 1;
            end
            'd3:begin
                tetris_map_ns[cmp_out        ][position    ] = 1;
                tetris_map_ns[cmp_out        ][position + 1] = 1;
                tetris_map_ns[cmp_out + 4'd15][position + 1] = 1;
                tetris_map_ns[cmp_out + 4'd14][position + 1] = 1;
            end
            'd4:begin//-1
                tetris_map_ns[cmp_out + 4'd15][position    ] = 1;
                tetris_map_ns[cmp_out        ][position    ] = 1;
                tetris_map_ns[cmp_out        ][position + 1] = 1;
                tetris_map_ns[cmp_out        ][position + 2] = 1;
            end
            'd5:begin
                tetris_map_ns[cmp_out       ][position    ] = 1;
                tetris_map_ns[cmp_out       ][position + 1] = 1;
                tetris_map_ns[cmp_out + 4'd1][position    ] = 1;
                tetris_map_ns[cmp_out + 2   ][position    ] = 1;
            end
            'd6:begin
                tetris_map_ns[cmp_out        ][position    ] = 1;
                tetris_map_ns[cmp_out        ][position + 1] = 1;
                tetris_map_ns[cmp_out + 4'd1 ][position    ] = 1;
                tetris_map_ns[cmp_out + 4'd15][position + 1] = 1;
            end
            'd7:begin//-1
                tetris_map_ns[cmp_out + 4'd15][position    ] = 1;
                tetris_map_ns[cmp_out + 4'd15][position + 1] = 1;
                tetris_map_ns[cmp_out        ][position + 1] = 1;
                tetris_map_ns[cmp_out        ][position + 2] = 1;
            end
        endcase
    end
    //---------------------------------------------------------------------
    //   Erase Row (if-else:27386  case:26993,cycle time:7.5ns)
    //---------------------------------------------------------------------
    else if(ns == CALC)begin
        case (erase_row)
        // case (1'b1)
            'd0:begin
                for(i = 0; i < 13; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i + 1];
                end
                tetris_map_ns[13] = 0;
            end 
            'd1:begin
                for(i = 1; i < 13; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i + 1];
                end
                tetris_map_ns[13] = 0;
                tetris_map_ns[0] = tetris_map[0];
            end
            'd2:begin
                for(i = 2; i < 13; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i + 1];
                end
                tetris_map_ns[13] = 0;
                for(i = 0; i < 2; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i];
                end
            end
            'd3:begin
                for(i = 3; i < 13; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i + 1];
                end
                tetris_map_ns[13] = 0;
                for(i = 0; i < 3; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i];
                end
            end
            'd4:begin
                for(i = 4; i < 13; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i + 1];
                end
                tetris_map_ns[13] = 0;
                for(i = 0; i < 4; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i];
                end
            end
            'd5:begin
                for(i = 5; i < 13; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i + 1];
                end
                tetris_map_ns[13] = 0;
            end
            'd6:begin
                for(i = 6; i < 13; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i + 1];
                end
                tetris_map_ns[13] = 0;
                for(i = 0; i < 6; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i];
                end
            end
            'd7:begin
                for(i = 7; i < 13; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i + 1];
                end
                tetris_map_ns[13] = 0;
                for(i = 0; i < 7; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i];
                end
            end
            'd8:begin
                for(i = 8; i < 13; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i + 1];
                end
                tetris_map_ns[13] = 0;
                for(i = 0; i < 8; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i];
                end
            end
            'd9:begin
                for(i = 9; i < 13; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i + 1];
                end
                tetris_map_ns[13] = 0;
                for(i = 0; i < 9; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i];
                end
            end
            'd10:begin
                for(i = 10; i < 13; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i + 1];
                end
                tetris_map_ns[13] = 0;
                for(i = 0; i < 10; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i];
                end
            end
            'd11:begin
                for(i = 11; i < 13; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i + 1];
                end
                tetris_map_ns[13] = 0;
                for(i = 0; i < 11; i = i + 1)begin
                    tetris_map_ns[i] = tetris_map[i];
                end
            end
        endcase
    end
end
//---------------------------------------------------------------------
//  Row assign same as always @(*)
//---------------------------------------------------------------------
always @(*) begin
    row_0  = &tetris_map[0];
    row_1  = &tetris_map[1];
    row_2  = &tetris_map[2];
    row_3  = &tetris_map[3];
    row_4  = &tetris_map[4];
    row_5  = &tetris_map[5];
    row_6  = &tetris_map[6];
    row_7  = &tetris_map[7];
    row_8  = &tetris_map[8];
    row_9  = &tetris_map[9];
    row_10 = &tetris_map[10];
    row_11 = &tetris_map[11];
end
//---------------------------------------------------------------------
//  Erase_row (if-else equivalent to case)
//  change to 1bit 26993 -> 29332
//---------------------------------------------------------------------
// assign erase_row = row_0 | row_1 | row_2 | row_3 | row_4 | row_5 | row_6 | row_7 | row_8 | row_9 | row_10 | row_11;
always @(*) begin
    if(row_0)erase_row = 0;
    else if(row_1)erase_row = 1;
    else if(row_2)erase_row = 2;
    else if(row_3)erase_row = 3;
    else if(row_4)erase_row = 4;
    else if(row_5)erase_row = 5;
    else if(row_6)erase_row = 6;
    else if(row_7)erase_row = 7;
    else if(row_8)erase_row = 8;
    else if(row_9)erase_row = 9;
    else if(row_10)erase_row = 10;
    else if(row_11)erase_row = 11;
    else erase_row = 12;
end
// always @(*) begin
//     case (1'b1)
//         row_0 : erase_row = 0;
//         row_1 : erase_row = 1;
//         row_2 : erase_row = 2;
//         row_3 : erase_row = 3;
//         row_4 : erase_row = 4;
//         row_5 : erase_row = 5;
//         row_6 : erase_row = 6;
//         row_7 : erase_row = 7;
//         row_8 : erase_row = 8;
//         row_9 : erase_row = 9;
//         row_10: erase_row = 10;
//         row_11: erase_row = 11;
//         default: erase_row = 12;
//     endcase
// end
//---------------------------------------------------------------------
//  Score_temp ba rst_n(26584 -> 26604)
//---------------------------------------------------------------------
reg [2:0] score_temp,score_temp_ns;
// always @(posedge clk or negedge rst_n) begin
//     if(~rst_n) score_temp <= 'd0;
//     else if(cs == NEXT_ROUND || tetris_valid) score_temp <= 'd0;
//     else if(cs == CALC && ns == CALC) score_temp <= score_temp + 1;
//     else score_temp <= score_temp;
// end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) score_temp <= 'd0;
    else score_temp <= score_temp_ns;
end
always @(*) begin
    // if(~rst_n) score_temp_ns = 'd0;
    if(tetris_valid) score_temp_ns = 'd0;
    else if(cs == CALC && ns == CALC) score_temp_ns = score_temp + 1;
    // else if(erase_row!=12) score_temp_ns = score_temp + 1;//SPEC-7 fail
    else score_temp_ns = score_temp;
end
//---------------------------------------------------------------------
//  Fail_temp
//---------------------------------------------------------------------
always @(*) begin
    if(tetris_map[12]) 
        fail_temp = 1;
    else
        fail_temp = 0;
end
//---------------------------------------------------------------------
//  Output
//---------------------------------------------------------------------
always @(*) begin
    if(ns == OUT)
        score_valid = 1;
    else
        score_valid = 0;
end
always @(*) begin
    if(ns == OUT)
        score = score_temp;
    else
        score = 0;
end
always @(*) begin
    if(ns == OUT)
        fail = fail_temp;
    else
        fail = 0;
end
always @(*) begin
    // if((ns == OUT && count == 'd0) || (ns == OUT && fail_temp == 1))// same as below
    if( (ns == OUT) && (count == 'd0 || fail_temp == 1) )
        tetris_valid = 1;
    else
        tetris_valid = 0;
end
always @(*) begin
    if(tetris_valid)begin
    // if((ns == OUT && count == 'd0) || (ns == OUT && fail_temp == 1))begin // same as above
        tetris = {tetris_map[11],tetris_map[10],tetris_map[9],tetris_map[8],tetris_map[7],tetris_map[6],tetris_map[5],tetris_map[4],tetris_map[3],tetris_map[2],tetris_map[1],tetris_map[0]};
    end
    else
        tetris = 0;
end
endmodule
module cmp_4 (
    in1,in2,in3,in4,
    out
);
    input  [3:0] in1,in2,in3,in4;
    output [3:0] out;

    wire [3:0] a0,a1;
    assign a0 = in1 > in3 ? in1 : in3;
    assign a1 = in2 > in4 ? in2 : in4;
    // assign a1 = in1 > in3 ? in3 : in1;
    // assign out = a0 > in3 ? a0 : in3;
    assign out = a0 > a1 ? a0 : a1;
endmodule