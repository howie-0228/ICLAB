/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: PATTERN
// FILE NAME: PATTERN.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / PATTERN
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

`ifdef RTL
    `define CYCLE_TIME 7.0
`endif
`ifdef GATE
    `define CYCLE_TIME 7.0
`endif

module PATTERN(
	//OUTPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//INPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg			rst_n, clk, in_valid;
output reg	[2:0]	tetrominoes;
output reg  [2:0]	position;
input 				tetris_valid, score_valid, fail;
input 		[3:0]	score;
input		[71:0]	tetris;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer total_latency,latency,pat_latency;
real CYCLE = `CYCLE_TIME;

integer i, j, r, a;
integer PAT_NUM;
integer i_pat, i_set;
integer round;
integer t;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [2:0] tetrominoes_temp[15:0];
reg [2:0] position_temp[15:0];
reg [5:0] tetris_golden[15:0];
reg [3:0] score_golden;
reg [3:0] score_round;
reg fail_golden;
reg tetris_valid_golden;
reg [71:0] golden;
//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
always #(CYCLE/2.0) clk = ~clk;

//---------------------------------------------------------------------
//  SIMULATION
//---------------------------------------------------------------------
initial begin
    r = $fopen("../00_TESTBED/input.txt", "r");
    reset_signal_task;
    // $display("reset done");
    total_latency = 0;
    for(i = 0; i < 16; i = i + 1) begin
        for(j = 0; j < 6; j = j + 1) begin
            tetris_golden[i][j] = 0;
        end
    end
    score_golden = 'd0;
    a = $fscanf(r, "%d", PAT_NUM);
    for(i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1) begin
        a = $fscanf(r, "%d", round);
        fail_golden = 0;
        tetris_valid_golden = 0;
        score_golden = 0;
        pat_latency = 0;
        for(i = 0; i < 16; i = i + 1) begin
            for(j = 0; j < 6; j = j + 1) begin
                tetris_golden[i][j] = 0;
            end
        end
        for(i_set = 0; i_set < 16; i_set = i_set + 1) 
            a = $fscanf(r, "%d %d",tetrominoes_temp[i_set], position_temp[i_set]);
            // $display("read done");
        //reset tetris_golden
        for(i_set = 0; i_set < 16; i_set = i_set + 1) begin
            // $display("input_task...");
            input_task;
            // $display("input done");
            score_cal_task;
            // $display("score_cal done");
            check_fail_task;
            // $display("check_fail done");
            wait_out_valid_task;
            // $display("wait_out_valid done");
            check_ans_task;
            total_latency = total_latency + latency;
            pat_latency = pat_latency + latency;
            if(fail_golden === 1) begin
                // $display("FAIL PATTERN NO.%4d", i_pat);
                break;
            end
            // $display("check_ans done");
            // $display("set num : %d", i_set);
        end
        $display("PASS PATTERN NO.%4d , latency:%d", i_pat, pat_latency);
    end
    $fclose(r);
    YOU_PASS_task;
end

task reset_signal_task;begin
    rst_n = 1;
    in_valid = 0;
    tetrominoes = 'bx;
    position = 'bx;

    force clk = 0;

    #CYCLE; rst_n = 0;
    
    #100; rst_n = 1;
    if(tetris_valid !== 'b0 || score_valid !== 'b0 ||fail !== 'b0 || score !== 'b0 || tetris !== 'b0) begin
    $display("                    SPEC-4 FAIL                   ");
    repeat (2) #CYCLE;
    $finish;
    end

    #CYCLE; release clk;
end endtask

task input_task; begin
    // t = ;
    repeat($urandom_range(4, 1)) @(negedge clk);
    in_valid = 1;
    tetrominoes = tetrominoes_temp[i_set];
    position = position_temp[i_set];
    gen_golden_task;
    #CYCLE;
    in_valid = 0;
    tetrominoes = 'bx;
    position = 'bx;
    // $finish;
end endtask

task gen_golden_task; begin
    // integer i;
    case (tetrominoes)
        'd0:begin//O
            for(i = 11; i >= 0; i = i - 1) begin
                if(tetris_golden[i][position] !== 0 || tetris_golden[i][position + 1] !== 0) begin
                    tetris_golden[i + 1][position] = 1;
                    tetris_golden[i + 1][position + 1] = 1;
                    tetris_golden[i + 2][position] = 1;
                    tetris_golden[i + 2][position + 1] = 1;
                    break;
                end
                else if(i === 0)begin
                    tetris_golden[0][position] = 1;
                    tetris_golden[0][position + 1] = 1;
                    tetris_golden[1][position] = 1;
                    tetris_golden[1][position + 1] = 1;
                end
            end

        end 
        'd1:begin//I_vertical
            for(i = 11; i >= 0; i = i - 1) begin
                if(tetris_golden[i][position] !== 0) begin
                    tetris_golden[i + 1][position] = 1;
                    tetris_golden[i + 2][position] = 1;
                    tetris_golden[i + 3][position] = 1;
                    tetris_golden[i + 4][position] = 1;
                    break;
                end
                else if(i === 0)begin
                    tetris_golden[0][position] = 1;
                    tetris_golden[1][position] = 1;
                    tetris_golden[2][position] = 1;
                    tetris_golden[3][position] = 1;
                end
            end
        end
        'd2:begin//I_horizontal
            for(i = 11; i >= 0; i = i - 1) begin
                if(tetris_golden[i][position] !== 0 || tetris_golden[i][position + 1] !== 0 || tetris_golden[i][position + 2] !== 0 || tetris_golden[i][position + 3] !== 0) begin
                    tetris_golden[i + 1][position] = 1;
                    tetris_golden[i + 1][position + 1] = 1;
                    tetris_golden[i + 1][position + 2] = 1;
                    tetris_golden[i + 1][position + 3] = 1;
                    break;
                end
                else if(i === 0)begin
                    tetris_golden[0][position] = 1;
                    tetris_golden[0][position + 1] = 1;
                    tetris_golden[0][position + 2] = 1;
                    tetris_golden[0][position + 3] = 1;
                end
            end
        end
        'd3:begin//7
            for(i = 12; i >= 2; i = i - 1) begin
                if(tetris_golden[i][position] !== 0 || tetris_golden[i - 2][position + 1] !== 0 || tetris_golden[i - 1][position + 1] !== 0 || tetris_golden[i][position + 1] !== 0) begin
                    tetris_golden[i + 1][position] = 1;
                    tetris_golden[i + 1][position + 1] = 1;
                    tetris_golden[i][position + 1] = 1;
                    tetris_golden[i - 1][position + 1] = 1;
                    break;
                end
                else if(i === 2)begin
                    tetris_golden[2][position] = 1;
                    tetris_golden[2][position + 1] = 1;
                    tetris_golden[1][position + 1] = 1;
                    tetris_golden[0][position + 1] = 1;
                end
            end
        end
        'd4:begin//L_horizontal
            for(i = 11; i >= 0; i = i - 1) begin
                if(tetris_golden[i][position] !== 0 || tetris_golden[i + 1][position + 1] !== 0 || tetris_golden[i + 1][position + 2] !== 0) begin
                    tetris_golden[i + 1][position] = 1;
                    tetris_golden[i + 2][position] = 1;
                    tetris_golden[i + 2][position + 1] = 1;
                    tetris_golden[i + 2][position + 2] = 1;
                    break;
                end
                else if(i === 0)begin
                    tetris_golden[0][position] = 1;
                    tetris_golden[1][position] = 1;
                    tetris_golden[1][position + 1] = 1;
                    tetris_golden[1][position + 2] = 1;
                end
            end
        end
        'd5:begin//L_vertical
            for(i = 11; i >= 0; i = i - 1) begin
                if(tetris_golden[i][position] !== 0 || tetris_golden[i][position + 1] !== 0) begin
                    tetris_golden[i + 1][position] = 1;
                    tetris_golden[i + 2][position] = 1;
                    tetris_golden[i + 3][position] = 1;
                    tetris_golden[i + 1][position + 1] = 1;
                    break;
                end
                else if(i === 0)begin
                    tetris_golden[0][position] = 1;
                    tetris_golden[1][position] = 1;
                    tetris_golden[2][position] = 1;
                    tetris_golden[0][position + 1] = 1;
                end
            end
        end
        'd6:begin//S_vertical
            for(i = 11; i >= 1; i = i - 1) begin
                if(tetris_golden[i][position] !== 0 || tetris_golden[i - 1][position + 1] !== 0 || tetris_golden[i][position + 1] !== 0) begin
                    tetris_golden[i + 1][position] = 1;
                    tetris_golden[i + 1][position + 1] = 1;
                    tetris_golden[i + 2][position] = 1;
                    tetris_golden[i][position + 1] = 1;
                    break;
                end
                else if(i === 1)begin
                    tetris_golden[1][position] = 1;
                    tetris_golden[1][position + 1] = 1;
                    tetris_golden[2][position] = 1;
                    tetris_golden[0][position + 1] = 1;
                end
            end
        end
        'd7:begin//S_horizontal
            for(i = 11; i >= 0; i = i - 1) begin
                if(tetris_golden[i][position] !== 0 || tetris_golden[i][position + 1] !== 0 || tetris_golden[i + 1][position + 2] !== 0) begin
                    tetris_golden[i + 1][position] = 1;
                    tetris_golden[i + 1][position + 1] = 1;
                    tetris_golden[i + 2][position + 1] = 1;
                    tetris_golden[i + 2][position + 2] = 1;
                    break;
                end
                else if(i === 0)begin
                    tetris_golden[0][position] = 1;
                    tetris_golden[0][position + 1] = 1;
                    tetris_golden[1][position + 1] = 1;
                    tetris_golden[1][position + 2] = 1;
                end
            end
        end
    endcase
end endtask

task score_cal_task; begin
    // integer temp;
    integer i,j;
    score_round = 0;
    //score_cal
    for(i = 0; i < 15; i = i + 1) begin
        if(&tetris_golden[i] === 1) begin
            score_round = score_round + 1;
        end
    end
    // //record_score_line
    // for(i = 0; i < 12; i = i + 1)begin
    //     if(&tetris_golden[i] === 1) begin
    //         temp = i;
    //         break;
    //     end
    // end
    //shift_tetris
    for(i = 11; i >= 0; i = i - 1) begin
        if(&tetris_golden[i] === 1) begin
            for(j = i; j < 15; j = j + 1)
                tetris_golden[j] = tetris_golden[j + 1];
        end
    end
    score_golden = score_golden + score_round;
end endtask

task check_fail_task; begin
    integer i,j;
    for(i = 12; i < 15; i = i + 1) begin
        for(j = 0; j < 6; j = j + 1) begin
            if(tetris_golden[i][j] !== 0) begin
                fail_golden = 1;
                tetris_valid_golden = 1;
                break;
            end
        end
        if(fail_golden == 1) begin
            tetris_valid_golden = 1;
            break;
        end
    end
end endtask

task wait_out_valid_task; begin
    latency = 1;
    while(score_valid !== 'b1) begin
        latency = latency + 1;
        if(latency == 1000) begin
            $display("                    SPEC-6 FAIL                   ");
            repeat(2) #CYCLE;
            $finish;
        end
        @(negedge clk);
    end
    // total_latency = total_latency + latency;
    // latency = 0;
    //     while (score_valid !== 1'b1) begin
    //         latency = latency + 1;
    //         if (latency == 1000) begin
    //             $display("                    SPEC-6 FAIL                   ");
    //             repeat (2) @(negedge clk);
    //             $finish;
    //         end
    //         $display("%d", latency);
    //         @(negedge clk);
    //     end
    //     total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    golden = {tetris_golden[11][5], tetris_golden[11][4], tetris_golden[11][3], tetris_golden[11][2], tetris_golden[11][1], tetris_golden[11][0],
    tetris_golden[10][5], tetris_golden[10][4], tetris_golden[10][3], tetris_golden[10][2], tetris_golden[10][1], tetris_golden[10][0], 
    tetris_golden[9][5], tetris_golden[9][4], tetris_golden[9][3], tetris_golden[9][2], tetris_golden[9][1], tetris_golden[9][0], 
    tetris_golden[8][5], tetris_golden[8][4], tetris_golden[8][3], tetris_golden[8][2], tetris_golden[8][1], tetris_golden[8][0], 
    tetris_golden[7][5], tetris_golden[7][4], tetris_golden[7][3], tetris_golden[7][2], tetris_golden[7][1], tetris_golden[7][0], 
    tetris_golden[6][5], tetris_golden[6][4], tetris_golden[6][3], tetris_golden[6][2], tetris_golden[6][1], tetris_golden[6][0], 
    tetris_golden[5][5], tetris_golden[5][4], tetris_golden[5][3], tetris_golden[5][2], tetris_golden[5][1], tetris_golden[5][0], 
    tetris_golden[4][5], tetris_golden[4][4], tetris_golden[4][3], tetris_golden[4][2], tetris_golden[4][1], tetris_golden[4][0], 
    tetris_golden[3][5], tetris_golden[3][4], tetris_golden[3][3], tetris_golden[3][2], tetris_golden[3][1], tetris_golden[3][0],
    tetris_golden[2][5], tetris_golden[2][4], tetris_golden[2][3], tetris_golden[2][2], tetris_golden[2][1], tetris_golden[2][0],
    tetris_golden[1][5], tetris_golden[1][4], tetris_golden[1][3], tetris_golden[1][2], tetris_golden[1][1], tetris_golden[1][0],
    tetris_golden[0][5], tetris_golden[0][4], tetris_golden[0][3], tetris_golden[0][2], tetris_golden[0][1], tetris_golden[0][0]};
    if(i_set === 15)
        tetris_valid_golden = 1;
    if(score !== score_golden || fail !== fail_golden || tetris_valid !== tetris_valid_golden ||  (tetris_valid === 1&&tetris !== golden)) begin
        $display("                    SPEC-7 FAIL                   ");
        repeat(2) #CYCLE;
        $finish;
    end
    #CYCLE;
    if(score_valid !== 0) begin
        $display("                    SPEC-8 FAIL                   ");
        repeat(2) #CYCLE;
        $finish;
    end
end endtask
task YOU_PASS_task; begin
    $display("                  Congratulations!               ");
    $display("              execution cycles = %7d", total_latency);
    $display("              clock period = %4fns", CYCLE);
    $finish;
end endtask

//SPEC-5-----------------------------------------------------------------------
always @(negedge clk) begin
    if( ((score_valid === 'b0)&&(score !== 0 || fail !== 0 || tetris_valid !== 0)) || (tetris_valid === 0 && tetris !== 0))
        begin
            $display("                    SPEC-5 FAIL                   ");
            // repeat(2) #CYCLE;
            $finish;
        end
end
// for spec check
// $display("                    SPEC-4 FAIL                   ");
// $display("                    SPEC-5 FAIL                   ");
// $display("                    SPEC-6 FAIL                   ");
// $display("                    SPEC-7 FAIL                   ");
// $display("                    SPEC-8 FAIL                   ");
// for successful design
// $display("                  Congratulations!               ");
// $display("              execution cycles = %7d", total_latency);
// $display("              clock period = %4fns", CYCLE);
endmodule