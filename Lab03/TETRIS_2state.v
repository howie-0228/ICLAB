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
// parameter  NEXT_ROUND = 'd0,CALC = 'd1, OUT = 'd2, IDLE = 'd3;
parameter  IDLE = 'd0, CALC = 'd1;
integer i, j;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg cs, ns;
reg [5:0] tetris_map[14:0];
reg [3:0] flag[0:5];
reg row_0, row_1, row_2, row_3, row_4, row_5, row_6, row_7, row_8, row_9, row_10, row_11;
reg [3:0] erase_row;
reg [3:0] score_temp;
reg fail_temp;
//---------------------------------------------------------------------
//   COUNTER
//---------------------------------------------------------------------
reg [3:0] count;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) count <= 'd0;
    else if(tetris_valid) count <= 'd0;
    else if(in_valid) count <= count + 1;
end

//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) cs <= IDLE;
    else cs <= ns;
    // $display("cs = %d, ns = %d", cs, ns);
end
always @(*) begin
    case (cs)
        IDLE      : ns = in_valid ? CALC : IDLE;
        CALC      : ns = erase_row == 12 ? IDLE : CALC;
        default   : ns = IDLE;
    endcase
end
//---------------------------------------------------------------------
//   Flag
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        for(i = 0; i < 6; i = i + 1)begin
            flag[i] <= 0;
        end
    end
    else if (tetris_valid)begin
        for(i = 0; i < 6; i = i + 1)begin
            flag[i] <= 0;
        end
    end
    else begin
        for(i = 0; i < 6; i = i + 1)begin
            if(tetris_map[11][i] == 1)
                flag[i] <= 12;
            else if(tetris_map[10][i] == 1)
                flag[i] <= 11;
            else if(tetris_map[9][i] == 1)
                flag[i] <= 10;
            else if(tetris_map[8][i] == 1)
                flag[i] <= 9;
            else if(tetris_map[7][i] == 1)
                flag[i] <= 8;
            else if(tetris_map[6][i] == 1)
                flag[i] <= 7;
            else if(tetris_map[5][i] == 1)
                flag[i] <= 6;
            else if(tetris_map[4][i] == 1)
                flag[i] <= 5;
            else if(tetris_map[3][i] == 1)
                flag[i] <= 4;
            else if(tetris_map[2][i] == 1)
                flag[i] <= 3;
            else if(tetris_map[1][i] == 1)
                flag[i] <= 2;
            else if(tetris_map[0][i] == 1)
                flag[i] <= 1;
            else
                flag[i] <= 0;
        end
    end
end
reg [3:0] cmp_in1, cmp_in2, cmp_in3, cmp_in4, cmp_out;
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
//---------------------------------------------------------------------
//   Tetris Map
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        for(i = 0; i < 15; i = i + 1)begin
            tetris_map[i] <= 0;
        end
    end
    else if(tetris_valid)begin
        for(i = 0; i < 15; i = i + 1)begin
            tetris_map[i] <= 0;
        end
    end
    else if(in_valid)begin
        case (tetrominoes)
            'd0:begin
                tetris_map[cmp_out    ][position    ] <= 1;
                tetris_map[cmp_out    ][position + 1] <= 1;
                tetris_map[cmp_out + 1][position    ] <= 1;
                tetris_map[cmp_out + 1][position + 1] <= 1;
            end 
            'd1:begin
                tetris_map[cmp_out    ][position] <= 1;
                tetris_map[cmp_out + 1][position] <= 1;
                tetris_map[cmp_out + 2][position] <= 1;
                tetris_map[cmp_out + 3][position] <= 1;
            end
            'd2:begin
                tetris_map[cmp_out    ][position    ] <= 1;
                tetris_map[cmp_out    ][position + 1] <= 1;
                tetris_map[cmp_out    ][position + 2] <= 1;
                tetris_map[cmp_out    ][position + 3] <= 1;
            end
            'd3:begin
                tetris_map[cmp_out    ][position    ] <= 1;
                tetris_map[cmp_out    ][position + 1] <= 1;
                tetris_map[cmp_out - 1][position + 1] <= 1;
                tetris_map[cmp_out - 2][position + 1] <= 1;
            end
            'd4:begin//-1
                tetris_map[cmp_out - 1][position    ] <= 1;
                tetris_map[cmp_out    ][position    ] <= 1;
                tetris_map[cmp_out    ][position + 1] <= 1;
                tetris_map[cmp_out    ][position + 2] <= 1;
            end
            'd5:begin
                tetris_map[cmp_out    ][position    ] <= 1;
                tetris_map[cmp_out    ][position + 1] <= 1;
                tetris_map[cmp_out + 1][position    ] <= 1;
                tetris_map[cmp_out + 2][position    ] <= 1;
            end
            'd6:begin
                tetris_map[cmp_out    ][position    ] <= 1;
                tetris_map[cmp_out    ][position + 1] <= 1;
                tetris_map[cmp_out + 1][position    ] <= 1;
                tetris_map[cmp_out - 1][position + 1] <= 1;
            end
            'd7:begin//-1
                tetris_map[cmp_out - 1][position    ] <= 1;
                tetris_map[cmp_out - 1][position + 1] <= 1;
                tetris_map[cmp_out    ][position + 1] <= 1;
                tetris_map[cmp_out    ][position + 2] <= 1;
            end
        endcase
    end
    else if(cs == CALC)begin
        case (erase_row)
            'd0:begin
                for(i = 0; i < 14; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i + 1];
                end
                tetris_map[14] <= 0;
            end 
            'd1:begin
                for(i = 1; i < 14; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i + 1];
                end
                tetris_map[14] <= 0;
                tetris_map[0] <= tetris_map[0];
            end
            'd2:begin
                for(i = 2; i < 14; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i + 1];
                end
                tetris_map[14] <= 0;
                for(i = 0; i < 2; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i];
                end
            end
            'd3:begin
                for(i = 3; i < 14; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i + 1];
                end
                tetris_map[14] <= 0;
                for(i = 0; i < 3; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i];
                end
            end
            'd4:begin
                for(i = 4; i < 14; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i + 1];
                end
                tetris_map[14] <= 0;
                for(i = 0; i < 4; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i];
                end
            end
            'd5:begin
                for(i = 5; i < 14; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i + 1];
                end
                tetris_map[14] <= 0;
                for(i = 0; i < 5; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i];
                end
            end
            'd6:begin
                for(i = 6; i < 14; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i + 1];
                end
                tetris_map[14] <= 0;
                for(i = 0; i < 6; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i];
                end
            end
            'd7:begin
                for(i = 7; i < 14; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i + 1];
                end
                tetris_map[14] <= 0;
                for(i = 0; i < 7; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i];
                end
            end
            'd8:begin
                for(i = 8; i < 14; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i + 1];
                end
                tetris_map[14] <= 0;
                for(i = 0; i < 8; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i];
                end
            end
            'd9:begin
                for(i = 9; i < 14; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i + 1];
                end
                tetris_map[14] <= 0;
                for(i = 0; i < 9; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i];
                end
            end
            'd10:begin
                for(i = 10; i < 14; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i + 1];
                end
                tetris_map[14] <= 0;
                for(i = 0; i < 10; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i];
                end
            end
            'd11:begin
                for(i = 11; i < 14; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i + 1];
                end
                tetris_map[14] <= 0;
                for(i = 0; i < 11; i = i + 1)begin
                    tetris_map[i] <= tetris_map[i];
                end
            end
        endcase
    end
end
//---------------------------------------------------------------------
//  Row
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
//  Erase_row
//---------------------------------------------------------------------
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
//---------------------------------------------------------------------
//  Score_temp
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) score_temp <= 'd0;
    else if(tetris_valid) score_temp <= 'd0;
    else if(cs == CALC && ns == CALC) score_temp <= score_temp + 1;
    else score_temp <= score_temp;
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
    if(cs == CALC && ns == IDLE)
        score_valid = 1;
    else
        score_valid = 0;
end
always @(*) begin
    if(cs == CALC && ns == IDLE)
        score = score_temp;
    else
        score = 0;
end
always @(*) begin
    if(cs == CALC && ns == IDLE)
        fail = fail_temp;
    else
        fail = 0;
end
always @(*) begin
    if((cs == CALC && ns == IDLE && count == 'd0) || (cs == CALC && ns == IDLE && fail_temp == 1))
        tetris_valid = 1;
    else
        tetris_valid = 0;
end
always @(*) begin
    if(tetris_valid)begin
    // if((ns == OUT && count == 'd0) || (ns == OUT && fail_temp == 1))begin
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
    // assign a1 = in1 > in3 ? in3 : in1;
    assign a1 = in2 > in4 ? in2 : in4;
    // assign a3 = in2 > in4 ? in4 : in2;

    assign out = a0 > a1 ? a0 : a1;
endmodule